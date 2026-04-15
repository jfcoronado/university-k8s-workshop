# Módulo 3 — Namespaces: Organizando tu clúster

> ⏱️ **Tiempo:** 10 minutos | 🎯 **Objetivo:** Entender y crear Namespaces para organizar recursos

---

## ¿Qué es un Namespace?

Un **Namespace** es un clúster virtual dentro de tu clúster de Kubernetes. Piensa en él como una carpeta — agrupa recursos relacionados y proporciona aislamiento.

```

cluster
├── namespace: kube-system     (componentes del sistema de K8s)
├── namespace: default         (aquí van las cosas si no especificas uno)
├── namespace: workshop-app    ← Este es el que vamos a crear
└── namespace: monitoring      (por ejemplo, Prometheus, Grafana)

````

### ¿Por qué usar Namespaces?

| Caso de uso | Ejemplo |
|----------|---------|
| **Aislamiento por entorno** | `dev`, `staging`, `prod` en un mismo clúster |
| **Aislamiento por equipo** | `team-frontend`, `team-backend` |
| **Aislamiento por aplicación** | `monitoring`, `logging`, `workshop-app` |
| **Cuotas de recursos** | Limitar CPU/memoria por namespace |
| **Alcance de RBAC** | Darle a un equipo acceso solo a su namespace |

> ⚠️ **Los Namespaces NO proporcionan aislamiento de seguridad** por defecto — solo separación lógica. Usa Network Policies para aislar tráfico.

---

## Paso 1: Crear un Namespace con kubectl

La forma más rápida:

```bash
kubectl create namespace workshop-app
````

Verifica que existe:

```bash
kubectl get namespaces
# o forma corta
kubectl get ns
```

---

## Paso 2: Crear un Namespace con YAML (la forma GitOps)

Usar YAML es mejor para proyectos reales — es declarativo y queda versionado.

```bash
cat manifests/namespace.yaml
```

```yaml
# manifests/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: workshop-app
  labels:
    environment: workshop
    managed-by: kubectl
```

Elimina el namespace creado antes y aplícalo usando el manifiesto, o verás un "Warning", aunque no es grave:

```bash
kubectl delete namespace workshop-app
kubectl apply -f manifests/namespace.yaml
```

> 💡 `kubectl apply` es idempotente — si lo ejecutas otra vez, no dará error si el namespace ya existe.

---

## Paso 3: Trabajar dentro de un Namespace

La mayoría de los comandos de kubectl necesitan `-n <namespace>` para apuntar a un namespace específico:

```bash
# Listar pods en un namespace específico
kubectl get pods -n workshop-app

# Obtener TODOS los recursos en TODOS los namespaces
kubectl get pods --all-namespaces
kubectl get pods -A   # forma corta

# Definir un namespace por defecto para tu sesión (opcional)
kubectl config set-context --current --namespace=workshop-app
# Ahora no necesitas -n workshop-app en cada comando
# Restablecer con:
kubectl config set-context --current --namespace=default
```

---

## Entendiendo el Namespace `default`

Si no especificas un namespace, los comandos van a `default`:

```bash
# Estos son equivalentes cuando el namespace actual es 'default'
kubectl get pods
kubectl get pods -n default
```

> 🏭 **Buena práctica:** Nunca despliegues tus apps en `default` en producción. Usa siempre namespaces con nombre.

---

## Cuotas de recursos por Namespace (vista previa)

Puedes limitar recursos por namespace. No lo aplicaremos hoy, pero así se ve:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: workshop-quota
  namespace: workshop-app
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
```

---

## 🧪 Ejercicios de laboratorio

```bash
# 1. Lista todos los namespaces y fíjate en la edad/estado
kubectl get namespaces

# 2. Describe el namespace workshop-app
kubectl describe namespace workshop-app

# 3. Intenta ver los pods en workshop-app (debe estar vacío)
kubectl get all -n workshop-app
```


**➡️ Siguiente:** [Módulo 4 — Deployments](../04-deployments/README.md)
