# Kubernetes — Deployment Guide

TL;DR
-----
- Use Kubernetes for orchestrating containerized workloads at scale: scheduling, self-healing, service discovery, and rolling updates.

When to use
-----------
- Production microservices, multi-replica services, advanced networking, autoscaling, and multi-node clusters.

Core manifest examples
---------------------

Deployment (minimal)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myregistry.example.com/myorg/myapp:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /live
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
```

Service (ClusterIP)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

ConfigMap and Secret (usage)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  LOG_LEVEL: info

---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
type: Opaque
stringData:
  DATABASE_PASSWORD: s3cr3t
```

Ingress (example, assumes controller present)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

Ingress types and controllers
-----------------------------
- Ingress resource types: the standard Kubernetes `Ingress` (networking.k8s.io/v1) is an abstract API. Behavior depends on the installed Ingress Controller.
- Common controllers: NGINX Ingress Controller, Traefik, AWS ALB Ingress Controller, GCE/GLBC (GKE Ingress), and Istio/Gateway API (advanced).
- Use cases:
  - Simple HTTP routing and TLS termination: NGINX / Traefik.
  - Cloud load-balancer integration: AWS ALB, GKE Ingress.
  - Advanced L7 routing, observability, and mesh features: Istio / Gateway API.
- TLS and annotations: TLS termination is configured via `tls:` in the `Ingress` manifest and controller-specific annotations (e.g., cert-manager annotations, ALB target group settings).

Volumes and persistent storage
------------------------------
Kubernetes supports many volume types. Choose based on durability, access mode, and performance.

- Ephemeral volumes
  - `emptyDir`: fast, node-local ephemeral storage (deleted when pod restarts).
  - `configMap` / `secret` volumes: inject config or secrets as files (not for large binary data).

- Persistent volumes
  - `PersistentVolume` (PV): cluster resource representing storage (NFS, cloud block storage, etc.).
  - `PersistentVolumeClaim` (PVC): a claim by a pod for storage from matching PVs.
  - `StorageClass`: dynamic provisioning policy (e.g., `standard`, `gp3`, `premium-ssd`).

PVC example (use block or file storage provided by the cluster/cloud):
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myapp-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

Mount PVC in a Deployment:
```yaml
      containers:
      - name: myapp
        image: myregistry.example.com/myorg/myapp:latest
        volumeMounts:
        - name: data
          mountPath: /var/lib/myapp/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: myapp-data
```

Access modes and considerations
- `ReadWriteOnce` (RWO): single node read-write (common for block storage).
- `ReadOnlyMany` (ROX) / `ReadWriteMany` (RWX): require networked file systems (NFS, some cloud file stores).
- For stateful workloads (databases), prefer storage with appropriate durability and backup strategy.

Storage best practices
- Use `StorageClass` with appropriate reclaimPolicy (`Delete` or `Retain`).
- Define resource requests for I/O sensitive apps and monitor IO/ throughput.
- Back up PV data using cloud provider snapshots or Velero for Kubernetes-native backups.

ServiceAccounts and RBAC
-----------------------
ServiceAccounts provide an identity for pods to call the Kubernetes API.

Create a `ServiceAccount`:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: default
```

Bind permissions (Role / RoleBinding example):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["configmaps","secrets"]
    verbs: ["get","list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bind-config-reader
  namespace: default
subjects:
  - kind: ServiceAccount
    name: myapp-sa
    namespace: default
roleRef:
  kind: Role
  name: config-reader
  apiGroup: rbac.authorization.k8s.io
```

Security best practices for ServiceAccounts
- Use least privilege: grant only required verbs/resources.
- Disable automatic token mounting when not needed: set `automountServiceAccountToken: false` on the `ServiceAccount` or Pod spec.
- Prefer short-lived credentials or integrate with external identity providers (IRSA, Workload Identity) in cloud environments.
- Avoid using the `default` ServiceAccount for production workloads.


Common kubectl commands
------------------------
- `kubectl apply -f deployment.yaml`
- `kubectl rollout status deployment/myapp`
- `kubectl rollout undo deployment/myapp`
- `kubectl port-forward svc/myapp 8080:80`
- `kubectl logs -f deployment/myapp`

Best practices
--------------
- Set resource requests and limits for predictable scheduling.
- Use readiness and liveness probes to avoid serving traffic from unhealthy pods.
- Keep Secrets out of plain manifests and integrate with secret stores (Vault, AWS Secrets Manager, Azure Key Vault).
- Use NetworkPolicies to limit traffic between pods.
- Use namespaces for isolation and RBAC for least-privilege access.

Scaling and updates
-------------------
- Horizontal Pod Autoscaler example:
  `kubectl autoscale deployment myapp --min=2 --max=10 --cpu-percent=70`
- Use `strategy.rollingUpdate` with `maxSurge` and `maxUnavailable` for controlled rollouts.

Troubleshooting
---------------
- Check events: `kubectl describe pod <pod>`
- Check node status: `kubectl get nodes`
- If pods are Pending, inspect scheduling (insufficient resources, taints).

Further reading
---------------
- Kubernetes docs: https://kubernetes.io/docs/home/
