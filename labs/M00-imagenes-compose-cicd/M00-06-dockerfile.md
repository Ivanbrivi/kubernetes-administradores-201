# M00-06 — Tu Dockerfile

[← Página anterior](README.md) · [Siguiente página →](M00-07-multistage-tags.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Construir `m00-web:v1` a partir de `Dockerfile.dev` y ver la tarjeta verde **sin** bind mount.

### Prerrequisitos

- M00-01 a M00-05. `./scripts/m00-clean.sh`. Estás en la **raíz** del repo.

### En qué consiste

Leer el Dockerfile, entender el context, `docker build`, `docker run -p 8888:80`, curl y Ports.

### 1 — Leer la receta

**Acción:**

```bash
cat infra/m00/web/Dockerfile.dev
ls infra/m00/web/site
```

**Por qué:** `COPY site/` es relativo al **context** (la carpeta que pasas a `build`), no a donde estés tú.

**Resultado esperado:** `FROM nginx:1.27-alpine` y `COPY site/ …`. En `site/` está `index.html`.

### 2 — Build con tag

**Acción:**

```bash
docker build -t m00-web:v1 -f infra/m00/web/Dockerfile.dev infra/m00/web
docker images m00-web
```

**Por qué:** `-f` es el Dockerfile. El último argumento (`infra/m00/web`) es el **context**: ahí vive `site/`. `-t m00-web:v1` pone nombre y etiqueta.

**Resultado esperado:** `m00-web` con tag `v1` en `docker images`.

> [!TIP]
> Si pones mal el context (`docker build … .` desde la raíz sin ajustar COPY), el build falla con `site/: not found`.

### 3 — Arrancar la imagen (el HTML va dentro)

**Acción:**

```bash
docker run -d --name m00-web -p 8888:80 m00-web:v1
curl -sS http://127.0.0.1:8888/ | grep Hola
```

Abre **Ports → 8888**.

**Por qué:** No hay `-v`. Si ves la tarjeta verde, el `COPY` del build funcionó.

**Resultado esperado:** tarjeta verde `v1 · puerto 8888` en el navegador. `HTTP` implícito 200.

### 4 — Inspeccionar la imagen

**Acción:**

```bash
docker image inspect m00-web:v1 --format 'Cmd={{json .Config.Cmd}} Entrypoint={{json .Config.Entrypoint}}'
docker history m00-web:v1 --no-trunc | head
```

**Por qué:** nginx trae su ENTRYPOINT/CMD. Tus capas son el `COPY` (y el FROM).

**Resultado esperado:** history con una capa que menciona `site` o `COPY`.

## Comprueba tu entendimiento

**Dónde está el HTML**

`docker exec m00-web ls /usr/share/nginx/html`

→ `index.html` (copiado en el build). No es un mount del repo.

**Cambiar el HTML del repo ¿cambia la web?**

Edita `infra/m00/web/site/index.html`, recarga 8888 **sin** rebuild.

→ Sigue el texto antiguo. Receta vieja. Para ver el cambio: `docker build` + recrear contenedor (siguiente lab, o volumen en M00-08).

## Reto

### 1 — Listar tags

`docker images m00-web --format '{{.Repository}}:{{.Tag}} {{.ID}}'`

<details>
<summary>Ver solución</summary>

Al menos `m00-web:v1`. El IMAGE ID identifica las capas; el tag es la etiqueta.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `site/: not found` | Context incorrecto | Último argumento: `infra/m00/web` |
| Puerto ocupado | Contenedor anterior | `./scripts/m00-clean.sh` |
| Welcome to nginx | Construiste otra carpeta / no usaste `-f Dockerfile.dev` | Revisa el comando del paso 2 |
