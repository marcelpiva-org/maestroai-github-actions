# K3d ARC Setup Guide

Complete guide for deploying GitHub Actions Runner Controller (ARC) on K3d for local CI/CD.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ K3d Cluster (maestroai-arc)                            │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Server-0   │  │   Agent-0    │  │   Agent-1    │  │
│  │              │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  Namespace: arc-systems                                 │
│  └─ ARC Controller Pod                                  │
│                                                          │
│  Namespace: arc-runners                                 │
│  ├─ Listener Pod                                        │
│  └─ Runner Pods (0-5, auto-scaled)                     │
│     └─ hostNetwork: true (fixes TLS timeout)           │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
brew install k3d kubectl helm gh
```

## Installation

### 1. Create K3d Cluster

```bash
k3d cluster create maestroai-arc \
  --agents 2 \
  --wait
```

### 2. Install ARC Controller

```bash
helm install arc-gha-rs-controller \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
  --namespace arc-systems \
  --create-namespace \
  --version 0.12.1 \
  --wait
```

### 3. Install ARC Runner Scale Set

```bash
# Get GitHub PAT with repo and admin:org scopes
export GITHUB_PAT="your_github_pat_here"
export GITHUB_ORG="your_org_name"

helm install arc-runner-set \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  --namespace arc-runners \
  --create-namespace \
  --version 0.12.1 \
  --set githubConfigUrl="https://github.com/${GITHUB_ORG}" \
  --set githubConfigSecret.github_token="${GITHUB_PAT}" \
  --set runnerScaleSetName="arc-runner-set" \
  --set minRunners=0 \
  --set maxRunners=5 \
  --set containerMode.type="dind" \
  --set template.spec.hostNetwork=true \
  --set template.spec.dnsPolicy="ClusterFirstWithHostNet" \
  --wait
```

## TLS Timeout Fix

**Problem**: Docker-in-Docker containers fail with TLS handshake timeout when accessing external registries (mcr.microsoft.com).

**Root Cause**: K3d networking isolation prevents dind containers from establishing TLS connections to external registries.

**Solution**: Use `hostNetwork: true` to share the host node's network stack.

```yaml
template:
  spec:
    hostNetwork: true
    dnsPolicy: ClusterFirstWithHostNet
```

### Why This Works

- `hostNetwork: true`: Runner pod uses host node's network interface
- `dnsPolicy: ClusterFirstWithHostNet`: Maintains Kubernetes DNS while using host network
- Result: dind containers can access external networks without TLS timeout

## Usage in Workflows

```yaml
jobs:
  build:
    runs-on: arc-runner-set
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on K3d ARC!"
```

## Verification

```bash
# Check cluster
kubectl get nodes

# Check ARC controller
kubectl get pods -n arc-systems

# Check runner scale set
kubectl get pods -n arc-runners
kubectl get  autoscalingrunnerset -n arc-runners

# Watch runners scale
kubectl get pods -n arc-runners -w
```

## Performance

| Job Type           | Time  | Runner Type    |
|--------------------|-------|----------------|
| Setup & Lint       | 30s   | arc-runner-set |
| Build              | 30s   | arc-runner-set |
| Unit Tests         | 30s   | arc-runner-set |
| Security Scan      | 14s   | arc-runner-set |
| Container Build    | 3min  | arc-runner-set |

**Total CI Fast**: ~4-5 minutes (all jobs on K3d ARC)

## Cost Savings

- GitHub-hosted runners: $36/month ($432/year)
- K3d ARC (local): $0/month
- **Savings**: 100%

## Troubleshooting

### TLS Timeout Errors

```
ERROR: failed to do request: Head "https://mcr.microsoft.com/...": net/http: TLS handshake timeout
```

**Solution**: Ensure `hostNetwork: true` is set in ARC configuration.

### Runners Not Scaling

```bash
# Check listener logs
kubectl logs -n arc-runners -l app.kubernetes.io/component=runner-scale-set-listener -f

# Check controller logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-rs-controller -f
```

### Clean Up & Reinstall

```bash
# Uninstall ARC
helm uninstall arc-runner-set -n arc-runners --wait
helm uninstall arc-gha-rs-controller -n arc-systems --wait

# Delete namespaces
kubectl delete namespace arc-runners arc-systems

# Reinstall (follow steps 2-3 above)
```

## References

- [ARC Documentation](https://github.com/actions/actions-runner-controller)
- [K3d Documentation](https://k3d.io)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Part of MaestroAI DevSecOps Infrastructure**  
Generated with [Claude Code](https://claude.com/claude-code)
