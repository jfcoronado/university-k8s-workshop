# Módulo 2 — Creando tu clúster KIND

> ⏱️ **Tiempo:** 20 minutos | 🎯 **Objetivo:** Crear y verificar un clúster local de Kubernetes con soporte para Ingress

---

## ¿Qué es KIND?

**KIND = Kubernetes IN Docker**

KIND ejecuta un clúster completo de Kubernetes usando contenedores de Docker como "nodos". Cada contenedor de Docker actúa como si fuera un servidor real — ejecuta kubelet, el runtime de contenedores y todos los componentes de Kubernetes.

```

Tu laptop
└── Docker
└── Contenedor Docker (actúa como un Nodo de K8s)
├── kubelet
├── containerd
└── Tus Pods

````

Esto es perfecto para aprender — es gratis, corre localmente y es **idéntico** a Kubernetes real.

---

## Paso 1: Revisar la configuración de KIND

Necesitamos un archivo de configuración personalizado para habilitar Ingress (enrutamiento de tráfico externo). Este archivo ya está en el repositorio:

```bash
cat manifests/kind-config.yaml
````

```yaml
# manifests/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
```

### ¿Qué hace esta configuración?

| Configuración                     | Propósito                                                                           |
| --------------------------------- | ----------------------------------------------------------------------------------- |
| `role: control-plane`             | Este nodo es tanto plano de control como worker, lo cual está bien para aprendizaje |
| `node-labels: ingress-ready=true` | Marca el nodo para que el controlador de Ingress pueda programarse allí             |
| `extraPortMappings`               | Redirige los puertos 80/443 de tu laptop → hacia dentro del clúster                 |

---

## Paso 2: Crear el clúster

```bash
kind create cluster --name workshop --config manifests/kind-config.yaml
```

Salida esperada (toma de 1 a 3 minutos):

```
Creating cluster "workshop" ...
 ✓ Ensuring node image (kindest/node:v1.29.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-workshop"
Have a nice day! 👋
```

---

## Paso 3: Verificar el clúster

```bash
# Confirmar que kubectl apunta a tu nuevo clúster
kubectl cluster-info --context kind-workshop

# Revisar nodos
kubectl get nodes

# Esperado:
# NAME                     STATUS   ROLES           AGE   VERSION
# workshop-control-plane   Ready    control-plane   2m    v1.29.0
```

---

## Paso 4: Explorar el clúster

```bash
# Ver todos los pods del sistema que están corriendo en el clúster
kubectl get pods --all-namespaces

# Forma abreviada equivalente
kubectl get pods -A

# ¿Qué namespaces existen por defecto?
kubectl get namespaces
```

Vas a ver namespaces como:

* `kube-system` — componentes del sistema de Kubernetes
* `kube-public` — datos de lectura pública
* `kube-node-lease` — datos de latido de los nodos
* `local-path-storage` — clase de almacenamiento por defecto de KIND

---

## Paso 5: Entender los contextos de kubectl

Un **contexto** es una conexión guardada a un clúster. Puedes tener varios clústeres y cambiar entre ellos.

```bash
# Ver todos los contextos
kubectl config get-contexts

# Ver el contexto actual
kubectl config current-context

# Cambiar de contexto (si tuvieras varios clústeres)
kubectl config use-context kind-workshop
```

---

## Hoja rápida de KIND

```bash
# Listar todos los clústeres KIND
kind get clusters

# Eliminar el clúster al terminar
kind delete cluster --name workshop

# Cargar una imagen local de Docker en KIND
# (necesario si construyes tu propia imagen)
kind load docker-image my-image:tag --name workshop

# Obtener logs del clúster
kind export logs /tmp/kind-logs --name workshop
```

---

## 🧪 Laboratorio: Explora qué está corriendo

Ejecuta estos comandos y mira la salida:

```bash
# ¿Qué pods ejecutan el clúster en sí?
kubectl get pods -n kube-system

# ¿Qué está haciendo el API server?
kubectl get componentstatuses 2>/dev/null || echo "Usa: kubectl get --raw='/readyz?verbose'"

# ¿Qué recursos puede administrar Kubernetes? - Linux/WSL
kubectl api-resources | head -30

# ¿Qué recursos puede administrar Kubernetes? - PowerShell
kubectl api-resources | Select-Object -First 30
```

---

**➡️ Siguiente:** [Módulo 3 — Namespaces](../03-namespaces/README.md)


