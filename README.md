# ☸️ Taller de Kubernetes para Principiantes

¡Bienvenido! Este repositorio contiene todo lo necesario para seguir un taller introductorio de **Kubernetes para Principiantes**.

Este fork está basado en el taller original creado por **Faisal Afzal** y ha sido adaptado para una audiencia, contexto y formato de entrega diferentes.

---

## 🎯 Qué vas a construir

Al finalizar este taller, tendrás:

- ✅ Un clúster local de Kubernetes ejecutándose con KIND
- ✅ Una aplicación real desplegada con Namespaces, Deployments y Pods
- ✅ Un Service exponiendo tu aplicación dentro del clúster
- ✅ Traefik Ingress enroutando tráfico HTTP externo (instalado mediante Helm)
- ✅ ConfigMaps y Secrets inyectados en tu aplicación como variables de entorno y archivos montados
- ✅ Escalado horizontal y actualizaciones continuas sin tiempo de inactividad
- ✅ Una estrategia de rollback para despliegues fallidos

---

## 🗂️ Módulos del taller

| # | Módulo | Tiempo |
|---|--------|------|
| 0 | [Lista de verificación previa](modules/00-preflight/README.md) | 15 min |
| 1 | [Contenedores y conceptos de Kubernetes](modules/01-concepts/README.md) | 20 min |
| 2 | [Creación de tu clúster KIND](modules/02-kind-cluster/README.md) | 20 min |
| 3 | [Namespaces — Organización del clúster](modules/03-namespaces/README.md) | 10 min |
| 4 | [Deployments — Ejecución de tu aplicación](modules/04-deployments/README.md) | 25 min |
| 5 | [Services — Redes internas](modules/05-services/README.md) | 20 min |
| 6 | [Ingress — Enrutamiento de tráfico externo con Traefik](modules/06-ingress/README.md) | 25 min |
| 7 | [ConfigMaps y Secrets](modules/07-configmaps-secrets/README.md) | 20 min |
| 8 | [Escalado y Rolling Updates](modules/08-scaling-updates/README.md) | 20 min |
| 9 | [Bonus: Solución de problemas y recomendaciones](modules/09-bonus/README.md) | abierto |

---

## ⚙️ Requisitos previos

| Herramienta | Versión mínima | Instalación |
|------|-------------|---------|
| Docker Desktop | v24+ | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| kind | v0.23+ | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/) |
| kubectl | v1.29+ | [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/) |
| helm | v3.14+ | [helm.sh/docs/intro/install](https://helm.sh/docs/intro/install/) |

> 💡 **¿Eres nuevo en la línea de comandos?** Revisa la carpeta [scripts/](scripts/) para encontrar scripts de apoyo.

---

## 🚀 Inicio rápido

### 1. Clona este repositorio

```bash
git clone https://github.com/faisalcodesinfrastructure/scale23x-k8s-workshop.git
cd scale23x-k8s-workshop
````

### 2. Descarga previamente las imágenes

```bash
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0
```

### 3. Crea el clúster KIND

```bash
kind create cluster --name workshop --config manifests/kind-config.yaml
kubectl config use-context kind-workshop
kubectl wait --for=condition=Ready node --all --timeout=120s
```

### 4. Instala el controlador Traefik Ingress

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  -f manifests/traefik-values.yaml \
  --wait
```

**PowerShell:**

```powershell
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik `
  --namespace traefik `
  --create-namespace `
  -f manifests/traefik-values.yaml `
  --wait
```

### 5. Construye y carga la aplicación del taller

```bash
docker build -t k8s-workshop-demo:1.0.0 ./app
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
```

### 6. Aplica todos los manifiestos

```bash
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml
kubectl rollout status deployment/demo-app -n workshop-app --timeout=120s
```

### 7. Agrega la entrada al archivo hosts

**macOS / Linux / WSL:**

```bash
echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
```

**Windows (PowerShell como administrador):**

```powershell
Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "127.0.0.1 demo.local"
```

### 8. Verifica

Abre **[http://demo.local](http://demo.local)** en tu navegador.

### 9. Sigue los módulos en orden

---

## 🧱 Estructura del repositorio

```
k8s-workshop/
├── README.md                    ← Estás aquí
├── manifests/                   ← Todos los archivos YAML (¡aplica estos!)
│   ├── kind-config.yaml
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secret.yaml
├── app/                         ← Código fuente de la aplicación de demostración (opcional)
│   ├── Dockerfile
│   └── index.html
├── modules/                     ← Guías paso a paso por módulo
│   ├── 00-preflight/
│   ├── 01-concepts/
│   └── ...
├── scripts/                     ← Scripts de apoyo
│   ├── setup.sh / setup.ps1
│   ├── teardown.sh / teardown.ps1
│   └── verify.sh / verify.ps1
└── docs/                        ← Material de referencia adicional
    └── kubectl-cheatsheet.md
```

---

## 🙌 Créditos

Este taller está basado en el workshop original de Kubernetes creado por **Faisal Afzal**.

Este fork ha sido adaptado y mantenido para una audiencia, entorno de aprendizaje y formato de presentación diferentes.

* 📚 [Documentación oficial de Kubernetes](https://kubernetes.io/docs/)
* 💬 Únete a [CNCF Slack](https://slack.cncf.io/) — canal #kubernetes

---

*Si este taller te resultó útil, considera darle una ⭐ al repositorio. Eso ayuda a que otras personas lo encuentren.*

````

Y te recomiendo además hacer estos ajustes antes de subirlo:

- cambiar la URL de `git clone` por la de tu fork
- cambiar `cd scale23x-k8s-workshop` por el nombre real de tu repo
- revisar si en otros archivos aparece `SCaLE`, `AHEAD`, `Faisal`, o `scale23x`
- si quieres, agregar una línea como esta en créditos:

```md
Adaptado y mantenido por Jose Coronado.
````
