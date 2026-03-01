# Linux Guide

## Install tools

Docker (Debian/Ubuntu example):

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

Install KIND:

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Install kubectl:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

Install Helm:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Verify

```bash
docker --version
kind --version
kubectl version --client
helm version
```

## Run workshop automation

```bash
bash platform-edition/scripts/setup.sh
bash platform-edition/scripts/verify.sh
```

## Teardown

```bash
bash platform-edition/scripts/teardown.sh
```
