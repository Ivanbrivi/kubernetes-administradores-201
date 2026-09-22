# M00-08 — Compose de desarrollo

[← Página anterior](M00-07-multistage-tags.md) · [Siguiente página →](M00-09-compose-prod.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Levantar **web + API** con Compose, usando el **build context** y el volumen de `site/` para recargar el HTML.

### Prerrequisitos

- [M00-07](M00-07-multistage-tags.md). Libera 8888/8889: `docker ps` y `docker rm -f` de lo que los use. Si dejaste un compose: `docker compose -f infra/m00/web/compose.yaml down`.

### En qué consiste

Leer `compose.yaml`, `up --build`, probar 8888 y 8889, editar HTML, `down`.

### 1 — Leer el YAML

**Acción:**

```bash
cat infra/m00/web/compose.yaml
```

**Por qué:** `build.context: .` es **relativo al fichero compose** (`infra/m00/web`). Ahí Compose encuentra `Dockerfile.dev` y `site/`.

**Resultado esperado:** servicios `web` y `api`; puertos 8888 y 8889; volumen `./site:/usr/share/nginx/html`.

### 2 — Arrancar el entorno de desarrollo

**Acción:**

```bash
docker compose -f infra/m00/web/compose.yaml up --build -d
docker compose -f infra/m00/web/compose.yaml ps
```

**Por qué:** `--build` construye `m00-web:dev` con ese context. `-d` deja la terminal libre. Compose crea una **red** para que `web` y `api` se vean por nombre.

**Resultado esperado:** dos servicios `running`. Nombres tipo `web-web-1` y `web-api-1`.

### 3 — Ver los dos servicios

**Acción:**

```bash
curl -sS http://127.0.0.1:8888/ | grep Hola
curl -sS http://127.0.0.1:8889/
```

Abre **8888** (tarjeta verde) y **8889** (texto `soy la api del compose`) en Ports.

**Por qué:** Un `compose.yaml` orquesta varios procesos. En Kubernetes serán varios Deployments; la idea es la misma: más de un contenedor, una red.

**Resultado esperado:** HTML v1 + el texto de la API. Dos pestañas, dos puertos.

### 4 — Recarga en caliente (volumen de dev)

**Acción:** cambia el `<h1>` de `infra/m00/web/site/index.html` a `Compose en caliente`, guarda, y:

```bash
curl -sS http://127.0.0.1:8888/ | grep -E 'Compose|Hola'
```

Recarga 8888.

**Por qué:** El servicio `web` monta `./site`. No hace falta `compose build` para un cambio de HTML.

**Resultado esperado:** `Compose en caliente` en curl y en el navegador.

### 5 — La API vista desde la red de Compose

**Acción:**

```bash
docker compose -f infra/m00/web/compose.yaml exec web wget -qO- http://api:8080
```

**Por qué:** Dentro de la red de Compose el hostname es el **nombre del servicio** (`api`), puerto interno 8080. Tú en el Codespace usas 8889.

**Resultado esperado:** `soy la api del compose`.

Deja el entorno up si vas a M00-09; si no: `docker compose -f infra/m00/web/compose.yaml down`.

## Comprueba tu entendimiento

**Context**

Si movieras `compose.yaml` a la raíz del repo sin cambiar `context`, ¿funcionaría `COPY` / el volumen `./site`?

→ No, salvo que ajustes rutas. El `.` es relativo al YAML.

**up vs run**

¿`docker compose up` sustituye a dos `docker run`?

→ Sí, más red, nombre de proyecto y un solo `down`.

## Reto

### 1 — Logs de un servicio

```bash
docker compose -f infra/m00/web/compose.yaml logs api --tail 20
```

<details>
<summary>Ver solución</summary>

http-echo registra peticiones. Tras los `curl` a 8889 deberías ver líneas de acceso.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `port is already allocated` | `m00-web` suelto | `docker rm -f m00-web` y otra vez `up` |
| `wget: not found` | Imagen sin wget | En `nginx:alpine` existe `wget`; no uses `curl` dentro si no está |
| HTML no cambia | Editaste `site-v2` o no guardaste | Edita `infra/m00/web/site/index.html` |
