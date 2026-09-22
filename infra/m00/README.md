# Material M00 — fundamentos de contenedores

App visual y ficheros de build para los laboratorios previos a Kubernetes.

| Ruta | Uso |
|------|-----|
| `web/site/` | HTML verde (v1) que se ve en el puerto **8888** |
| `web/site-v2/` | HTML naranja (v2) para demostrar un cambio de tag |
| `web/Dockerfile.dev` | Una sola etapa: copia `site/` a nginx |
| `web/Dockerfile` | Multistage (`stamp` → `runtime`) |
| `web/compose.yaml` | Dev: build context + volumen del HTML |
| `web/compose.prod.yaml` | Prod: imagen runtime, sin bind mount |
| `echoer/` | Imagen para ver ENTRYPOINT / CMD / args |

Desde la raíz del repo:

```bash
docker compose -f infra/m00/web/compose.yaml up --build
```

Luego abre el puerto **8888** en la pestaña Ports del Codespace.
