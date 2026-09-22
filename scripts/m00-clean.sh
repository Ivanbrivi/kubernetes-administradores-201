#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Parando compose M00 (si existe)…"
docker compose -f "$ROOT/infra/m00/web/compose.yaml" down --remove-orphans 2>/dev/null || true
docker compose -f "$ROOT/infra/m00/web/compose.prod.yaml" down --remove-orphans 2>/dev/null || true

echo "Borrando contenedores de práctica M00…"
docker ps -a --filter "name=m00-" --format '{{.Names}}' | while read -r name; do
  docker rm -f "$name" >/dev/null && echo "  eliminado $name"
done

echo "OK: entorno M00 limpio. Las imágenes (m00-web, m00-echoer) se quedan por si las reutilizas."
echo "Para borrarlas: docker image rm m00-web:dev m00-web:prod m00-web:v1 m00-web:v2 m00-echoer:lab 2>/dev/null || true"
