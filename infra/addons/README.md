# Addons del clúster operativo (versiones ancladas)

| Fichero | Proyecto | Versión |
|---------|----------|---------|
| `calico.yaml` | projectcalico/calico | v3.29.3 |
| `ingress-nginx.yaml` | kubernetes/ingress-nginx (provider kind) | controller-v1.12.2 |
| `metrics-server.yaml` | kubernetes-sigs/metrics-server | v0.7.2 (+ `--kubelet-insecure-tls`) |
| `local-path-storage.yaml` | rancher/local-path-provisioner | v0.0.31 (StorageClass por defecto) |

Los aplica `scripts/cluster-up.sh`. No los edites durante los labs salvo que el guion lo pida.
