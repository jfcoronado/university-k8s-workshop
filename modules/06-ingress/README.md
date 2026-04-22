# Módulo 6 — Ingress: Enrutamiento de tráfico externo

> ⏱️ **Tiempo:** 25 minutos | 🎯 **Objetivo:** Instalar un controlador Ingress y enrutar tráfico HTTP externo hacia tu aplicación

---

## ¿Qué es Ingress?

**Ingress** es un recurso de Kubernetes que administra el acceso HTTP/HTTPS externo hacia los Services dentro de un clúster.

Piensa en él como un **router inteligente** — un único punto de entrada que dirige el tráfico a distintos Services según:
- **Hostname:** `api.example.com` → api-service, `app.example.com` → frontend-service
- **Path:** `/api/*` → backend-service, `/` → frontend-service

```

Internet
│
▼
Puerto 80 (tu laptop / balanceador de carga en la nube)
│
▼
┌─────────────────────────────────────┐
│        Controlador Ingress          │
│      (Traefik ejecutándose como Pod)│
│                                     │
│ Regla: demo.local / → demo-app-svc  │
└─────────────────────────────────────┘
│
▼
Service: demo-app-svc
│
├── Pod 1
└── Pod 2

````

---

## Ingress vs. Service LoadBalancer

| | Service LoadBalancer | Ingress |
|--|--|--|
| Capa | L4 (TCP/UDP) | L7 (HTTP/HTTPS) |
| Enrutamiento por path | ❌ No | ✅ Sí |
| Terminación TLS | ❌ No | ✅ Sí |
| Costo en la nube | 1 LB por service ($$) | 1 LB para todos los services (barato ✅) |
| Manipulación de headers | ❌ No | ✅ Sí |

> 🏭 **Patrón de producción:** Un LoadBalancer en la nube → Controlador Ingress → muchos Services

---

## ¿Por qué Traefik?

Este workshop usa **Traefik** como controlador Ingress en lugar de NGINX Ingress. Estas son las razones:

| | NGINX Ingress | Traefik |
|--|--|--|
| Multi-arquitectura (Intel/AMD/Apple Silicon/ARM) | ❌ Imágenes separadas por arquitectura, propensas a errores de descarga | ✅ Una sola imagen multi-arquitectura, funciona en todas partes |
| Complejidad de instalación | ❌ 3 pods, admission webhooks, YAML extenso | ✅ Un comando Helm, un pod |
| Confiabilidad en Wi-Fi de conferencias | ❌ Imagen grande, problemas con límites de descarga | ✅ Imagen pequeña, alrededor de 50 MB, descarga rápida |
| Relevancia en producción | ⚠️ En proceso de retiro en marzo de 2026 | ✅ Mantenido activamente, reemplazo recomendado |

Los conceptos de Ingress que aprendes aquí — reglas, hostnames, paths y backends — son **idénticos** sin importar el controlador que uses. Cambiar de controlador en un clúster real normalmente es solo un cambio de una línea, `ingressClassName`.

---

## Paso 1: Instalar Helm

Helm es el gestor de paquetes de Kubernetes. Lo usamos para instalar Traefik.

**macOS:**
```bash
brew install helm
````

**Linux:**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows:**

```powershell
winget install Helm.Helm
```

Verifica:

```bash
helm version
# version.BuildInfo{Version:"v3.x.x"...}
```

**Windows (WSL2):**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## Paso 2: Predescargar la imagen de Traefik en KIND

Como los nodos de KIND corren dentro de contenedores Docker, no siempre pueden acceder directamente a internet, especialmente en redes corporativas o con Wi-Fi de conferencias. Descárgala antes en tu host y luego cárgala en KIND:

```bash
docker pull traefik:v3.0
kind load docker-image traefik:v3.0 --name workshop
```

Verifica que esté dentro del clúster:

```bash
docker exec workshop-control-plane crictl images | grep traefik

#PowerShell
docker exec workshop-control-plane crictl images | Select-String "traefik"
```

---

## Paso 3: Instalar Traefik

Usamos un archivo de valores, `manifests/traefik-values.yaml`, para configurar Traefik correctamente para KIND. Esto configura el modo DaemonSet con hostNetwork para que el tráfico fluya correctamente a través de los mapeos de puertos de KIND.

```bash
# Agregar el repositorio oficial del chart Helm de Traefik
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Instalar Traefik usando el archivo de valores preconfigurado
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --values manifests/traefik-values.yaml \
  --wait
```

> 💡 `--wait` bloquea hasta que Traefik esté completamente corriendo. Debe completarse en menos de 60 segundos.

Verifica que esté corriendo:

```bash
kubectl get pods -n traefik
```

Salida esperada:

```text
NAME                       READY   STATUS    RESTARTS   AGE
traefik-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

Un pod. Corriendo. Listo. ✅

---

## Paso 4: Revisar el YAML de Ingress

```bash
cat manifests/ingress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
  namespace: workshop-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik    # Qué controlador Ingress manejará esto
  rules:
    - host: demo.local          # Coincide con solicitudes que tengan este Host header
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: demo-app-svc
                port:
                  number: 80
```

### Campos clave

| Campo                       | Qué hace                                                       |
| --------------------------- | -------------------------------------------------------------- |
| `ingressClassName: traefik` | Le dice a Kubernetes qué controlador administra este Ingress   |
| `host: demo.local`          | Solo coincide con solicitudes con el header `Host: demo.local` |
| `path: /`                   | Coincide con todos los paths                                   |
| `pathType: Prefix`          | Coincide con `/` y todo lo que está debajo                     |
| `backend.service`           | Reenvía el tráfico coincidente a este Service en ese puerto    |

---

## Paso 5: Aplicar el Ingress

```bash
kubectl apply -f manifests/ingress.yaml
```

Verifica:

```bash
kubectl get ingress -n workshop-app
```

Salida esperada:

```text
NAME               CLASS     HOSTS        ADDRESS     PORTS   AGE
demo-app-ingress   traefik   demo.local   localhost   80      15s
```

---

## Paso 6: Configurar DNS local

`demo.local` es un hostname ficticio — necesitamos decirle a tu laptop que lo resuelva hacia localhost.

**macOS / Linux:**

```bash
echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
```

**Windows (PowerShell como Administrador):**

```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value '127.0.0.1 demo.local'
```

Verifica:

```bash
ping -c 1 demo.local
# Debe mostrar: 127.0.0.1
```

**Windows (WSL2):**

```bash
# Tu navegador corre en Windows, no dentro de WSL2.
# Edita el archivo hosts de Windows usando el bloque de PowerShell de arriba,
# luego abre http://demo.local en tu navegador normal de Windows.
```

---

## Paso 7: Prueba de extremo a extremo

Abre [http://demo.local](http://demo.local) en tu navegador. Deberías ver la app del workshop. 🎉

Refresca varias veces — observa cómo cambia el **Pod Name** en la tarjeta principal mientras Traefik balancea la carga entre tus dos pods.

También puedes probar desde la terminal:

```bash
curl http://demo.local/health
# {"status":"ok","pod":"demo-app-xxx","uptime":"5m"}
```

---

## Entendiendo el flujo completo del tráfico

```
1. Abres: http://demo.local
2. Navegador → /etc/hosts → resuelve demo.local a 127.0.0.1
3. La solicitud llega al puerto 80 de tu laptop
4. KIND extraPortMapping → puerto 80 dentro del clúster
5. El pod de Traefik recibe la solicitud
6. Traefik lee el header Host: demo.local
7. Coincide con la regla de Ingress: demo.local / → demo-app-svc:80
8. El Service balancea la carga hacia uno de los 2 Pods
9. El Pod responde → vuelve por toda la cadena → a tu navegador
```

---

## 🧪 Laboratorio: Enrutamiento de múltiples servicios

Esto es lo que hace poderoso a Ingress — un solo controlador, múltiples aplicaciones. Imagina que tuvieras un segundo service:

```yaml
# Regla hipotética de un segundo Ingress
- host: api.local
  http:
    paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```

Tanto `demo.local` como `api.local` pasarían por **el mismo pod de Traefik** y serían dirigidos a distintos Services. En un clúster en la nube esto significa un balanceador de carga en lugar de uno por cada service.

---

## 🧪 Laboratorio: Dashboard de Traefik

Traefik incluye un dashboard integrado que muestra todas las rutas, services y middleware:

```bash
kubectl port-forward -n traefik $(kubectl get pods -n traefik -o name) 9000:9000
```

Abre [http://localhost:9000/dashboard/](http://localhost:9000/dashboard/) — verás tu ruta `demo.local` listada.

Presiona `Ctrl+C` cuando termines.

---

**➡️ Siguiente:** [Módulo 7 — ConfigMaps y Secrets](../07-configmaps-secrets/README.md)
