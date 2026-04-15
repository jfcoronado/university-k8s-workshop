# Módulo 1 — Conceptos de Contenedores y Kubernetes

> ⏱️ **Tiempo:** 20 minutos | 🎯 **Objetivo:** Entender POR QUÉ existe Kubernetes y cuáles son sus bloques fundamentales

---

## El problema: "Funciona en mi máquina"

Antes de los contenedores, desplegar software era doloroso:
- "Funciona en desarrollo, pero falla en producción" — porque los entornos eran diferentes
- Conflictos de dependencias entre aplicaciones en el mismo servidor
- Difícil de escalar — había que aprovisionar una VM completa nueva para obtener más capacidad
- Despliegues lentos — levantar VMs toma de minutos a horas

---

## Contenedores: llevar el entorno, no solo el código

Un **contenedor** empaqueta tu aplicación **y** todas sus dependencias (librerías, runtime, configuración) en una sola imagen portátil.

```

┌─────────────────────────────────────────────┐
│                 Contenedor                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │   Tu     │  │ Runtime  │  │  Librerías│  │
│  │   app    │  │ (Node/   │  │     y     │  │
│  │          │  │ Python)  │  │ deps      │  │
│  └──────────┘  └──────────┘  └───────────┘  │
└─────────────────────────────────────────────┘
Se ejecuta igual en cualquier lugar donde corra Docker

```

### Contenedor vs máquina virtual

| | Contenedor 🐳 | Máquina virtual 🖥️ |
|--|---|---|
| Inicia en | Milisegundos | Minutos |
| Tamaño | Megabytes | Gigabytes |
| SO | Comparte el kernel del host | SO invitado completo |
| Aislamiento | A nivel de proceso | A nivel de hardware |
| Ideal para | Microservicios | Monolitos heredados |

---

## ¿Por qué Kubernetes? El problema de "solo contenedores"

Los contenedores son geniales — pero en producción tienes decenas o cientos de ellos:

- **¿Quién reinicia un contenedor que se cayó?**
- **¿Cómo actualizas 50 contenedores sin tiempo de inactividad?**
- **¿Cómo enrutas tráfico solo a contenedores saludables?**
- **¿Cómo escalas cuando aumenta el tráfico?**

**Kubernetes (K8s)** es un **orquestador** de contenedores — administra contenedores a escala a través de un clúster de máquinas.

> 🔑 **Idea clave:** Tú le dices a Kubernetes *qué quieres* (estado deseado), y Kubernetes lo hace realidad y lo mantiene así. A esto se le llama **reconciliación**.

---

## Arquitectura de Kubernetes

```

┌─────────────────────────────────────────────────────────┐
│                   PLANO DE CONTROL                      │
│                                                         │
│  ┌───────────┐  ┌──────┐  ┌─────────────────────────┐  │
│  │API Server │  │ etcd │  │ Controller Manager      │  │
│  │(puerta de │  │(base │  │ (observa y reconcilia)  │  │
│  │ entrada)  │  │estado)│ │                         │  │
│  └───────────┘  └──────┘  └─────────────────────────┘  │
│       │                ┌────────────┐                   │
│       │                │ Scheduler  │                   │
│       │                │ (ubica     │                   │
│       │                │  pods)     │                   │
│       │                └────────────┘                   │
└───────┼────────────────────────────────────────────────┘
│ aquí llegan los comandos kubectl
▼
┌───────────────────┐    ┌───────────────────┐
│  NODO WORKER 1    │    │  NODO WORKER 2    │
│                   │    │                   │
│  ┌─────────────┐  │    │  ┌─────────────┐  │
│  │   kubelet   │  │    │  │   kubelet   │  │
│  └─────────────┘  │    │  └─────────────┘  │
│  ┌─────────────┐  │    │  ┌─────────────┐  │
│  │ kube-proxy  │  │    │  │ kube-proxy  │  │
│  └─────────────┘  │    │  └─────────────┘  │
│  ┌────┐  ┌────┐   │    │  ┌────┐  ┌────┐   │
│  │Pod │  │Pod │   │    │  │Pod │  │Pod │   │
│  └────┘  └────┘   │    │  └────┘  └────┘   │
└───────────────────┘    └───────────────────┘

```

### Componentes del plano de control

| Componente | Función |
|-----------|------|
| **API Server** | La puerta de entrada — todos los comandos `kubectl` hablan con este |
| **etcd** | La memoria del clúster — almacena todo el estado como pares clave-valor |
| **Scheduler** | Decide qué Nodo recibe cada nuevo Pod |
| **Controller Manager** | Observa el estado y toma acciones correctivas (ejecuta el controlador de Deployment, etc.) |

### Componentes del nodo

| Componente | Función |
|-----------|------|
| **kubelet** | Agente en cada Nodo — ejecuta Pods y reporta su salud al plano de control |
| **kube-proxy** | Administra reglas de red para enrutar tráfico al Pod correcto |
| **Container Runtime** | Ejecuta realmente los contenedores (containerd, CRI-O) |

---

## Objetos principales de Kubernetes

Piensa en estos como bloques de construcción. Vamos a crear cada uno durante el workshop:

```

Ingress        ← Enrutamiento HTTP desde fuera del clúster
│
▼
Service        ← Dirección interna estable + balanceador de carga para Pods
│
▼
Deployment     ← "Ejecuta siempre N copias de este Pod"
│
▼
Pod            ← Uno o más contenedores ejecutándose juntos
│
▼
Container      ← Tu aplicación real (imagen Docker)

```

| Objeto | Analogía | Qué hace |
|--------|---------|-------------|
| **Pod** | Un proceso en ejecución | La unidad más pequeña — uno o más contenedores que comparten red/almacenamiento |
| **Deployment** | Una oferta de trabajo | "Mantén siempre 3 copias de este Pod ejecutándose" |
| **Service** | Un número de teléfono | Endpoint estable para un conjunto de Pods (ellos vienen y van, el número permanece) |
| **Ingress** | Una recepcionista | Enruta solicitudes HTTP entrantes al Service correcto |
| **ConfigMap** | Un archivo de configuración | Datos de configuración no secretos inyectados en Pods |
| **Secret** | Un archivo de configuración bajo llave | Datos sensibles (contraseñas, tokens) inyectados en Pods |
| **Namespace** | Una carpeta | Clúster virtual — aísla recursos por equipo/entorno |

---

## El flujo de trabajo de Kubernetes

```

El desarrollador escribe YAML → kubectl apply → API Server → etcd (almacena el estado deseado)
│
El controlador observa etcd
│
El Scheduler elige un Nodo
│
kubelet ejecuta el Pod
│
kubelet reporta el estado de vuelta

```

---

## 💡 Modelo mental clave: estado deseado vs estado real

Kubernetes pregunta continuamente: **"¿El estado real es igual al estado deseado?"**

- Tú dices: "Quiero 3 réplicas"
- Un Pod falla → estado real = 2
- El controlador lo detecta → inicia un nuevo Pod → estado real = 3 ✅
- Este ciclo corre **constantemente**. Esto es **autoreparación**.

---

**➡️ Siguiente:** [Módulo 2 — Creando tu clúster KIND](../02-kind-cluster/README.md)