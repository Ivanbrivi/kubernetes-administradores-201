# M00-07 — Multistage y tags

[← Página anterior](M00-06-dockerfile.md) · [Siguiente página →](M00-08-compose-dev.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Construir la etapa `runtime` (multistage), etiquetar `v1`/`v2` y **ver** el cambio de color en el mismo puerto 8888.

### Prerrequisitos

- [M00-06](M00-06-dockerfile.md). `m00-web` puede seguir en 8888; lo recreamos.

### En qué consiste

Leer `Dockerfile` de dos etapas, build `--target runtime`, un segundo tag con `site-v2`, recargar el navegador.

### 1 — Leer el multistage

**Acción:**

```bash
cat infra/m00/web/Dockerfile
```

**Por qué:** `AS stamp` genera `build-info.txt`. `AS runtime` copia el resultado a nginx. La imagen que corres es **solo** `runtime`.

**Resultado esperado:** dos `FROM`. El segundo usa `COPY --from=stamp`.

### 2 — Build de la etapa final

**Acción:**

```bash
docker build -t m00-web:prod --target runtime -f infra/m00/web/Dockerfile infra/m00/web
docker images m00-web
```

**Por qué:** `--target runtime` deja fuera herramientas de la etapa `stamp` (aquí Alpine solo se usó para el `RUN echo`).

**Resultado esperado:** tag `prod` (y el `v1` de antes si no lo borraste).

### 3 — Comprobar el artefacto del build

**Acción:**

```bash
docker rm -f m00-web
docker run -d --name m00-web -p 8888:80 m00-web:prod
curl -sS http://127.0.0.1:8888/build-info.txt
curl -sS http://127.0.0.1:8888/ | grep Hola
```

**Por qué:** `build-info.txt` **no** está en `site/` del repo: lo creó el `RUN` de la etapa stamp.

**Resultado esperado:** `construido en el build` y la tarjeta verde.

### 4 — Tag v2 (otro HTML, misma receta)

**Acción:** copia v2 al context, construye otro tag (Dockerfile.dev es más directo para este contraste visual):

```bash
cp infra/m00/web/site-v2/index.html /tmp/m00-index-v2.html
# build v2 usando un context temporal
rm -rf /tmp/m00-ctx-v2
mkdir -p /tmp/m00-ctx-v2/site
cp /tmp/m00-index-v2.html /tmp/m00-ctx-v2/site/index.html
cp infra/m00/web/Dockerfile.dev /tmp/m00-ctx-v2/Dockerfile
docker build -t m00-web:v2 /tmp/m00-ctx-v2
docker images m00-web
```

**Por qué:** `:v1` y `:v2` conviven. El navegador no “sabe” de tags: sabe del **contenedor** que está en 8888.

**Resultado esperado:** `m00-web:v1` (o `prod`) y `m00-web:v2` en la lista.

### 5 — Cambiar de tag y mirar el navegador

**Acción:**

```bash
docker rm -f m00-web
docker run -d --name m00-web -p 8888:80 m00-web:v2
curl -sS http://127.0.0.1:8888/ | grep -E 'v2|Nueva'
```

Recarga **8888**. Luego vuelve a v1 si quieres:

```bash
docker rm -f m00-web
docker run -d --name m00-web -p 8888:80 m00-web:v1
```

**Por qué:** Misma URL, otra imagen. En Kubernetes harás lo mismo con un Deployment (rolling update).

**Resultado esperado:** tarjeta **naranja** con `v2`. Al volver a `:v1`, otra vez verde.

## Comprueba tu entendimiento

**Qué viaja a prod**

`docker history m00-web:prod`

→ No deberías ver un `apk add` pesado: solo nginx + COPY desde stamp.

**latest**

`docker tag m00-web:v2 m00-web:latest` y `docker images m00-web`

→ `latest` es **otro nombre** para el mismo ID que `v2`, no una versión mágica.

## Reto

### 1 — Inspeccionar build-info en prod

`docker exec m00-web cat /usr/share/nginx/html/build-info.txt` (si corre `:prod`).

<details>
<summary>Ver solución</summary>

`construido en el build`. En `:v2` (Dockerfile.dev) ese fichero **no** existe: no hubo etapa stamp.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| Sigue verde tras v2 | No recreaste el contenedor | `docker rm -f m00-web` y `run … m00-web:v2` |
| `failed to build` target | Typo `runtime` | El Dockerfile usa `AS runtime` |
| Caché del navegador | Ctrl+Shift+R / `curl` | Confía en `curl` si la pestaña miente |
