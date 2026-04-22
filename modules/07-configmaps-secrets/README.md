# Módulo 7 — ConfigMaps y Secrets

> ⏱️ **Tiempo:** 20 minutos | 🎯 **Objetivo:** Externalizar la configuración e inyectarla en tu app como variables de entorno y archivos montados

---

## 🧹 Limpieza inicial, restablecer a un estado conocido y correcto

Si ya intentaste este módulo antes, ejecuta estos comandos para borrar todo y empezar desde cero.  
Si es tu primera vez, salta a [Los conceptos](#los-conceptos).

```bash
# Eliminar el deployment actualizado
kubectl delete deployment demo-app -n workshop-app --ignore-not-found

# Eliminar ConfigMap y Secret
kubectl delete configmap demo-app-config -n workshop-app --ignore-not-found
kubectl delete secret demo-app-secret -n workshop-app --ignore-not-found

# Eliminar cualquier ConfigMap rápido del laboratorio que hayas creado
kubectl delete configmap my-quick-config -n workshop-app --ignore-not-found
kubectl delete configmap file-config -n workshop-app --ignore-not-found

# Confirmar que el namespace está limpio, solo deben quedar el Service y el Ingress
kubectl get all -n workshop-app
kubectl get configmaps -n workshop-app
kubectl get secrets -n workshop-app
````

Ahora restaura el deployment base, pods corriendo, todavía sin ConfigMap ni Secret:

```bash
kubectl apply -f manifests/deployment.yaml
kubectl rollout status deployment/demo-app -n workshop-app
# → deployment "demo-app" successfully rolled out

kubectl get pods -n workshop-app
# → 2 pods Running
```

Ya estás en un punto de partida limpio. Continúa abajo.

---

## Los conceptos

### ¿Por qué ConfigMaps y Secrets?

Un principio central de las aplicaciones cloud-native, el enfoque de las 12 Factor Apps, es **separar la configuración del código**.

| ❌ Malo                                                                | ✅ Bueno                                                                              |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Dejar `DB_URL`, API keys o feature flags dentro de la imagen Docker   | Inyectarlos en tiempo de ejecución, misma imagen, distinta configuración por entorno |
| Reconstruir y volver a desplegar la app para cambiar el nivel de logs | Actualizar un ConfigMap con `kubectl apply`                                          |

Kubernetes ofrece dos objetos para esto:

| Objeto        | Para qué sirve                                                       | Cómo se almacena     |
| ------------- | -------------------------------------------------------------------- | -------------------- |
| **ConfigMap** | Configuración no sensible, URLs, feature flags, parámetros de ajuste | Texto plano          |
| **Secret**    | Datos sensibles, contraseñas, API keys, certificados                 | Codificado en Base64 |

> ⚠️ Los Secrets están **codificados** en Base64, no cifrados por defecto. En producción conviene usar Sealed Secrets, External Secrets Operator o HashiCorp Vault.

### Dos formas de consumirlos dentro de un Pod

| Método                   | Cómo                                                | ¿Se actualiza sin reiniciar?              |
| ------------------------ | --------------------------------------------------- | ----------------------------------------- |
| **Variable de entorno**  | `configMapKeyRef` o `secretKeyRef` dentro de `env:` | ❌ No, requiere rollout restart            |
| **Montaje como volumen** | `volumes:` + `volumeMounts:`                        | ✅ Sí, en unos 60 segundos aproximadamente |

Este módulo usa **ambos métodos** para que puedas ver la diferencia.

---

## Paso 1 — Revisar y aplicar el ConfigMap

```bash
cat manifests/configmap.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-app-config
  namespace: workshop-app
data:
  # Pares clave-valor simples, se inyectan como variables de entorno
  APP_ENV: "workshop"
  APP_VERSION: "1.0.0"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  FEATURE_NEW_UI: "false"

  # Valores multilínea, cada uno se convierte en un archivo bajo /etc/config/
  app.properties: |
    environment=workshop
    app.version=1.0.0
    log.level=info
    feature.new_ui=false
    max.connections=100

  feature-flags.json: |
    {
      "new_ui": false,
      "dark_mode": false,
      "max_connections": 100
    }
```

Aplícalo:

```bash
kubectl apply -f manifests/configmap.yaml

kubectl get configmaps -n workshop-app
kubectl describe configmap demo-app-config -n workshop-app
```

> 💡 Aplicar el ConfigMap por sí solo **no hace nada** sobre tus pods en ejecución. Los pods todavía no saben que existe. Eso ocurre en el Paso 3.

---

## Paso 2 — Revisar y aplicar el Secret

```bash
cat manifests/secret.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-app-secret
  namespace: workshop-app
type: Opaque
stringData:
  DB_PASSWORD: "super-secret-workshop-password"
  API_KEY: "workshop-api-key-12345"
  connection-string: "postgresql://appuser:super-secret-workshop-password@db:5432/workshopdb"
```

> 💡 `stringData` te deja escribir cadenas normales y Kubernetes las codifica automáticamente en Base64. Usa `data:` solo si quieres pasar los valores ya codificados.

Aplícalo:

```bash
kubectl apply -f manifests/secret.yaml

# Los valores quedan ocultos en la salida de describe, esto es intencional
kubectl get secrets -n workshop-app
kubectl describe secret demo-app-secret -n workshop-app

# Decodificar manualmente un valor, solo para aprendizaje
kubectl get secret demo-app-secret -n workshop-app \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
echo ""

#PowerShell
$base64Pass = kubectl get secret demo-app-secret -n workshop-app -o jsonpath='{.data.DB_PASSWORD}'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Pass))

```

> 💡 Aplicar el Secret por sí solo tampoco hace nada en los pods que ya están corriendo.

---

## Paso 3 — Aplicar el Deployment actualizado

> ⚠️ **Este es el paso que más gente olvida.**
>
> El ConfigMap y el Secret ya existen en el clúster, pero tus pods siguen usando `deployment.yaml`,
> que tiene valores `env:` fijos y **no tiene montajes de volumen**. Debes aplicar
> `deployment-with-config.yaml` para conectar todo. Esto dispara una actualización gradual
> que reemplaza los pods viejos por pods nuevos que ya referencian el ConfigMap y el Secret.

Revisa qué cambia:

```bash
diff manifests/deployment.yaml manifests/deployment-with-config.yaml
```

Las diferencias clave en `deployment-with-config.yaml`:

* Las entradas de `env:` ahora usan `configMapKeyRef` y `secretKeyRef` en lugar de `value:`
* Un bloque `volumeMounts:` agrega `/etc/config` y `/etc/secrets` dentro del contenedor
* Un bloque `volumes:` a nivel del pod conecta el ConfigMap y el Secret a esos montajes

Aplícalo:

```bash
kubectl apply -f manifests/deployment-with-config.yaml

# Espera a que termine la actualización gradual antes de probar, no te saltes esto
kubectl rollout status deployment/demo-app -n workshop-app
# → Waiting for deployment "demo-app" rollout to finish: 1 out of 2 new replicas have been updated...
# → deployment "demo-app" successfully rolled out

# Confirmar que cambió la anotación change-cause
kubectl rollout history deployment/demo-app -n workshop-app
# REVISION  CHANGE-CAUSE
# 1         Initial deployment — workshop demo app v1.0.0
# 2         Module 7 — Added ConfigMap and Secret injection

# Obtener nombres nuevos de pods, los viejos ya fueron reemplazados
kubectl get pods -n workshop-app
```

---

## Paso 4 — Verificar variables de entorno

Usa uno de los nombres de pod que te devolvió `kubectl get pods`:

```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  env | grep -E "APP_ENV|APP_VERSION|LOG_LEVEL|FEATURE_NEW_UI|DB_PASSWORD|API_KEY"

#PowerShell
kubectl exec -it <pod-name> -n workshop-app -- \
  env | Select-String "APP_ENV|APP_VERSION|LOG_LEVEL|FEATURE_NEW_UI|DB_PASSWORD|API_KEY"
```

Salida esperada:

```text
APP_ENV=workshop
APP_VERSION=1.0.0
LOG_LEVEL=info
FEATURE_NEW_UI=false
DB_PASSWORD=super-secret-workshop-password
API_KEY=workshop-api-key-12345
```

Los primeros cuatro valores vienen del ConfigMap, y los dos últimos del Secret.

---

## Paso 5 — Verificar archivos montados

```bash
kubectl exec -it <pod-name> -n workshop-app -- ls /etc/config
```

Salida esperada:

```text
APP_ENV
APP_VERSION
FEATURE_NEW_UI
LOG_LEVEL
MAX_CONNECTIONS
app.properties
feature-flags.json
```

> 💡 Cada clave de un ConfigMap se convierte en un archivo cuando se monta como volumen. El nombre del archivo es la clave y el contenido es el valor.

```bash
# Leer el archivo de propiedades
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/app.properties

# Leer el JSON de feature flags
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/feature-flags.json

# Revisar el montaje de secrets
kubectl exec -it <pod-name> -n workshop-app -- ls /etc/secrets
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/secrets/DB_PASSWORD
```

---

## Paso 6 — Actualización en vivo del ConfigMap, auto-refresh del volumen

Los ConfigMaps montados como **volúmenes** se actualizan automáticamente dentro de los pods en ejecución en unos 60 segundos, sin reiniciar.

```bash
# Editar el ConfigMap, cambia LOG_LEVEL de "info" a "debug"
kubectl edit configmap demo-app-config -n workshop-app
# Busca: LOG_LEVEL: "info"
# Cámbialo por: LOG_LEVEL: "debug"
# Guarda y sal

# Espera unos 60 segundos y revisa el archivo montado
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/LOG_LEVEL
# → debug  (actualizado automáticamente)

# La variable de entorno NO cambió, quedó fijada al iniciar el pod
kubectl exec -it <pod-name> -n workshop-app -- env | grep LOG_LEVEL
# → LOG_LEVEL=info   (todavía con el valor anterior)
#PowerShell
kubectl exec -it <pod-name> -n workshop-app -- env | Select-String LOG_LEVEL

# Para actualizar variables de entorno necesitas un rollout restart
kubectl rollout restart deployment/demo-app -n workshop-app
kubectl rollout status deployment/demo-app -n workshop-app

kubectl exec -it <new-pod-name> -n workshop-app -- env | grep LOG_LEVEL
# → LOG_LEVEL=debug  (ahora sí actualizado)

# Restablecer a "info" para que el Módulo 8 empiece limpio
kubectl patch configmap demo-app-config -n workshop-app \
  --type merge -p '{"data":{"LOG_LEVEL":"info"}}'
kubectl rollout restart deployment/demo-app -n workshop-app
kubectl rollout status deployment/demo-app -n workshop-app
```

---

## 🧪 Ejercicios de laboratorio

```bash
# 1. Crear un ConfigMap desde valores literales en línea
kubectl create configmap my-quick-config \
  --from-literal=COLOR=blue \
  --from-literal=FONT_SIZE=16 \
  -n workshop-app

kubectl get cm my-quick-config -n workshop-app -o yaml

# 2. Crear un ConfigMap desde un archivo local
echo "my workshop config content" > /tmp/my-config.txt
kubectl create configmap file-config \
  --from-file=/tmp/my-config.txt \
  -n workshop-app

kubectl describe configmap file-config -n workshop-app

# 3. Decodificar todos los valores del Secret de una sola vez
kubectl get secret demo-app-secret -n workshop-app \
  -o jsonpath='{range .data.*}{@}{"\n"}{end}' | while read val; do
    echo "$val" | base64 -d; echo ""
  done
#PowerShell
kubectl get secret demo-app-secret -n workshop-app -o jsonpath="{range .data.*}{@}{'\n'}{end}" |
ForEach-Object {
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
    ""
}

# 4. Ver la alternativa envFrom, inyectar todas las claves del ConfigMap de una sola vez
kubectl explain pod.spec.containers.envFrom
```

---

## 🔍 Solución de problemas

**`ls: /etc/config: No such file or directory`**

Entraste a un pod del deployment viejo, el que no tiene montajes de volumen. Confirma esto:

```bash
kubectl describe deployment demo-app -n workshop-app | grep change-cause
# Debe mostrar: Module 7 — Added ConfigMap and Secret injection
# Si muestra: Initial deployment, entonces el Paso 3 nunca se completó
```

Solución:

```bash
kubectl apply -f manifests/deployment-with-config.yaml
kubectl rollout status deployment/demo-app -n workshop-app
kubectl get pods -n workshop-app   # obtén nombres nuevos y vuelve a probar
```

---

**`APP_ENV=workshop` aparece pero `DB_PASSWORD` no**

La causa suele ser la misma. Los pods todavía vienen del deployment viejo con valores fijos o el Secret nunca fue aplicado.

```bash
kubectl get secret demo-app-secret -n workshop-app   # confirma que existe

# Si no existe:
kubectl apply -f manifests/secret.yaml

# Vuelve a aplicar el deployment y espera
kubectl apply -f manifests/deployment-with-config.yaml
kubectl rollout status deployment/demo-app -n workshop-app
```

---

**El pod se queda en `CreateContainerConfigError`**

El ConfigMap o el Secret referenciado en el deployment todavía no existe. Aplícalos primero y el pod pendiente debería recuperarse automáticamente:

```bash
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml

# El pod debería autorepararse en pocos segundos
kubectl get pods -n workshop-app -w
```

---

## Resumen

El orden correcto para aplicar este módulo siempre es:

```text
configmap.yaml  →  secret.yaml  →  deployment-with-config.yaml
```

| Recurso                       | Qué hace al aplicarlo                                                                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `configmap.yaml`              | Crea el objeto ConfigMap, los pods todavía no lo usan                                                                                       |
| `secret.yaml`                 | Crea el objeto Secret, los pods todavía no lo usan                                                                                          |
| `deployment-with-config.yaml` | **Conecta todo** y dispara un rolling restart para crear nuevos pods que ya referencian ambos objetos como variables de entorno y volúmenes |

**La regla de oro: ConfigMaps y Secrets no hacen nada hasta que una especificación de Pod los referencia explícitamente.**

---

**➡️ Siguiente:** [Módulo 8 — Escalado y actualizaciones graduales](../08-scaling-updates/README.md)

