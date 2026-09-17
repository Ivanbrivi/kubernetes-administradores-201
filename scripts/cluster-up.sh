#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/infra/kind/cluster.yaml"
CLUSTER_NAME="k8s-ops"
ADDONS="$ROOT/infra/addons"

if ! command -v kind >/dev/null 2>&1; then
  echo "ERROR: kind no instalado. Ejecuta scripts/bootstrap-tools.sh o espera a que termine el Codespace."
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "Creando clúster $CLUSTER_NAME (kind HA)…"
  kind create cluster --name "$CLUSTER_NAME" --config "$CONFIG"
else
  echo "Clúster $CLUSTER_NAME ya existe."
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null
kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

echo "Instalando Calico…"
kubectl apply -f "$ADDONS/calico.yaml"
echo "Esperando nodos Ready (CNI)…"
kubectl wait --for=condition=Ready nodes --all --timeout=240s

echo "Instalando metrics-server, ingress-nginx y local-path…"
kubectl apply -f "$ADDONS/metrics-server.yaml"
kubectl apply -f "$ADDONS/ingress-nginx.yaml"
kubectl apply -f "$ADDONS/local-path-storage.yaml"

echo "Esperando ingress-nginx…"
kubectl -n ingress-nginx wait --for=condition=available deploy/ingress-nginx-controller --timeout=180s || true

echo
echo "Clúster operativo listo. Contexto: kind-${CLUSTER_NAME}"
kubectl get nodes -o wide
kubectl get sc
echo
echo "Siguiente: ./scripts/health-check.sh"
