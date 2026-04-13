# Módulo 0 - Lista de verificación previa al vuelo (multiplataforma)

Tiempo: 15 minutos  
Objetivo: Instalar las herramientas, verificarlas y predescargar las imágenes clave antes del workshop.

## 1) Instalar las herramientas requeridas

### macOS

# Reemplaza {{USER.NAME}} con la salida de whoami

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /Users/{{USER.NAME}}/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> /Users/{{USER.NAME}}/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
brew install git
brew install --cask docker
brew install kind kubectl helm
````

### Linux

```bash
sudo apt update && sudo apt install -y git curl

curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Windows (PowerShell)

```powershell
winget install Git.Git
winget install Docker.DockerDesktop
winget install Kubernetes.kind
winget install Kubernetes.kubectl
winget install Helm.Helm
```

**Windows (WSL2):**

```bash
sudo apt update && sudo apt install -y git
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
```

```bash
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```

**Windows (WSL2):**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 2) Verificar las herramientas

### Bash shells (macOS/Linux/WSL)

```bash
git --version
docker --version
kind --version
kubectl version --client
helm version
docker info
```

### PowerShell

```powershell
git --version
docker --version
kind --version
kubectl version --client
helm version
docker info
```

## 3) Predescargar imágenes

```bash
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0
```

Si estás en un host ARM y ves errores de arquitectura de imagen, vuelve a intentarlo con:

```bash
docker pull --platform linux/amd64 kindest/node:v1.29.0
docker pull --platform linux/amd64 traefik:v3.0
```

## 4) Configuración opcional con un solo comando

* macOS/Linux/WSL:

```bash
bash platform-edition/scripts/setup.sh
```

* Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\platform-edition\scripts\setup.ps1
```

## Siguiente paso

Continúa con el Módulo 1 del contenido original del workshop.
