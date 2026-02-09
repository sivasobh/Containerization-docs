# Redis Cluster on Kubernetes — Notes & SOP

This note covers deployment patterns, HA considerations, and operational runbooks for Redis (including Redis Cluster and Sentinel models) running on Kubernetes.

## Modes of running Redis
- **Standalone (Single primary):** simplest, not HA; use only for caches where loss is acceptable.
- **Sentinel + Masters/Replicas:** provides automatic failover for master/replica topologies; commonly used for HA without sharding.
- **Redis Cluster:** native sharding with cluster slots and node-to-node replication; supports scaling and data partitioning.

## Deployment Options on Kubernetes
- **Helm charts (Bitnami/Redis official):** quick start for dev/test; can be configured for cluster mode or sentinel mode.
- **Operators (recommended for production):** e.g., Redis Operator by Spot/OTC, Redis Enterprise Operator, or community operators — manage CRs, backups, failover.
- **StatefulSet + init scripts:** DIY approach for small clusters; requires custom controllers for safe resharding and failover.

## Storage & Persistence
- Persist data using PersistentVolumeClaims with appropriate storage class (IOPS and latency tuned). For Redis AOF/RDB persistence, ensure PVs are fast and reliable.
- Consider using AOF for durability with fsync tuned to balance performance vs durability.

## High Availability Patterns
- **Sentinel model:** maintain >=3 Sentinels and >=3 nodes for robust quorum; configure PodAntiAffinity to spread across nodes/AZs.
- **Cluster mode:** run at least 6 nodes (3 masters + 3 replicas) to ensure resiliency during failures and support resharding.
- **Anti-affinity & scheduling:** use `podAntiAffinity` and `topologySpreadConstraints` to avoid co-locating shard replicas on same failure domain.
- **PodDisruptionBudget:** set PDBs to avoid draining multiple masters/replicas at once.

## Networking & Security
- Use headless `Service` for cluster node discovery and additional ClusterIP Services for client access.
- Secure Redis traffic: enable TLS (Redis 6+ supports TLS natively) or use sidecar/proxy (stunnel) when native TLS is unavailable.
- Restrict access using `NetworkPolicy` so only known application pods or namespaces can connect to Redis.

## Backups & Persistence Strategy
- Regularly create RDB snapshots and optionally enable AOF with WAL archiving to object storage (S3/GCS/Azure Blob).
- Test restores frequently; document recovery steps for both single-node and cluster restores.

## Scaling & Resharding
- For Redis Cluster, add new master nodes and trigger resharding to redistribute slots. Prefer operator-managed resharding when available.
- For Sentinel topologies, scale read replicas to serve read-heavy workloads; promote a replica only when necessary.

## Monitoring & Alerting
- Export metrics with `redis_exporter` and collect with Prometheus. Monitor: used_memory, connected_clients, ops/sec, keyspace_hits/misses, replication_offset/lag, AOF rewrite/compaction metrics.
- Alerts: node down, replication lag, high memory usage, eviction events, AOF rewrite failures.

## Runbooks (playbooks)

Incident: Master failure (Sentinel)
1. Check sentinel status: connect to sentinel pod and run `sentinel masters` / `sentinel replicas <master-name>`.
2. Confirm automatic failover occurred; if not, promote the best replica manually using sentinel commands or operator CRs.
3. Recreate or repair failed node and rejoin it as a replica.

Incident: Node down (Cluster mode)
1. Verify cluster state: `redis-cli --cluster check <node:port>` or operator status.
2. If a master is lost, ensure a replica is promoted; if automatic promotion fails, use operator/manual `CLUSTER FAILOVER` where applicable.
3. After recovery, run `redis-cli --cluster fix` if slot gaps or inconsistencies appear (with caution and backups).

Incident: Memory pressure / eviction
1. Identify top keys and clients; use `CLIENT LIST` and `INFO memory`.
2. Consider scaling out (add masters + reshard) or increase memory limits for pods where safe.

Backup Restore
1. For single-node restore: stop writes, replace data directory with snapshot, start node.
2. For cluster restore: orchestrate restores carefully — restore replicas first, then promote and rejoin to avoid split-brain; consider rebuilding cluster in staging first.

## Operator & Helm Example References
- Bitnami Redis Helm chart (cluster mode): https://artifacthub.io/packages/helm/bitnami/redis
- Redis Operator (example): https://github.com/spotahome/redis-operator
- Redis Enterprise Operator (for commercial Redis with HA features): https://docs.redis.com/latest/interactive/redis-enterprise-k8s/

## Quick Kubernetes commands
- View pods: `kubectl get pods -n <ns> -l app=redis` 
- Describe a pod: `kubectl describe pod <pod> -n <ns>`
- Exec to a Redis pod: `kubectl exec -it <pod> -n <ns> -- redis-cli -p <port>`

## Checklist before promoting to production
- Choose operator or tested Helm chart.
- Run staging with same data shape (keys, sizes) as prod.
- Topology: masters and replicas across AZs/nodes.
- Storage: low-latency PVs; backups to off-cluster storage.
- Monitoring and alerts configured.
- Runbooks tested with simulated failures.

## Further reading
- Redis official: https://redis.io/docs/
- Redis Cluster specification: https://redis.io/docs/manual/scaling/
- Bitnami Redis Helm chart docs
- Redis Operator projects and their READMEs

---
I can add an operator CR example (Bitnami values.yaml, or a Redis Cluster CR for a specific operator) and a tested playbook next. Which operator/chart would you prefer me to produce manifests for?
