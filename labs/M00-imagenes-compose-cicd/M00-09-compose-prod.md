# M00-09 — Compose de producción

[← Página anterior](M00-08-compose-dev.md) · [Siguiente página →](M00-10-actions-ghcr.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Levantar el mismo par web+API **sin** bind mount, con la etapa `runtime` del Dockerfile multistage.

### Prerrequisitos

- [M00-08](M00-08-compose-dev.md). Baja el compose de dev:

```bash
docker compose -f infra/m00/web/compose.yaml down
```

### En qué consiste

Leer `compose.prod.yaml`, `up --build`, comprobar que editar `site/index.html` **ya no** cambia la web.

### 1 — Diferencias del YAML

**Acción:**

```bash
cat infra/m00/web/compose.prod.yaml
```

**Por qué:** `dockerfile: Dockerfile` + `target: runtime` = imagen de prod. `volumes: []` = el HTML va **cocido** en la imagen.

**Resultado esperado:** no hay bind `./site:…`.

### 2 — Arrancar prod

**Acción:**

```bash
docker compose -f infra/m00/web/compose.prod.yaml up --build -d
docker compose -f infra/m00/web/compose.prod.yaml ps
curl -sS http://127.0.0.1:8888/build-info.txt
curl -sS http://127.0.0.1:8889/
```

Abre 8888: tarjeta verde **original del repo** (la que se COPYó al construir), más `build-info.txt`.

**Por qué:** Es el artefacto que mandarías a un registry. El Codespace deja de ser “el disco de nginx”.

**Resultado esperado:** `construido en el build` y `api-prod` en 8889.

### 3 — Demostrar que el volumen ya no manda

**Acción:** edita `infra/m00/web/site/index.html` el h1 a `Esto no debería verse en prod`, guarda:

```bash
curl -sS http://127.0.0.1:8888/ | grep -E 'debería|Hola|Compose'
```

**Por qué:** El contenedor no monta esa carpeta. El HTML es el de la **capa** de la imagen.

**Resultado esperado:** **no** aparece `Esto no debería verse en prod`. Sigue el HTML de cuando hiciste el build.

### 4 — Bajar el stack

**Acción:**

```bash
docker compose -f infra/m00/web/compose.prod.yaml down
docker ps --filter name=web
```

**Por qué:** `down` para y elimina los contenedores del proyecto. Las imágenes `m00-web:prod` se quedan.

**Resultado esperado:** ningún contenedor del compose. 8888 deja de responder.

> [!TIP]
> Restaura el h1 de `site/index.html` si lo cambiaste, para no liar a M00-10 ni a otros labs.

## Comprueba tu entendimiento

**Dev vs prod**

Completa: en dev el HTML vive en ______; en prod vive en ______.

→ Dev: carpeta del repo (volumen). Prod: capas de la imagen.

**target**

¿Qué pasaría si en prod no pones `target: runtime`?

→ Buildx/Compose usa la **última** etapa del Dockerfile (aquí también es `runtime`). El `target` lo deja explícito.

## Reto

### 1 — Imagen que quedó

`docker images 'm00-web'`

<details>
<summary>Ver solución</summary>

Deberías ver `dev`, `prod`, `v1`, `v2` según lo que hayas construido. Prod es la que usa el compose de este lab.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| Sigue el compose de dev | No hiciste `down` del otro fichero | `compose.yaml down` y luego `compose.prod.yaml up` |
| No hay `build-info.txt` | Estás en dev o en `:v1` de Dockerfile.dev | Este lab usa `Dockerfile` + `target: runtime` |
| Puerto ocupado | Contenedor suelto `m00-web` | `docker rm -f m00-web` |
