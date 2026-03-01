# Module 1 — Containers & Kubernetes Concepts

> ⏱️ **Time:** 20 minutes | 🎯 **Goal:** Understand WHY Kubernetes exists and the key building blocks

---

## The Problem: "It Works on My Machine"

Before containers, deploying software was painful:
- "Works on dev, broken in prod" — because environments differed
- Dependency conflicts between apps on the same server
- Hard to scale — you'd provision a whole new VM for more capacity
- Slow deployments — spinning up VMs takes minutes to hours

---

## Containers: Ship the Environment, Not Just the Code

A **container** packages your app **and** all its dependencies (libraries, runtime, config) into a single portable image.

```
┌─────────────────────────────────────────────┐
│                  Container                   │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Your    │  │ Runtime  │  │   Libs &  │  │
│  │   App    │  │ (Node/   │  │   Deps    │  │
│  │          │  │  Python) │  │           │  │
│  └──────────┘  └──────────┘  └───────────┘  │
└─────────────────────────────────────────────┘
         Runs identically anywhere Docker runs
```

### Container vs Virtual Machine

| | Container 🐳 | Virtual Machine 🖥️ |
|--|---|---|
| Starts in | Milliseconds | Minutes |
| Size | Megabytes | Gigabytes |
| OS | Shares host kernel | Full guest OS |
| Isolation | Process-level | Hardware-level |
| Best for | Microservices | Legacy monoliths |

---

## Why Kubernetes? The Problem with "Just Containers"

Containers are great — but in production you have dozens or hundreds of them:

- **Who restarts a crashed container?**
- **How do you update 50 containers with zero downtime?**
- **How do you route traffic to healthy containers only?**
- **How do you scale up when traffic spikes?**

**Kubernetes (K8s)** is a container **orchestrator** — it manages containers at scale across a cluster of machines.

> 🔑 **Key insight:** You tell Kubernetes *what you want* (desired state), and Kubernetes makes it happen and keeps it that way. This is called **reconciliation**.

---

## Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     CONTROL PLANE                        │
│                                                          │
│  ┌───────────┐  ┌──────┐  ┌─────────────────────────┐  │
│  │ API Server│  │ etcd │  │ Controller Manager       │  │
│  │ (front    │  │(state│  │ (watches & reconciles)   │  │
│  │  door)    │  │ db)  │  │                          │  │
│  └───────────┘  └──────┘  └─────────────────────────┘  │
│       │                ┌────────────┐                    │
│       │                │  Scheduler │                    │
│       │                │ (places    │                    │
│       │                │  pods)     │                    │
│       │                └────────────┘                    │
└───────┼─────────────────────────────────────────────────┘
        │ kubectl commands go here
        ▼
┌───────────────────┐    ┌───────────────────┐
│    WORKER NODE 1  │    │    WORKER NODE 2  │
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

### Control Plane Components

| Component | Role |
|-----------|------|
| **API Server** | The front door — all `kubectl` commands talk to this |
| **etcd** | The cluster's memory — stores all state as key-value pairs |
| **Scheduler** | Decides which Node gets each new Pod |
| **Controller Manager** | Watches state, takes corrective action (runs Deployment controller, etc.) |

### Node Components

| Component | Role |
|-----------|------|
| **kubelet** | Agent on each Node — runs Pods, reports health back to control plane |
| **kube-proxy** | Manages network rules to route traffic to the right Pod |
| **Container Runtime** | Actually runs containers (containerd, CRI-O) |

---

## Core Kubernetes Objects

Think of these as building blocks. We'll create each one in the workshop:

```
Ingress        ← HTTP routing from outside the cluster
    │
    ▼
Service        ← Stable internal address + load balancer for Pods
    │
    ▼
Deployment     ← "Always run N copies of this Pod"
    │
    ▼
Pod            ← One or more containers running together
    │
    ▼
Container      ← Your actual app (Docker image)
```

| Object | Analogy | What it does |
|--------|---------|-------------|
| **Pod** | A running process | The smallest unit — one or more containers sharing network/storage |
| **Deployment** | A job posting | "Always keep 3 copies of this Pod running" |
| **Service** | A phone number | Stable endpoint for a set of Pods (they come and go, the number stays) |
| **Ingress** | A receptionist | Routes incoming HTTP requests to the right Service |
| **ConfigMap** | A config file | Non-secret configuration data injected into Pods |
| **Secret** | A locked config file | Sensitive data (passwords, tokens) injected into Pods |
| **Namespace** | A folder | Virtual cluster — isolates resources by team/environment |

---

## The Kubernetes Workflow

```
Developer writes YAML → kubectl apply → API Server → etcd (stores desired state)
                                                           │
                                              Controller watches etcd
                                                           │
                                              Scheduler picks a Node
                                                           │
                                              kubelet runs the Pod
                                                           │
                                              kubelet reports status back
```

---

## 💡 Key Mental Model: Desired vs. Actual State

Kubernetes continuously asks: **"Is actual state == desired state?"**

- You say: "I want 3 replicas"
- One Pod crashes → actual state = 2
- Controller notices → starts a new Pod → actual state = 3 ✅
- This loop runs **constantly**. This is **self-healing**.

---

**➡️ Next:** [Module 2 — Creating Your KIND Cluster](../02-kind-cluster/README.md)
