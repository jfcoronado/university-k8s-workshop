# Módulo 8 — Escalado y actualizaciones graduales

> ⏱️ **Tiempo:** 20 minutos | 🎯 **Objetivo:** Escalar tu app, hacer una actualización gradual sin tiempo de inactividad y revertirla

---

## Escalado en Kubernetes

Kubernetes soporta dos tipos de escalado:

| Tipo | Cómo | Cuándo |
|------|------|--------|
| **Escalado horizontal** | Agregar más Pods | Apps sin estado, manejar más tráfico |
| **Escalado vertical** | Darle más CPU o RAM a cada Pod | Apps de un solo hilo, pods de base de datos |

Para aplicaciones web, el **escalado horizontal** casi siempre es el enfoque correcto.

---

## Escalado horizontal manual

### Escalar hacia arriba

```bash
# Escalar a 5 réplicas
kubectl scale deployment demo-app --replicas=5 -n workshop-app

# Observar cómo aparecen los pods
kubectl get pods -n workshop-app -w
````

Ahora abre [http://demo.local](http://demo.local) y refresca varias veces — verás **5 nombres de pod distintos** rotando en la tarjeta principal. El contador de solicitudes de cada pod aumentará de forma independiente.

### Escalar hacia abajo

```bash
kubectl scale deployment demo-app --replicas=2 -n workshop-app
```

---

## Horizontal Pod Autoscaler, HPA

En producción normalmente no escalas manualmente — dejas que Kubernetes lo haga según métricas.

```yaml
# manifests/hpa.yaml (solo revisión, requiere metrics-server)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-app-hpa
  namespace: workshop-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70    # Escala cuando el CPU promedio supera 70%
```

> ⚠️ HPA requiere metrics-server. Revisamos el YAML, pero no lo aplicaremos hoy.

---

## Rolling updates, despliegues sin caída

Una **actualización gradual** reemplaza los Pods uno por uno, garantizando que siempre haya algunos disponibles.

```text
Antes de la actualización: [v1.0.0] [v1.0.0] [v1.0.0] [v1.0.0]

Paso 1:                    [v1.0.0] [v1.0.0] [v1.0.0] [v2.0.0]   ← se crea 1 pod nuevo
Paso 2:                    [v1.0.0] [v1.0.0] [v2.0.0] [v2.0.0]   ← se elimina 1 pod viejo
Paso 3:                    [v1.0.0] [v2.0.0] [v2.0.0] [v2.0.0]
Paso 4:                    [v2.0.0] [v2.0.0] [v2.0.0] [v2.0.0]   ← completo
```

### Estrategia RollingUpdate, ya está en deployment.yaml

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1         # Crear 1 pod extra antes de quitar uno viejo
      maxUnavailable: 0   # Nunca bajar del número deseado de réplicas, cero downtime
```

---

## Paso 1 — Construir la versión v2.0.0 de la app

Para la demo de rolling update, vamos a construir una imagen v2 con un pequeño cambio. Abre `app/Dockerfile` y cambia la línea de la variable `APP_VERSION`:

```dockerfile
# Cambia esta línea:
ENV APP_VERSION=1.0.0
# Por esta:
ENV APP_VERSION=2.0.0
```

Luego constrúyela y cárgala:

```bash
docker build -t k8s-workshop-demo:2.0.0 ./app
kind load docker-image k8s-workshop-demo:2.0.0 --name workshop
```

---

## Paso 2 — Ejecutar la actualización gradual

```bash
# Terminal 1: observar los pods en tiempo real
kubectl get pods -n workshop-app -w

# Terminal 2: disparar la actualización gradual
kubectl set image deployment/demo-app demo-app=k8s-workshop-demo:2.0.0 -n workshop-app
```

Observa la Terminal 1 — los nuevos pods con `v2.0.0` suben **antes** de que los pods viejos con `v1.0.0` se eliminen. Mantén abierto [http://demo.local](http://demo.local) — la insignia de versión en la esquina superior derecha cambiará de `v1.0.0` a `v2.0.0` a medida que tus solicitudes lleguen a pods ya actualizados.

---

## Paso 3 — Revisar el estado del rollout

```bash
kubectl rollout status deployment/demo-app -n workshop-app
# Waiting for deployment "demo-app" rollout to finish...
# deployment "demo-app" successfully rolled out
```

---

## Paso 4 — Ver el historial del rollout

```bash
kubectl rollout history deployment/demo-app -n workshop-app
```

Agrega una anotación change-cause para llevar mejor historial:

```bash
kubectl annotate deployment demo-app kubernetes.io/change-cause="Upgraded app to v2.0.0" -n workshop-app
```

---

## Paso 5 — Revertir

¿Algo salió mal? Revierte al instante a la versión anterior:

```bash
# Revertir a la revisión previa
kubectl rollout undo deployment/demo-app -n workshop-app

# O revertir a una revisión específica
kubectl rollout undo deployment/demo-app --to-revision=1 -n workshop-app

# Observar el rollback
kubectl rollout status deployment/demo-app -n workshop-app
```

Abre [http://demo.local](http://demo.local) — la versión vuelve a `v1.0.0`. Esa es la fuerza de los rollbacks.

---

## Paso 6 — La forma GitOps, mejor que kubectl set image

En producción, lo correcto es actualizar la etiqueta de imagen en tu YAML y luego aplicarlo:

```bash
# Edita manifests/deployment.yaml y cambia:
#   image: k8s-workshop-demo:1.0.0
# Por:
#   image: k8s-workshop-demo:2.0.0

kubectl apply -f manifests/deployment.yaml
```

Esto es mejor porque:

* ✅ El cambio queda en control de versiones, historial de git como auditoría
* ✅ Puede revisarse en un Pull Request antes de llegar al clúster
* ✅ Un rollback puede hacerse con `git revert` y luego `kubectl apply`

---

## 🧪 Laboratorio — Simular un mal despliegue

```bash
# 1. Desplegar una imagen rota, tag inexistente
kubectl set image deployment/demo-app demo-app=k8s-workshop-demo:this-tag-does-not-exist -n workshop-app

# 2. Observar qué pasa
kubectl get pods -n workshop-app -w
# Verás: ErrImagePull → ImagePullBackOff
# Los pods viejos siguen corriendo, la actualización se DETIENE porque los nuevos pods no pueden arrancar

# 3. Revisar el estado del rollout
kubectl rollout status deployment/demo-app -n workshop-app --timeout=30s

# 4. Revertir al instante para corregirlo
kubectl rollout undo deployment/demo-app -n workshop-app

# 5. Confirmar que todo está saludable
kubectl get pods -n workshop-app
```

> 💡 Por eso `maxUnavailable: 0` es importante — los pods viejos siguieron corriendo todo el tiempo, así que tus usuarios nunca vieron una caída.

---

## Hoja rápida de kubectl rollout

```bash
kubectl scale deployment demo-app --replicas=N -n workshop-app
kubectl rollout status deployment/demo-app -n workshop-app
kubectl rollout history deployment/demo-app -n workshop-app
kubectl rollout undo deployment/demo-app -n workshop-app
kubectl rollout undo deployment/demo-app --to-revision=1 -n workshop-app
kubectl rollout pause deployment/demo-app -n workshop-app
kubectl rollout resume deployment/demo-app -n workshop-app
kubectl rollout restart deployment/demo-app -n workshop-app  # Fuerza reemplazo de pods, útil después de cambios de configuración
```

---

**➡️ Siguiente:** [Módulo 9 — Bonus: Troubleshooting y consejos](../09-bonus/README.md)
