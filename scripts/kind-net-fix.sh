#!/usr/bin/env bash
# Codespaces (Docker 29): la red Docker "kind" no tiene NAT a Internet.
# Este script:
# 1) Crea esa red solo IPv4 (evita ip6tables).
# 2) Levanta un proxy CONNECT en la gateway de kind (el host SÍ tiene red).
# 3) Configura containerd de cada nodo con HTTPS_PROXY → kubelet puede hacer pull.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROXY_PORT="${KIND_EGRESS_PORT:-3128}"

log() { echo "[kind-net-fix] $*"; }

if ! command -v docker >/dev/null 2>&1; then
  exit 0
fi
if ! docker info >/dev/null 2>&1; then
  exit 0
fi

if [ -w /proc/sys/net/ipv4/ip_forward ]; then
  echo 1 >/proc/sys/net/ipv4/ip_forward 2>/dev/null || true
fi
modprobe ip6_tables 2>/dev/null || true

ensure_kind_network() {
  if docker network inspect kind >/dev/null 2>&1; then
    local n
    n="$(docker network inspect kind -f '{{len .Containers}}' 2>/dev/null || echo 1)"
    if [ "${n}" = "0" ]; then
      log "recreando red kind vacía (IPv4)"
      docker network rm kind >/dev/null 2>&1 || return 0
    else
      return 0
    fi
  fi
  log "creando red docker kind solo IPv4"
  docker network create \
    --driver bridge \
    -o com.docker.network.bridge.enable_ip_masquerade=true \
    kind >/dev/null
}

kind_gateway() {
  docker network inspect kind -f '{{(index .IPAM.Config 0).Gateway}}' 2>/dev/null || echo "172.18.0.1"
}

ensure_egress_proxy() {
  local gw="$1"
  if ss -ltn 2>/dev/null | grep -q "${gw}:${PROXY_PORT}"; then
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    log "python3 no está; el proxy de salida no arranca"
    return 1
  fi
  log "proxy CONNECT en ${gw}:${PROXY_PORT} (imagenes kind → Internet del Codespace)"
  nohup python3 "$ROOT/scripts/kind-egress-proxy.py" "$gw" "$PROXY_PORT" \
    >/tmp/kind-egress-proxy.log 2>&1 &
  sleep 0.5
}

configure_node_containerd_proxy() {
  local node="$1" gw="$2"
  local proxy="http://${gw}:${PROXY_PORT}"
  local nop="localhost,127.0.0.1,10.96.0.0/16,10.244.0.0/16,172.16.0.0/12,.svc,.cluster.local"
  docker exec "$node" bash -c "
set -e
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/http-proxy.conf <<EOF
[Service]
Environment=HTTP_PROXY=${proxy}
Environment=HTTPS_PROXY=${proxy}
Environment=NO_PROXY=${nop}
EOF
if tr '\\0' '\\n' < /proc/\$(pgrep -x containerd | head -1)/environ 2>/dev/null | grep -qx \"HTTPS_PROXY=${proxy}\"; then
  exit 0
fi
systemctl daemon-reload
systemctl restart containerd
" 2>/dev/null && log "containerd usa proxy en ${node}" || true
}

ensure_kind_network || true
GW="$(kind_gateway)"
ensure_egress_proxy "$GW" || true

export KIND_HTTP_PROXY="http://${GW}:${PROXY_PORT}"
export KIND_HTTPS_PROXY="http://${GW}:${PROXY_PORT}"
export KIND_NO_PROXY="localhost,127.0.0.1,10.96.0.0/16,10.244.0.0/16,172.16.0.0/12,.svc,.cluster.local"

for node in $(docker ps --filter "label=io.x-k8s.kind.cluster" --format '{{.Names}}' 2>/dev/null); do
  configure_node_containerd_proxy "$node" "$GW"
done

exit 0
