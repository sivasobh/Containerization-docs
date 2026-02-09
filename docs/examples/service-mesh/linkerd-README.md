Linkerd example: deploy the same test app into a Linkerd-injected namespace

Prerequisites
- Linkerd control plane installed. See https://linkerd.io/getting-started/ for install instructions.

Steps

1. Create namespace with Linkerd injection enabled:

```bash
kubectl apply -f docs/examples/service-mesh/linkerd-namespace.yaml
```

2. Deploy the sample backend into `linkerd-demo` (you can reuse `simple-backend.yaml`):

```bash
# Option A: let Linkerd auto-inject by namespace label
kubectl apply -f docs/examples/service-mesh/simple-backend.yaml -n linkerd-demo

# Option B: manually inject and apply
linkerd inject docs/examples/service-mesh/simple-backend.yaml | kubectl apply -n linkerd-demo -f -
```

3. Verify proxies are injected:

```bash
kubectl get pods -n linkerd-demo -o wide
kubectl -n linkerd-demo get pods -l app=backend -o jsonpath='{.items[*].spec.containers[*].name}'
# should show a `linkerd-proxy` container in pod spec
```

4. Test connectivity (from inside cluster):

```bash
kubectl exec -n linkerd-demo -it curl-client -- /bin/sh -c "curl http://backend.linkerd-demo.svc.cluster.local:80/"
```

Notes
- Linkerd does not use Istio CRDs; routing changes are commonly done via SMI TrafficSplit or service-level changes.
- If you want a traffic-split example, I can add an SMI `TrafficSplit` resource next.
