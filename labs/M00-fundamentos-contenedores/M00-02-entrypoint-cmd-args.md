# M00-02 — ENTRYPOINT, CMD y args

[← Página anterior](M00-01-contenedor-proceso.md) · [Siguiente página →](M00-03-interactuar.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Ver qué proceso se lanza de verdad al hacer `docker run`, y cómo `run … args` cambia el CMD.

### Prerrequisitos

- [M00-01](M00-01-contenedor-proceso.md). Codespace con Docker. Si `docker ps -a` lista un `m00-*`, bórralo: `docker rm -f NOMBRE`.

### En qué consiste

Probar Alpine “a pelo”, construir la imagen `m00-echoer` (tiene ENTRYPOINT) y comparar `docker run` con y sin `--entrypoint`.

### 1 — Sin ENTRYPOINT: todo lo que escribes es el comando

**Acción:**

```bash
docker run --rm --name m00-cmd alpine:3.20 echo hola-alpine
docker run --rm --name m00-cmd alpine:3.20 cat /etc/os-release | head -2
```

**Por qué:** La imagen `alpine` usa `CMD ["/bin/sh"]`. Si pones `echo …` después del nombre de imagen, **sustituyes** ese CMD. `--rm` borra el contenedor al salir.

**Resultado esperado:** `hola-alpine` y las dos primeras líneas de Alpine. No queda contenedor (`docker ps -a --filter name=m00-cmd` vacío).

### 2 — Construir una imagen con ENTRYPOINT

**Acción:**

```bash
docker build -t m00-echoer:lab infra/m00/echoer
docker image inspect m00-echoer:lab --format 'ENTRYPOINT={{json .Config.Entrypoint}} CMD={{json .Config.Cmd}}'
```

**Por qué:** El Dockerfile fija `ENTRYPOINT ["/entrypoint.sh"]` y `CMD ["sleep", "30"]`. Eso queda **dentro** de la imagen.

**Resultado esperado:** `ENTRYPOINT=["/entrypoint.sh"]` y `CMD=["sleep","30"]`.

Abre `infra/m00/echoer/entrypoint.sh`: el script imprime un banner y luego hace `exec` de los argumentos. Así el PID 1 acaba siendo `sleep`, no un wrapper zombie.

### 3 — Arrancar con los defaults

**Acción:**

```bash
docker run -d --name m00-echoer m00-echoer:lab
sleep 1
docker logs m00-echoer
docker top m00-echoer
```

**Por qué:** No pasaste args: se usa el CMD. El entrypoint escribe el banner y ejecuta `sleep 30`.

**Resultado esperado:** en logs, `argumentos recibidos: sleep 30` y `PID 1 soy yo`. `docker top` muestra `sleep 30`.

### 4 — Sustituir solo el CMD (args de `docker run`)

**Acción:**

```bash
docker rm -f m00-echoer
docker run --rm --name m00-echoer m00-echoer:lab echo "me pasaron estos args"
```

**Por qué:** `echo "me pasaron…"` **reemplaza** `sleep 30`. El ENTRYPOINT sigue siendo `/entrypoint.sh`.

**Resultado esperado:** banner + `argumentos recibidos: echo me pasaron estos args` + la línea `me pasaron estos args`. El contenedor termina (echo acaba).

### 5 — Sustituir el ENTRYPOINT

**Acción:**

```bash
docker run --rm --name m00-echoer --entrypoint echo m00-echoer:lab "sin el script"
```

**Por qué:** `--entrypoint` cambia el binario. Ya **no** corre `/entrypoint.sh`.

**Resultado esperado:** solo `sin el script`. **No** aparece `=== entrypoint del contenedor ===`.

## Comprueba tu entendimiento

**Quién es PID 1**

`docker run -d --name m00-echoer m00-echoer:lab` y `docker top m00-echoer`

→ `sleep 30` (tras el `exec` del script). Luego `docker rm -f m00-echoer`.

**CMD vs argumentos**

Sin mirar el Dockerfile: ¿qué lanza `docker run m00-echoer:lab sleep 5`?

→ `/entrypoint.sh sleep 5` (ENTRYPOINT + tus args; el CMD `sleep 30` se ignora).

## Reto

### 1 — Un sleep de 5 segundos y ver el Exited

```bash
docker run --name m00-echoer m00-echoer:lab sleep 5
# espera 5 s
docker ps -a --filter name=m00-echoer
```

<details>
<summary>Ver solución</summary>

Logs con `sleep 5`. Estado `Exited (0)`. `docker rm m00-echoer`.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| No ves el banner | Usaste `--entrypoint` o otra imagen | Quita `--entrypoint`; imagen `m00-echoer:lab` |
| `name already in use` | El `-d` anterior sigue | `docker rm -f m00-echoer` |
| `exec format error` | Falta `#!/bin/sh` | El repo ya lo trae en `entrypoint.sh` |
