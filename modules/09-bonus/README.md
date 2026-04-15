# Módulo 9 — Bonus: Solución de problemas y próximos pasos

> ⏱️ **Tiempo:** Abierto | 🎯 **Objetivo:** Depurar problemas comunes y saber cuál es el siguiente paso

---

## Estados comunes de los Pods y qué significan

| Estado | Significado | Solución |
|--------|-------------|----------|
| `Pending` | El scheduler no puede ubicar el pod | Revisa recursos, node selectors y taints |
| `ContainerCreating` | Está descargando la imagen o montando volúmenes | Espera, o revisa el nombre de la imagen y los pull secrets |
| `Running` | El contenedor está corriendo | Normal |
| `CrashLoopBackOff` | El contenedor sigue fallando y reiniciando | Revisa logs: `kubectl logs <pod> --previous` |
| `OOMKilled` | El contenedor superó el límite de memoria | Aumenta los límites de memoria |
| `ImagePullBackOff` | No puede descargar la imagen | Revisa nombre de imagen, acceso al registry y pull secrets |
| `ErrImagePull` | La descarga de la imagen falló una vez | Revisa nombre y tag de la imagen, o la red |
| `Terminating` | El pod está siendo eliminado | Normal, o revisa finalizers si se queda atascado |
| `Error` | El contenedor salió con error | Revisa logs |

---

## Árbol de decisión para troubleshooting

```text
¿El pod no funciona?
│
├─ kubectl get pods -n <ns>
│   │
│   ├─ Estado: Pending
│   │   └─ kubectl describe pod <pod> -n <ns>
│   │       Busca: sección Events — "Insufficient CPU/Memory", "Unschedulable"
│   │
│   ├─ Estado: CrashLoopBackOff
│   │   └─ kubectl logs <pod> -n <ns> --previous
│   │       Busca: error al iniciar la app, variable de entorno faltante, fallo de conexión a BD
│   │
│   ├─ Estado: ImagePullBackOff
│   │   └─ kubectl describe pod <pod> -n <ns>
│   │       Busca: error tipográfico en el nombre de la imagen, registry privado que necesita pull secret
│   │
│   └─ Estado: Running pero la app no responde
│       ├─ kubectl exec -it <pod> -n <ns> -- curl localhost:<port>
│       ├─ kubectl get endpoints <svc> -n <ns>
│       └─ kubectl logs <pod> -n <ns>
````

---

## Comandos esenciales de depuración

```bash
# 1. El comando "describe", tu mejor amigo
kubectl describe pod <pod-name> -n <ns>
kubectl describe deployment <deploy-name> -n <ns>
kubectl describe svc <svc-name> -n <ns>
kubectl describe ingress <ingress-name> -n <ns>

# 2. Events, qué pasó dentro del clúster
kubectl get events -n workshop-app --sort-by='.lastTimestamp'

# 3. Logs
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous      # Último contenedor terminado
kubectl logs -l app=demo-app -n <ns>       # Todos los pods que coinciden con la label

# 4. Entrar a un pod
kubectl exec -it <pod> -n <ns> -- /bin/sh
kubectl exec -it <pod> -n <ns> -- /bin/bash

# 5. Ejecutar un pod de depuración
kubectl run debug --image=busybox --restart=Never -it --rm -n workshop-app -- sh
kubectl run debug --image=curlimages/curl --restart=Never -it --rm -n workshop-app \
  -- curl -v http://demo-app-svc

# 6. Port forward para probar services
kubectl port-forward svc/demo-app-svc 8080:80 -n workshop-app
kubectl port-forward pod/<pod-name> 8080:80 -n workshop-app

# 7. Revisar uso de recursos, requiere metrics-server
kubectl top pods -n workshop-app
kubectl top nodes
```

---

## Depuración de Ingress

```bash
# 1. ¿Está corriendo el controlador Ingress?
kubectl get pods -n traefik

# 2. ¿El Ingress tiene dirección?
kubectl get ingress -n workshop-app
# La columna ADDRESS debería mostrar 'localhost' o una IP

# 3. ¿Los endpoints del Service están poblados?
kubectl get endpoints demo-app-svc -n workshop-app
# Endpoints vacíos = no hay pods que coincidan con el selector

# 4. Revisar logs del controlador Ingress
kubectl logs -n traefik \
  $(kubectl get pods -n traefik -o name | grep controller | head -1)

# 5. Probar directamente contra el controlador
curl -H "Host: demo.local" http://localhost
```

---

## Errores comunes y cómo corregirlos

### Labels que no coinciden entre el selector del Deployment y la plantilla del Pod

```bash
# Síntoma: el service no tiene endpoints
# Revisa: ¿coinciden estos valores?
kubectl get deploy demo-app -n workshop-app -o jsonpath='{.spec.selector}'
kubectl get pods -n workshop-app --show-labels
```

### Namespace incorrecto

```bash
# Síntoma: errores de "not found"
# Incluye siempre -n <namespace>
kubectl get pods -n workshop-app    # NO solo: kubectl get pods
```

### Desajuste de puertos

```bash
# El targetPort del Service debe coincidir con el containerPort del Pod
# Revisa:
kubectl get svc demo-app-svc -n workshop-app -o yaml | grep -A5 ports
kubectl get pods -n workshop-app -o yaml | grep -A5 ports
```

### Imagen no encontrada en KIND

```bash
# Si usas una imagen local, primero debes cargarla en KIND
docker build -t my-app:v1 .
kind load docker-image my-app:v1 --name workshop
# Luego usa imagePullPolicy: Never en tu Deployment
```

---

## Limpiar el workshop

Cuando termines:

```bash
# Quitar la entrada de /etc/hosts
sudo sed -i '' '/demo.local/d' /etc/hosts    # macOS
sudo sed -i '/demo.local/d' /etc/hosts        # Linux

# O usar el script de teardown
bash scripts/teardown.sh
```

---

## Próximos pasos, qué aprender después

### Temas inmediatos

* **Helm** — gestor de paquetes de Kubernetes. Instala apps complejas con un solo comando
* **Persistent Volumes** — dar almacenamiento a tus Pods que sobreviva reinicios
* **StatefulSets** — para apps con estado, como bases de datos o colas
* **RBAC** — controlar quién puede hacer qué dentro del clúster
* **Network Policies** — controlar qué Pods pueden hablar con otros

### Temas intermedios

* **Service Mesh** como Istio o Linkerd — mTLS, división de tráfico y observabilidad
* **GitOps** con ArgoCD o Flux — usar git como fuente de verdad de los despliegues
* **Observabilidad** con Prometheus + Grafana — métricas, dashboards y alertas
* **Cert-Manager** — certificados TLS automáticos, como Let's Encrypt

### Certificaciones

| Certificación | Nivel      | Enfoque                     |
| ------------- | ---------- | --------------------------- |
| CKA           | Intermedio | Administración de clústeres |
| CKAD          | Intermedio | Desarrollo de aplicaciones  |
| CKS           | Avanzado   | Seguridad                   |

### Entornos para practicar

* **Killercoda:** [killercoda.com](https://killercoda.com) — laboratorios gratis en navegador
* **Play with K8s:** [labs.play-with-k8s.com](https://labs.play-with-k8s.com) — sesiones gratis de 4 horas
* **k3d:** alternativa ligera a KIND
* **minikube:** otra opción local de Kubernetes con add-ons

### Comunidad

* **CNCF Slack:** [slack.cncf.io](https://slack.cncf.io) — canal `#kubernetes`
* **Cloud Native LA:** [meetup.com/cloud-native-la](https://meetup.com/cloud-native-la)
* **Documentación de Kubernetes:** [kubernetes.io/docs](https://kubernetes.io/docs) — la mejor referencia
* **Boletín KubeWeekly:** [kubeweekly.io](https://kubeweekly.io)

---

## 🙌 ¡Gracias!

Ya pasaste de cero a un pipeline funcional de despliegue en Kubernetes.

¿Preguntas después del workshop? Abre un issue en este repositorio o búscame en CNCF Slack.

