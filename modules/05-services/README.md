# Módulo 5 — Services: Red interna

> ⏱️ **Tiempo:** 20 minutos | 🎯 **Objetivo:** Exponer tu aplicación con una dirección de red interna estable y probarla

---

## ¿Por qué necesitamos Services?

Los Pods son **efímeros** — aparecen y desaparecen. Cuando un Pod es reemplazado, obtiene una **nueva dirección IP**.

**Problema:** Si otro servicio estaba hablando directamente con `10.244.0.5`, esa conexión se rompe cuando el Pod se reinicia.

**Solución:** Un **Service** le da a un conjunto de Pods una **dirección estable y permanente** (nombre DNS + ClusterIP) que nunca cambia, aunque los Pods vayan y vengan.

```
Antes del Service:                      Después del Service:

Cliente → IP del Pod (¡cambia!)         Cliente → Service (¡estable!)
                                              │
                                              ├── Pod 1 (10.244.0.5)
                                              ├── Pod 2 (10.244.0.6)
                                              └── Pod 3 (10.244.0.7)

                                        El Service balancea la carga entre Pods saludables
```

## Tipos de Service

| Tipo | Accesible desde | Caso de uso |
|------|-----------------|-------------|
| **ClusterIP** | Solo dentro del clúster | Predeterminado. Comunicación entre microservicios |
| **NodePort** | Desde fuera mediante IP del nodo + puerto (30000-32767) | Acceso de desarrollo o pruebas |
| **LoadBalancer** | Desde fuera mediante balanceador de carga en la nube | Producción en AWS, GCP o Azure |
| **ExternalName** | Apunta a un DNS externo | Proxy hacia servicios externos |

> 💡 Para este workshop usamos **ClusterIP** (interno) + **Ingress** (enrutamiento externo). Este es el patrón recomendado en producción.

---

## Cómo encuentran Pods los Services: Label Selectors

Los Services usan **label selectors** para encontrar sus Pods objetivo. El Service no se preocupa por nombres de Pods ni por IPs — solo por labels.

```yaml
# Selector del Service
selector:
  app: demo-app      # ← Enruta hacia cualquier Pod con esta etiqueta

# Label de la plantilla del Pod (debe coincidir)
labels:
  app: demo-app      # ← Este pod recibirá tráfico
````

---

## Paso 1: Revisar el YAML del Service

```bash
cat manifests/service.yaml
```

```yaml
# manifests/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-app-svc          # Nombre DNS estable: demo-app-svc.workshop-app.svc.cluster.local
  namespace: workshop-app
  labels:
    app: demo-app
spec:
  selector:
    app: demo-app              # Enruta a todos los Pods con label app=demo-app
  ports:
    - name: http
      protocol: TCP
      port: 80                 # Puerto donde escucha el Service dentro del clúster
      targetPort: 3000         # Puerto donde escucha la app Node.js dentro del Pod
  type: ClusterIP
```

---

## Paso 2: Aplicar el Service

```bash
kubectl apply -f manifests/service.yaml
```

---

## Paso 3: Verificar el Service

```bash
kubectl get services -n workshop-app
# o forma corta
kubectl get svc -n workshop-app
```

Salida esperada:

```text
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
demo-app-svc   ClusterIP   10.96.145.23   <none>        80/TCP    15s
```

```bash
# Vista detallada — muestra selector y endpoints
kubectl describe svc demo-app-svc -n workshop-app
```

Busca la línea de **Endpoints** — muestra qué IPs de Pods están recibiendo tráfico en ese momento:

```text
Endpoints: 10.244.0.5:3000, 10.244.0.6:3000
```

---

## Paso 4: Inspeccionar Endpoints

Los Endpoints se crean y actualizan automáticamente por el Service para seguir las IPs de Pods saludables:

```bash
kubectl get endpoints demo-app-svc -n workshop-app
```

> 💡 Si un Pod falla su readiness probe, se **elimina de los Endpoints** — ya no se le enviará tráfico. Así es como Kubernetes se asegura de enrutar solo hacia pods saludables.

---

## Paso 5: Probar el Service con Port-Forward

ClusterIP solo es accesible desde dentro del clúster. Usamos `port-forward` para crear un túnel temporal hacia él:

```bash
kubectl port-forward svc/demo-app-svc 8080:80 -n workshop-app
```

> ⚠️ **¡Deja esta terminal abierta!** Port-forward solo funciona mientras el comando siga corriendo. En el momento en que presionas Ctrl+C, el túnel se cierra.

Ahora abre [http://localhost:8080](http://localhost:8080) en tu navegador. Deberías ver la app del workshop.

Presiona `Ctrl+C` cuando termines.

> `port-forward` es solo una herramienta de depuración — no es como fluye el tráfico en producción. Para eso está Ingress, en el Módulo 6.

---

## Paso 6: DNS dentro del clúster

### Por qué importa el DNS

Piensa en una aplicación real — un frontend que habla con una API backend, y esta con una base de datos. ¿Cómo sabe el frontend dónde encontrar el backend?

Sin DNS, tendría que usar una IP fija como `10.244.0.5`. Pero las IPs de los pods cambian cada vez que un pod es reemplazado. Dejar IPs escritas directamente fallaría todo el tiempo.

**Kubernetes DNS resuelve esto.** Cada Service recibe automáticamente un nombre DNS estable. Tu frontend llama a `http://backend-svc` y CoreDNS resuelve eso a la IP correcta del Service, que balancea la carga hacia un pod saludable, sin importar cuántas veces esos pods hayan sido reemplazados.

```
Pod de tu app
    │
    │  http://demo-app-svc   ← nombre estable, nunca cambia
    ▼
CoreDNS (servidor DNS integrado de K8s)
    │
    │  resuelve a 10.96.145.23  (ClusterIP del Service)
    ▼
Service: demo-app-svc
    │
    ├── Pod 10.244.0.5:3000
    └── Pod 10.244.0.6:3000
```

### Formato del nombre DNS

Cada Service recibe un nombre DNS con este formato:

```text
<service-name>.<namespace>.svc.cluster.local
```

Para nuestro Service:

```text
demo-app-svc.workshop-app.svc.cluster.local
```

Dentro del mismo namespace puedes usar solo el nombre del service:

```text
demo-app-svc
```

### Pruébalo

Vamos a entrar a un pod que ya está corriendo para probar el DNS — no hace falta descargar otra imagen porque `wget` ya está disponible en nuestra imagen Node Alpine.

**Paso 1 — obtener el nombre de un pod en ejecución:**

```bash
kubectl get pods -n workshop-app
```

**Paso 2 — probar el nombre DNS completo:**

```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc.workshop-app.svc.cluster.local | head -5
```

**Paso 3 — probar la forma corta, atajo del mismo namespace:**

```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc | head -5
```

Ambos devuelven el mismo HTML. Kubernetes agrega automáticamente `.workshop-app.svc.cluster.local` cuando los pods están en el mismo namespace.

**Paso 4 — acceder al endpoint de salud para confirmar toda la cadena:**

```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc/health
```

Salida esperada:

```json
{"status":"ok","pod":"demo-app-7d9f8b6c4-abc12","uptime":"5m 30s"}
```

### Lo que acabas de demostrar

* `demo-app-svc` se resolvió hacia el ClusterIP del Service mediante CoreDNS ✅
* El Service balanceó la solicitud hacia uno de tus pods ✅
* El pod respondió a través del Service, no por IP directa ✅

Así es exactamente como se comunican los microservicios dentro de un clúster real de Kubernetes.

---

## 🧪 Laboratorio: Mira cómo se actualizan los Endpoints

Abre dos ventanas de terminal lado a lado.

**Terminal 1 — comienza observando primero:**

```bash
kubectl get endpoints demo-app-svc -n workshop-app -w
```

Vas a ver:

```text
NAME           ENDPOINTS                           AGE
demo-app-svc   10.244.0.5:3000,10.244.0.6:3000    5m
```

**Terminal 2 — elimina un pod:**

```bash
# Obtener el nombre de un pod
kubectl get pods -n workshop-app

# Eliminarlo
kubectl delete pod <pod-name> -n workshop-app
```

Mira la Terminal 1 — verás que la IP del pod eliminado desaparece al instante, y luego aparece una IP nueva en pocos segundos cuando Kubernetes crea el reemplazo:

```text
NAME           ENDPOINTS                           AGE
demo-app-svc   10.244.0.5:3000,10.244.0.6:3000    5m
demo-app-svc   10.244.0.5:3000                     5m   ← el pod desapareció
demo-app-svc   10.244.0.5:3000,10.244.0.7:3000    5m   ← nuevo pod registrado
```

La lista de endpoints del Service se actualiza automáticamente. Tu nombre DNS `demo-app-svc` siempre apuntó a pods saludables durante todo el proceso — por eso existen los Services.

---

**➡️ Siguiente:** [Módulo 6 — Ingress](../06-ingress/README.md)

