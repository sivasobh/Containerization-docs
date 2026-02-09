Service mesh example (Istio) with a simple backend and canary routing

Prerequisites
- An Istio control plane and ingress gateway installed and running.

Quick deploy

```bash
# Create namespace with automatic sidecar injection
kubectl apply -f docs/examples/service-mesh/namespace-injection.yaml

# Deploy backend v1/v2 and test client
kubectl apply -f docs/examples/service-mesh/simple-backend.yaml

# Apply Istio routing objects (DestinationRule, Gateway, VirtualService)
kubectl apply -f docs/examples/service-mesh/istio-routing.yaml
```

Testing the canary

1. Port-forward the ingress gateway (adjust namespace if your ingress is in `istio-system`):

```bash
kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80
```

2. Send requests to the backend path and observe responses (the text shows which backend served):

```bash
curl -s http://localhost:8080/backend | head -n 1
```

Because the VirtualService routes /backend to backend subset `v1` (90%) and `v2` (10%), repeated requests should predominantly return `backend-v1` but occasionally `backend-v2`.

Testing from inside cluster

```bash
# Exec into the curl-client pod
kubectl exec -n mesh-demo -it curl-client -- /bin/sh
# from inside the pod run
curl http://backend.mesh-demo.svc.cluster.local:80/
```

Notes & next steps
- Replace Gateway selector if your ingress gateway uses a different label.
- For Linkerd examples or non-Istio meshes, the concepts are similar but CRDs differ.
- I can add automatic traffic shaping, fault-injection, and telemetry examples next.
 
Prometheus & Grafana quickstart

1. Install kube-prometheus-stack (Prometheus Operator + Grafana) with example values:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -f docs/examples/service-mesh/prometheus-helm-values.yaml --namespace monitoring --create-namespace
```

2. Optionally import the example dashboard into Grafana (open Grafana UI -> Manage -> Import, upload `docs/examples/service-mesh/grafana-backend-dashboard.json`).

Linkerd SMI TrafficSplit (canary)

1. Create per-version services and TrafficSplit in the `linkerd-demo` namespace:

```bash
kubectl apply -f docs/examples/service-mesh/linkerd-traffic-split.yaml
```

2. Ensure the `backend` Service exists and routes to the `backend-v1/backend-v2` services created above; test using the client pod.

Deploy & Test (full demo)

This repo includes a kustomize overlay and helper script to deploy the demo and monitoring stack to a local cluster (e.g., kind).

1. Install Prometheus + Grafana and apply the demo resources (uses Helm + kubectl):

```bash
bash docs/examples/service-mesh/deploy-kind.sh
```

2. (Alternative manual steps)

```bash
# Install kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -f docs/examples/service-mesh/prometheus-helm-values.yaml --namespace monitoring --create-namespace

# Apply the kustomize overlay (all demo manifests)
kubectl apply -k docs/examples/service-mesh
```

3. Confirm demo resources are running:

```bash
kubectl get ns mesh-demo monitoring linkerd-demo -o wide
kubectl get pods -n mesh-demo
kubectl get pods -n monitoring
```

Grafana provisioning & automatic dashboard

- The example includes a `ConfigMap` (`grafana-backend-dashboard`) labeled so the Grafana sidecar (kube-prometheus-stack) can automatically pick up the dashboard. If you installed Grafana separately, import `docs/examples/service-mesh/grafana-backend-dashboard.json` manually.
- Datasource provisioning example is in `docs/examples/service-mesh/grafana/provisioning/datasources/datasource.yaml` (points to Prometheus Operator service).

Traffic generation (canary testing)

1. Run the Job inside the cluster to generate traffic to `/backend`:

```bash
kubectl apply -f docs/examples/service-mesh/traffic-job.yaml -n mesh-demo
```

2. Check Job logs or pod logs to validate responses and observe routing percentages.

Kustomize overlay

- Use `kubectl apply -k docs/examples/service-mesh` to apply all example resources in the correct order.

Cleanup

```bash
kubectl delete -k docs/examples/service-mesh
helm uninstall monitoring -n monitoring || true
kubectl delete ns mesh-demo linkerd-demo monitoring || true
```

Notes
- The demo uses lightweight example containers; for production replace with instrumented services exposing `/metrics`.
- If your Istio ingress gateway is in a non-standard namespace or uses a different service name, update `istio-routing.yaml` and port-forward commands accordingly.

