# macOS Guide (Intel + Apple Silicon)

## Install tools

```bash
brew install --cask docker
brew install kind kubectl helm
```

Start Docker Desktop and wait until `docker info` succeeds.

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

## Hosts file

The setup script adds `demo.local` to `/etc/hosts` with sudo if missing.

Manual fallback:

```bash
echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
```

## Teardown

```bash
bash platform-edition/scripts/teardown.sh
```
