# M00 — Fundamentos de contenedores

[← Página anterior](../../README.md) · [Siguiente página →](M00-01-contenedor-proceso.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

Este bloque es **previo a Kubernetes**. Si no has usado Docker, empieza aquí.
Todo ocurre en el **Codespace**: no instalas Docker en tu portátil.

## Qué aprenderás

- Ver un contenedor como **un proceso** (PID 1) aislado, no como una máquina virtual.
- Distinguir `ENTRYPOINT`, `CMD` y los argumentos que pasas en `docker run`.
- Leer estados (`Created`, `Running`, `Exited`) y limpiar con `docker ps` / `rm`.
- Entrar en un contenedor vivo (`exec`, `logs`) y lanzar comandos dentro.
- Publicar un **puerto** y **ver la web** en la pestaña Ports del Codespace.
- Persistir ficheros con **volúmenes** (bind mount y volumen con nombre).

## Teoría

### El contenedor es un proceso

Docker **no** arranca un Linux completo cada vez. Toma una **imagen** (plantilla de
ficheros + metadatos) y lanza **un proceso** con su propio sistema de ficheros y red.

```text
tú (Codespace)  →  docker run  →  proceso PID 1 dentro del contenedor
```

Cuando ese proceso termina, el contenedor pasa a **Exited**. No “se apaga un PC”:
se acaba el programa.

| Idea que se confunde | Realidad |
|----------------------|----------|
| Contenedor = VM | El contenedor comparte el kernel del Codespace; solo aísla procesos y ficheros |
| `docker run` “enciende un servidor” | Arranca **un** proceso (el PID 1). Si ese proceso muere, el contenedor muere |
| Imagen = contenedor | La **imagen** es la receta; el **contenedor** es una ejecución concreta |

### command, ENTRYPOINT y args

En la imagen hay dos metadatos:

| Campo | Pregunta que responde | Ejemplo |
|-------|----------------------|---------|
| **ENTRYPOINT** | ¿Qué binario se lanza siempre? | `/entrypoint.sh` |
| **CMD** | ¿Con qué argumentos por defecto? | `sleep 30` |

`docker run imagen ARG` **sustituye el CMD**, no el ENTRYPOINT (salvo que uses `--entrypoint`).

```text
ENTRYPOINT ["/entrypoint.sh"] + CMD ["sleep", "30"]
docker run img                →  /entrypoint.sh sleep 30
docker run img sleep 5        →  /entrypoint.sh sleep 5
docker run --entrypoint echo img hola  →  echo hola
```

> [!NOTE]
> `docker run alpine ls /` no “entra en Alpine”. Lanza el proceso `ls` y el contenedor
> termina. Para una shell viva usas `-it` y un proceso que no acabe (`sh`) o `docker exec`.

### Estados y `docker ps`

| Estado | Significado |
|--------|-------------|
| **Created** | Existe, aún no ha arrancado |
| **Running** | El PID 1 sigue vivo |
| **Exited** | El PID 1 ya terminó (código 0 u otro) |
| **Paused** | Congelado (no lo usamos en el curso) |

```text
docker ps          # solo Running
docker ps -a       # también Exited / Created
docker rm NOMBRE   # borra un contenedor parado
docker rm -f NOMBRE
docker container prune   # borra todos los Exited
```

### Interactuar

| Comando | Qué hace |
|---------|----------|
| `docker logs` | Lee lo que el PID 1 escribió en stdout/stderr |
| `docker exec` | Lanza **otro** proceso en un contenedor *Running* |
| `docker run -it` | Arranca el contenedor con terminal interactiva |
| `docker cp` | Copia ficheros Codespace ↔ contenedor |

### Puertos (lo visual)

El proceso dentro escucha en un puerto **interno** (nginx en `:80`).
`-p 8888:80` publica `8888` en el Codespace. La pestaña **Ports** abre esa URL en tu navegador.

```text
Navegador  →  Codespace :8888  →  contenedor :80  →  nginx
```

### Volúmenes

El disco del contenedor **se pierde** al borrarlo. Un volumen (o un directorio del Codespace
montado) sobrevive.

| Tipo | Qué montas |
|------|------------|
| **Bind mount** | Una carpeta del repo (`./site:/usr/share/nginx/html`) |
| **Volumen con nombre** | Disco de Docker (`m00-datos:/data`) |

## Demostración guiada

> Recorrido que hace el formador en vivo. Tono descriptivo, sin imperativos.

1. En la terminal del Codespace, `docker run --rm alpine echo hola` imprime `hola` y no
   deja contenedor: el proceso `echo` acaba y `--rm` limpia.
2. `docker run -d --name m00-sleep alpine sleep 3600` deja un `Running`. `docker top m00-sleep`
   muestra `sleep` como PID 1.
3. `docker run -d --name m00-web -p 8888:80 nginx:1.27-alpine` y la pestaña **Ports → 8888**
   abre la página de bienvenida de nginx: el puerto se ve, no solo se “declara”.
4. Tras `docker stop` / `docker rm`, `docker ps -a` queda limpio. `./scripts/m00-clean.sh`
   hace esa limpieza de un golpe.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M00-01 | [El contenedor es un proceso](M00-01-contenedor-proceso.md) | `run`, `ps`, estados y limpieza |
| M00-02 | [ENTRYPOINT, CMD y args](M00-02-entrypoint-cmd-args.md) | Ver qué proceso se lanza de verdad |
| M00-03 | [Interactuar con contenedores](M00-03-interactuar.md) | `logs`, `exec`, procesos extra |
| M00-04 | [Puertos y la web](M00-04-puertos-web.md) | Publicar 8888 y **ver** el sitio |
| M00-05 | [Volúmenes](M00-05-volumenes.md) | El HTML cambia sin reconstruir |

→ Empieza por **[M00-01 — El contenedor es un proceso](M00-01-contenedor-proceso.md)**.
