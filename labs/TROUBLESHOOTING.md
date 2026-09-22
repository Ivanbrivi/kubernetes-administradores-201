# Solución de problemas — clúster kind en Codespace

## Docker o puertos de M00

```bash
docker info
./scripts/m00-clean.sh
```

- **8888 ocupado:** queda un nginx de M00. El script anterior lo quita.
- **Ports no muestra 8888:** Forward a Port → `8888`, o recarga la ventana del Codespace.
- **`name already in use`:** `docker rm -f m00-web m00-sleep` o `m00-clean.sh`.

## El Codespace no tiene `kind`

El `postCreate` aún no ha terminado. Ejecuta:

```bash
bash scripts/bootstrap-tools.sh
command -v kind kubectl helm docker
```

## Nodos `NotReady`

Calico tarda en arrancar, o el Codespace se queda sin RAM.

```bash
kubectl get nodes
kubectl get pods -A | grep -E 'calico|kube-system'
./scripts/health-check.sh
```

Si sigue igual: **Codespace 16 GB** y `./scripts/cluster-down.sh && ./scripts/cluster-up.sh`.

## Contexto kubectl incorrecto

```bash
kubectl config use-context kind-k8s-ops
```

## `curl` a Ingress no responde en `:8080`

- El mapeo hostPort está en el **primer** control-plane (`ingress-ready=true`).
- Comprueba el controller: `kubectl -n ingress-nginx get pods,ing -A`.
- Usa cabecera Host: `curl -sH 'Host: shop.local' http://127.0.0.1:8080/`.

## NetworkPolicy “ha roto todo”

DNS vive en `kube-system`. Si tu política de egress no permite UDP/TCP 53, `nslookup` falla.
Borra la policy o aplica `infra/manifests/m05/networkpolicy.yaml` (incluye DNS).

## OOM al instalar Prometheus (M07)

El stack de monitorización pide RAM. Opciones:

1. Machine del Codespace: 16 GB.
2. Desinstalar: `helm uninstall kps -n monitoring`.
3. Recrear clúster si el nodo kind quedó inestable.

## Restore de etcd dejó la API muerta

Es un lab destructivo. Recupera el laboratorio con:

```bash
./scripts/cluster-down.sh
./scripts/cluster-up.sh
```

Luego vuelve a aplicar los manifiestos del módulo en el que estabas (`infra/manifests/`).
