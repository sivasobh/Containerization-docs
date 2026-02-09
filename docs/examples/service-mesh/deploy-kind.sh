#!/usr/bin/env bash
set -euo pipefail

echo "Installing Prometheus + Grafana (kube-prometheus-stack) via Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -f docs/examples/service-mesh/prometheus-helm-values.yaml --namespace monitoring --create-namespace || true

echo "Applying service mesh example resources via kustomize..."
kubectl apply -k docs/examples/service-mesh

echo "Wait a few moments for pods to come up. To port-forward Grafana:
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
Then open http://localhost:3000 and login with admin and password from values file."

echo "To generate traffic inside the cluster run:
kubectl create job --from=cronjob/backend-traffic-generator -n mesh-demo backend-traffic-once || true
or apply the Job manifest:
kubectl apply -f docs/examples/service-mesh/traffic-job.yaml -n mesh-demo
"

echo "Done."
