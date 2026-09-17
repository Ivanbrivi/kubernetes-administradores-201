#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="k8s-ops"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
  echo "Clúster $CLUSTER_NAME eliminado."
else
  echo "No existe el clúster $CLUSTER_NAME."
fi
