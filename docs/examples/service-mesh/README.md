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
