# M00-04 — Puertos y la web

[← Página anterior](M00-03-interactuar.md) · [Siguiente página →](M00-05-volumenes.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Publicar el puerto 80 de nginx en el **8888** del Codespace y **ver la página** en el navegador.

### Prerrequisitos

- [M00-03](M00-03-interactuar.md). `./scripts/m00-clean.sh`. Nada más debe usar el 8888.

### En qué consiste

Nginx de fábrica, `curl` local, pestaña **Ports**, y luego la web **v1** del curso (tarjeta verde).

### 1 — Nginx con puerto publicado

**Acción:**

```bash
docker run -d --name m00-web -p 8888:80 nginx:1.27-alpine
docker ps --filter name=m00-web --format '{{.Names}} {{.Ports}} {{.Status}}'
```

**Por qué:** `-p 8888:80` significa: Codespace **8888** → contenedor **80**. Sin `-p`, nginx escucha solo *dentro* y tu navegador no llega.

**Resultado esperado:** `0.0.0.0:8888->80/tcp` y estado `Up`.

### 2 — Comprobar con curl (en el Codespace)

**Acción:**

```bash
curl -sS -o /tmp/m00-nginx.html -w "HTTP %{http_code}\n" http://127.0.0.1:8888/
head -n 5 /tmp/m00-nginx.html
```

**Por qué:** `127.0.0.1` es el Codespace, no tu portátil. Si esto funciona, el mapeo está bien aunque el navegador aún no se haya abierto.

**Resultado esperado:** `HTTP 200` y HTML de “Welcome to nginx”.

### 3 — Verlo en el navegador (lo visual)

**Acción:** en VS Code / Codespace, pestaña **Ports** (o el icono de puertos). Busca **8888** / **M00 Web**. Abre la URL (globo o *Open in Browser*).

**Por qué:** GitHub reenvía el puerto del Codespace a una URL `*.app.github.dev`. Eso es lo que ve tu clase: no “confíes en el curl”, **mira la página**.

**Resultado esperado:** la página de bienvenida de nginx en una pestaña nueva.

> [!TIP]
> Si 8888 no aparece, **Forward a Port** → `8888`. El `devcontainer` ya lo declara; a veces tarda unos segundos.

### 4 — Sustituir nginx por la web del curso (v1)

**Acción:**

```bash
docker rm -f m00-web
docker run -d --name m00-web -p 8888:80 \
  -v "$PWD/infra/m00/web/site:/usr/share/nginx/html:ro" \
  nginx:1.27-alpine
curl -sS http://127.0.0.1:8888/ | grep -E 'Hola|badge'
```

**Por qué:** El bind mount pone *nuestro* HTML en la carpeta que nginx sirve. Recarga la pestaña del navegador (sin cambiar de URL).

**Resultado esperado:** `curl` contiene `Hola desde el contenedor`. En el navegador, **tarjeta verde** y badge `v1 · puerto 8888`.

### 5 — Qué pasa si no publicas el puerto

**Acción:**

```bash
docker rm -f m00-web
docker run -d --name m00-interno nginx:1.27-alpine
curl -sS --max-time 3 http://127.0.0.1:8888/ || echo "no hay nadie en 8888"
docker rm -f m00-interno
```

**Por qué:** El contenedor está Running y nginx escucha en 80 **dentro**. Sin `-p`, el Codespace 8888 está vacío.

**Resultado esperado:** `curl` falla o timeout; el mensaje `no hay nadie en 8888`.

## Comprueba tu entendimiento

**Orden de `-p`**

`-p 8888:80` ¿quién es el 80?

→ El puerto **dentro** del contenedor (nginx). El 8888 es el del Codespace.

**Misma URL, otro contenido**

Tras el paso 4, recarga el navegador. No cambies de puerto.

→ Debe verse la tarjeta verde, no el “Welcome to nginx”.

## Reto

### 1 — Publicar en 8889 la API de eco

```bash
docker run -d --name m00-api -p 8889:8080 hashicorp/http-echo:1.0.0 \
  -text="hola-api" -listen=:8080
curl -sS http://127.0.0.1:8889/
```

Abre **8889** en Ports. Luego `docker rm -f m00-api`.

<details>
<summary>Ver solución</summary>

El cuerpo es `hola-api`. El mapeo es 8889 (Codespace) → 8080 (proceso http-echo).

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `port is already allocated` | Otro `m00-web` o kind | `./scripts/m00-clean.sh`; no arranques el clúster kind aún |
| curl Connection refused | Olvidaste `-p` o el contenedor no está Up | `docker ps`; repite el `run -p 8888:80` |
| Navegador 404 en github.dev | Abriste otro puerto | Ports → **8888** |
| Sigue el nginx de fábrica | Caché del navegador o no recargaste | Recarga forzada; `curl` para confirmar |
