# Módulo 4 — Deployments: Ejecutando tu aplicación

> ⏱️ **Tiempo:** 25 minutos | 🎯 **Objetivo:** Construir la app del workshop, cargarla en KIND, desplegarla y demostrar que la autoreparación funciona

---

## Pods vs Deployments — ¿Cuál es la diferencia?

**Pod:** Ejecuta uno o más contenedores. Si falla, se queda muerto.

**Deployment:** Un controlador que administra Pods. Si un Pod falla, el Deployment crea uno nuevo.

```

Deployment
└── ReplicaSet (administra N pods idénticos)
├── Pod 1  ← aquí corre el contenedor de la app
├── Pod 2  ← aquí corre el contenedor de la app
└── Pod 3  ← aquí corre el contenedor de la app

````

> 🔑 **En la práctica: nunca crees Pods sueltos.** Usa siempre un Deployment, o un StatefulSet si es una app con estado.

---

## Paso 1: Construir la app del workshop

Nuestra app demo es un servidor Node.js en la carpeta `app/`. Vamos a construirla como una imagen de Docker:

```bash
docker build -t k8s-workshop-demo:1.0.0 ./app
````

Verifica que la imagen fue construida:

```bash
docker images | grep k8s-workshop-demo

#PowerShell
docker images --filter "reference=k8s-workshop-demo*"
```

---

## Paso 2: Cargar la imagen en KIND

KIND ejecuta Kubernetes dentro de contenedores Docker. Esos contenedores no pueden ver por defecto las imágenes de tu daemon local de Docker, así que necesitas cargarlas explícitamente:

```bash
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
```

> 💡 Esto es específico de KIND. En un clúster real en AWS, GCP o Azure, subirías la imagen a un registry de contenedores como ECR, GCR o GHCR, y Kubernetes la descargaría desde allí.

Nota: al usar podman puede ser necesario importar en kind directamente el tar file exportando la imagen local, porque el kind import con podman es todavia en fase experimental.

```bash
podman save localhost/k8s-workshop-demo:1.0.0 -o workshop.tar
kind load image-archive --name workshop workshop.tar 
```
En el ejemplo, la imagen previamente descargada en podman local para el usuario en uso era `localhost/k8s-workshop-demo:1.0.0`, se exportó como `workshop.tar`, y finalmente se importó con el command line de kind.

---

## Paso 3: Revisar el YAML del Deployment

```bash
cat manifests/deployment.yaml
```

```yaml
# manifests/deployment.yaml
apiVersion: apps/v1          # Grupo API para Deployments
kind: Deployment             # Tipo de objeto
metadata:
  name: demo-app             # Nombre de este Deployment
  namespace: workshop-app    # Namespace donde se crea
  labels:
    app: demo-app
spec:
  replicas: 2                # Cuántos Pods deben mantenerse corriendo
  selector:
    matchLabels:
      app: demo-app          # El Deployment administra Pods con esta etiqueta
  template:                  # Aquí empieza la plantilla del Pod
    metadata:
      labels:
        app: demo-app        # Etiqueta que recibe cada Pod, debe coincidir con el selector
    spec:
      containers:
        - name: demo-app
          image: k8s-workshop-demo:1.0.0   # La imagen que acabamos de construir y cargar
          imagePullPolicy: Never            # Usa imagen local, no intentes descargarla
          ports:
            - containerPort: 3000
          env:
            # Downward API — Kubernetes inyecta metadatos del Pod como variables de entorno
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: APP_ENV
              value: "workshop"
            - name: APP_VERSION
              value: "1.0.0"
          resources:
            requests:
              cpu: 100m        # 100 millicores = 0.1 núcleo de CPU garantizado
              memory: 64Mi     # 64 MiB de RAM garantizados
            limits:
              cpu: 250m        # Máximo CPU que puede usar este contenedor
              memory: 128Mi    # Máxima RAM — el contenedor será OOMKilled si la excede
          readinessProbe:      # ¿La app ya está lista para recibir tráfico?
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:       # ¿La app sigue viva? Reiníciala si no.
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
```

### Campos clave explicados

| Campo                    | Qué significa                                                                         |
| ------------------------ | ------------------------------------------------------------------------------------- |
| `replicas: 2`            | Mantén siempre 2 Pods corriendo                                                       |
| `selector.matchLabels`   | Cómo el Deployment encuentra sus Pods — debe coincidir con `template.metadata.labels` |
| `imagePullPolicy: Never` | Usa la imagen local cargada — nunca intentes descargarla desde un registry            |
| `resources.requests`     | Recursos mínimos reservados para planificar el Pod                                    |
| `resources.limits`       | Límite duro — el contenedor será OOMKilled si supera la memoria                       |
| `readinessProbe`         | K8s espera a que esto pase antes de enviar tráfico al Pod                             |
| `livenessProbe`          | K8s reinicia el Pod si esto sigue fallando                                            |

### La Downward API

Las variables `fieldRef` son una función de Kubernetes llamada **Downward API** — permite que un Pod aprenda sobre sí mismo, como su nombre, IP, namespace o nodo, sin llamar al API server. Nuestra app muestra estos valores en pantalla, así que podrás ver cómo cambia el nombre del Pod cuando las solicitudes se balancean entre ellos.

### Unidades de CPU

| Valor  | Significado                       |
| ------ | --------------------------------- |
| `1`    | 1 núcleo completo de CPU          |
| `500m` | 0.5 núcleo de CPU, 500 millicores |
| `100m` | 0.1 núcleo de CPU, 100 millicores |

---

## Paso 4: Actualizar la imagen en deployment.yaml

Antes de aplicar, actualiza la línea de la imagen en `manifests/deployment.yaml` para usar la imagen local:

```yaml
image: k8s-workshop-demo:1.0.0
imagePullPolicy: Never
```

> El archivo actualmente tiene una URL de registry de ejemplo. Reemplázala por esas dos líneas.

---

## Paso 5: Aplicar el Deployment

```bash
kubectl apply -f manifests/deployment.yaml
```

---

## Paso 6: Ver cómo arrancan los Pods

```bash
# Ver en tiempo real, Ctrl+C para detener
kubectl get pods -n workshop-app -w
```

Salida esperada:

```text
NAME                        READY   STATUS    RESTARTS   AGE
demo-app-7d9f8b6c4-abc12   1/1     Running   0          30s
demo-app-7d9f8b6c4-xyz34   1/1     Running   0          30s
```

---

## Paso 7: Inspeccionar tu Deployment y Pods

```bash
# Estado general del Deployment
kubectl get deployment demo-app -n workshop-app

# Vista detallada con eventos y condiciones
kubectl describe deployment demo-app -n workshop-app

# Describir un Pod específico
kubectl describe pod <pod-name> -n workshop-app

# Qué revisar: Events al final, Conditions y estado de las probes
```

---

## Paso 8: Ver logs

```bash
# Logs de un Pod específico
kubectl logs <pod-name> -n workshop-app

# Ver logs en vivo
kubectl logs -f <pod-name> -n workshop-app

# Logs de TODOS los Pods con esa etiqueta
kubectl logs -l app=demo-app -n workshop-app

# Logs del contenedor anterior, útil después de un fallo
kubectl logs <pod-name> -n workshop-app --previous
```

Deberías ver líneas como estas:

```text
☸  Workshop demo app running on port 3000
   Pod: demo-app-7d9f8b6c4-abc12
   Env: workshop | Version: 1.0.0
```

---

## Paso 9: Entrar a un Pod

```bash
# Abrir una shell dentro de un contenedor en ejecución
kubectl exec -it <pod-name> -n workshop-app -- /bin/sh

# Una vez dentro, prueba:
wget -qO- localhost:3000/health
hostname
env | grep POD
exit
```

> 💡 Esto es como hacer SSH dentro de un contenedor. Muy útil para depuración.

---

## 🧪 Laboratorio: Demostración de autoreparación

Esta es la parte que más llama la atención. Mira cómo Kubernetes reemplaza automáticamente un Pod caído:

```bash
# Terminal 1: observar los Pods continuamente
kubectl get pods -n workshop-app -w

# Terminal 2: borrar un Pod para simular un fallo
kubectl delete pod <pod-name> -n workshop-app
```

Observa la Terminal 1 — en pocos segundos aparece un **Pod nuevo** con un nombre nuevo.

El controlador del Deployment detectó que `actual (1) < desired (2)` y creó de inmediato un reemplazo. La app nunca cayó porque la segunda réplica siguió atendiendo tráfico.

---

## Labels y Selectors

Las labels son pares clave-valor en cualquier objeto de K8s. Los selectors filtran por labels.

```bash
# Mostrar labels en los Pods
kubectl get pods -n workshop-app --show-labels

# Filtrar Pods por label
kubectl get pods -n workshop-app -l app=demo-app
```

> 🔑 Las labels son la forma en que Kubernetes conecta objetos. El Deployment encuentra sus Pods por label. El Service, en el siguiente módulo, encuentra los Pods que debe balancear por label. Ese acoplamiento flexible es muy poderoso.

---

**➡️ Siguiente:** [Módulo 5 — Services](../05-services/README.md)
