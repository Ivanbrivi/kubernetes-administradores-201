#!/bin/sh
echo "=== entrypoint del contenedor ==="
echo "argumentos recibidos: $*"
echo "PID 1 soy yo: $$"
exec "$@"
