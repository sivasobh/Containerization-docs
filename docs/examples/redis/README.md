Redis examples: Bitnami Helm values and operator CR template

Quick deploy (Bitnami Helm chart)

1. Add the Bitnami repo and update:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

2. Install with the example values:

```bash
helm install redis bitnami/redis -f docs/examples/redis/bitnami-values.yaml --namespace redis-prod --create-namespace
```

Operator deploy (generic)

1. Install your chosen Redis Operator following its docs.
2. Apply the CR template (adjust apiVersion/kind and fields):

```bash
kubectl apply -f docs/examples/redis/redis-operator-cr-template.yaml
```

Manual recovery examples

- Check redis pods: `kubectl get pods -n redis-prod -l app=redis`
- Exec into a pod and run cluster check (cluster mode):
  `kubectl exec -it <pod> -n redis-prod -- redis-cli --cluster check <pod-ip>:6379`

Notes
- The `bitnami-values.yaml` is an example; chart values and keys change between chart versions—always consult chart docs.
- The `redis-operator-cr-template.yaml` is a scaffold. Use the operator's CRD reference for exact fields and supported features (resharding, backup CRs, TLS config).
