# M00-05 — Volúmenes

[← Página anterior](M00-04-puertos-web.md) · [Siguiente página →](../M00-imagenes-compose-cicd/README.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Demostrar que un bind mount refleja tus ediciones en el navegador, y que un volumen con nombre **sobrevive** a `docker rm`.

### Prerrequisitos

- [M00-04](M00-04-puertos-web.md). `./scripts/m00-clean.sh`.

### En qué consiste

Montas `infra/m00/web/site` en nginx, cambias el HTML, recargas la web; luego un volumen `m00-datos` con un fichero que reaparece en otro contenedor.

### 1 — Bind mount: el Codespace es el disco de nginx

**Acción:**

```bash
docker run -d --name m00-web -p 8888:80 \
  -v "$PWD/infra/m00/web/site:/usr/share/nginx/html:ro" \
  nginx:1.27-alpine
curl -sS http://127.0.0.1:8888/ | grep Hola
```

Abre **8888** en Ports (tarjeta verde).

**Por qué:** `-v host:contenedor` sustituye esa carpeta. `:ro` = el contenedor no puede pisar tus ficheros.

**Resultado esperado:** la misma web v1 que en M00-04.

### 2 — Editar y recargar (sin rebuild)

**Acción:** abre `infra/m00/web/site/index.html` y cambia el `<h1>` a:

```html
<h1>Cambio en caliente</h1>
```

Guarda el fichero. En el Codespace:

```bash
curl -sS http://127.0.0.1:8888/ | grep -E 'Cambio|Hola'
```

Recarga el navegador.

**Por qué:** nginx lee el fichero en cada petición. No has reconstruido imagen ni recreado el contenedor.

**Resultado esperado:** `Cambio en caliente` en curl y en el navegador.

> [!NOTE]
> Antes de seguir al siguiente módulo, **deshaz** el h1 a `Hola desde el contenedor` (o deja el cambio: es tu fork).

### 3 — Sin volumen: el dato muere con el contenedor

**Acción:**

```bash
docker rm -f m00-web
docker run -d --name m00-tmp alpine:3.20 sleep 3600
docker exec m00-tmp sh -c "echo solo-dentro > /tmp/dato.txt && cat /tmp/dato.txt"
docker rm -f m00-tmp
docker run --rm alpine:3.20 cat /tmp/dato.txt || echo "el fichero ya no existe"
```

**Por qué:** Cada contenedor nuevo parte de la imagen limpia. `/tmp/dato.txt` no estaba en Alpine.

**Resultado esperado:** el segundo `cat` falla; ves `el fichero ya no existe`.

### 4 — Volumen con nombre

**Acción:**

```bash
docker volume create m00-datos
docker run --rm -v m00-datos:/data alpine:3.20 sh -c "echo persistido > /data/nota.txt && cat /data/nota.txt"
docker run --rm -v m00-datos:/data alpine:3.20 cat /data/nota.txt
docker volume ls --filter name=m00-datos
```

**Por qué:** `m00-datos` es un disco de Docker. Los dos `run --rm` son contenedores **distintos**; el volumen es el mismo.

**Resultado esperado:** las dos veces `persistido`. El volumen sigue listado después de `--rm`.

### 5 — Borrar el volumen (cuando acabes)

**Acción:**

```bash
docker volume rm m00-datos
./scripts/m00-clean.sh
```

**Por qué:** Los volúmenes no se van con `docker rm`. Si no los borras, ocupan sitio.

**Resultado esperado:** `m00-datos` desaparece de `docker volume ls`.

## Comprueba tu entendimiento

**Bind vs volumen con nombre**

El HTML del paso 1 vive en `infra/m00/web/site`. ¿Lo ves en el explorador de archivos del Codespace?

→ Sí. Un volumen `m00-datos` **no** aparece como carpeta del repo (vive en Docker).

**`:ro`**

`docker exec m00-web sh -c "echo x > /usr/share/nginx/html/index.html"` (si el contenedor del paso 1 sigue).

→ Error de solo lectura. El HTML se edita **en el repo**, no desde dentro.

## Reto

### 1 — Montar site-v2 (tarjeta naranja)

```bash
docker rm -f m00-web
docker run -d --name m00-web -p 8888:80 \
  -v "$PWD/infra/m00/web/site-v2:/usr/share/nginx/html:ro" \
  nginx:1.27-alpine
```

Recarga 8888. Luego `docker rm -f m00-web`.

<details>
<summary>Ver solución</summary>

Fondo naranja y badge `v2`. Misma URL, otro directorio montado.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| Sigue el HTML viejo | Caché del navegador | `curl` o recarga forzada |
| `no such file` en el bind | No estás en la raíz del repo | `pwd`; usa `"$PWD/infra/m00/web/site:..."` |
| El volumen “vacío” al segundo run | Nombre distinto (`m00-dato` vs `m00-datos`) | Copia el nombre tal cual |
