# kubectl Cheat Sheet — Kubernetes Beginners Workshop

## Context & Cluster

```bash
kubectl config get-contexts                    # List all contexts
kubectl config current-context                 # Show current context
kubectl config use-context kind-workshop       # Switch context
kubectl cluster-info                           # Show cluster info
kubectl get nodes                              # List nodes
kubectl top nodes                              # Node resource usage (needs metrics-server)
```

## Namespaces

```bash
kubectl get namespaces                         # List namespaces (also: get ns)
kubectl create namespace <name>                # Create namespace
kubectl delete namespace <name>                # Delete namespace (and everything in it!)
kubectl config set-context --current --namespace=<ns>  # Set default namespace
```

## Pods

```bash
kubectl get pods -n <ns>                       # List pods in namespace
kubectl get pods -A                            # List pods in ALL namespaces
kubectl get pods -n <ns> -w                   # Watch pods (live updates)
kubectl get pods -n <ns> --show-labels        # Show labels
kubectl get pods -n <ns> -l app=demo-app      # Filter by label
kubectl describe pod <pod> -n <ns>            # Detailed pod info + events
kubectl logs <pod> -n <ns>                    # View logs
kubectl logs <pod> -n <ns> -f                 # Follow (stream) logs
kubectl logs <pod> -n <ns> --previous         # Logs from crashed container
kubectl logs -l app=demo-app -n <ns>          # Logs from all pods matching label
kubectl exec -it <pod> -n <ns> -- /bin/sh     # Shell into pod
kubectl exec -it <pod> -n <ns> -- env         # Print env vars
kubectl delete pod <pod> -n <ns>              # Delete a pod
kubectl top pods -n <ns>                      # Pod resource usage
```

## Deployments

```bash
kubectl get deployments -n <ns>               # List deployments (also: get deploy)
kubectl describe deployment <name> -n <ns>    # Deployment details
kubectl apply -f deployment.yaml              # Create/update deployment
kubectl delete deployment <name> -n <ns>      # Delete deployment
kubectl scale deployment <name> --replicas=5 -n <ns>   # Scale
kubectl set image deployment/<name> <container>=<image> -n <ns>  # Update image
kubectl rollout status deployment/<name> -n <ns>    # Watch rollout
kubectl rollout history deployment/<name> -n <ns>   # Rollout history
kubectl rollout undo deployment/<name> -n <ns>      # Roll back
kubectl rollout undo deployment/<name> --to-revision=1 -n <ns>  # Roll back to rev
kubectl rollout restart deployment/<name> -n <ns>   # Force pod replacement
kubectl rollout pause deployment/<name> -n <ns>     # Pause rollout
kubectl rollout resume deployment/<name> -n <ns>    # Resume rollout
```

## Services

```bash
kubectl get services -n <ns>                  # List services (also: get svc)
kubectl describe svc <name> -n <ns>           # Service details + endpoints
kubectl get endpoints <name> -n <ns>          # Show pod IPs behind service
kubectl port-forward svc/<name> 8080:80 -n <ns>  # Local tunnel to service
kubectl port-forward pod/<name> 8080:80 -n <ns>  # Local tunnel to pod
```

## Ingress

```bash
kubectl get ingress -n <ns>                   # List ingress resources
kubectl describe ingress <name> -n <ns>       # Ingress details + rules
```

## ConfigMaps & Secrets

```bash
kubectl get configmaps -n <ns>                # List configmaps (also: get cm)
kubectl describe cm <name> -n <ns>            # ConfigMap contents
kubectl get secret <name> -n <ns>             # List secrets
kubectl get secret <name> -n <ns> -o yaml     # Show secret (base64)
kubectl get secret <name> -n <ns> -o jsonpath='{.data.KEY}' | base64 -d  # Decode a key

# Imperative creation
kubectl create configmap <name> --from-literal=KEY=VALUE -n <ns>
kubectl create configmap <name> --from-file=config.yaml -n <ns>
kubectl create secret generic <name> --from-literal=KEY=VALUE -n <ns>
```

## Debugging

```bash
kubectl get events -n <ns> --sort-by='.lastTimestamp'   # Cluster events
kubectl describe pod <pod> -n <ns>                       # Best debugging start
kubectl run debug --image=busybox --restart=Never -it --rm -n <ns> -- sh  # Debug pod
kubectl get all -n <ns>                                   # All resources in namespace
kubectl api-resources                                     # All K8s resource types
kubectl explain deployment.spec.strategy                  # Built-in YAML docs
```

## Output Formats

```bash
kubectl get pods -n <ns> -o wide              # More columns (IP, Node)
kubectl get pods -n <ns> -o yaml              # Full YAML
kubectl get pods -n <ns> -o json              # Full JSON
kubectl get pods -n <ns> -o jsonpath='{.items[*].metadata.name}'  # Extract fields
kubectl get pods -n <ns> -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
```

## Useful Aliases (add to ~/.bashrc or ~/.zshrc)

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kgd='kubectl get deployment'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kd='kubectl describe'
alias ka='kubectl apply -f'
```
