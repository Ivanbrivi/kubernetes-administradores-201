# M00-03 — Interactuar con contenedores

[← Página anterior](M00-02-entrypoint-cmd-args.md) · [Siguiente página →](M00-04-puertos-web.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Leer logs, ejecutar comandos en un contenedor **vivo** y comprobar que `exec` no es el PID 1.

### Prerrequisitos

- [M00-02](M00-02-entrypoint-cmd-args.md). Si un nombre `m00-*` está ocupado: `docker rm -f NOMBRE`.

### En qué consiste

Dejas un Alpine durmiendo, miras logs, lanzas `exec` (hostname, escritura de un fichero) y copias ese fichero al Codespace.

### 1 — Contenedor vivo para practicar

**Acción:**

```bash
docker run -d --name m00-vivo alpine:3.20 sleep 3600
docker ps --filter name=m00-vivo
```

**Por qué:** `exec` solo funciona si el contenedor está **Running**. Un Exited no acepta procesos nuevos.

**Resultado esperado:** estado `Up`.

### 2 — Logs del PID 1

**Acción:**

```bash
docker logs m00-vivo
docker run --rm alpine:3.20 echo "esto sí genera log"
```

**Por qué:** `sleep` no escribe nada: `logs` de `m00-vivo` está vacío y **no es un error**. El segundo comando demuestra que `logs` = stdout del PID 1.

**Resultado esperado:** primera llamada sin texto (o casi); la segunda imprime `esto sí genera log`.

### 3 — Un proceso extra: `docker exec`

**Acción:**

```bash
docker exec m00-vivo hostname
docker exec m00-vivo ps aux
docker exec m00-vivo sh -c "echo hola-desde-exec > /tmp/nota.txt && cat /tmp/nota.txt"
```

**Por qué:** `exec` entra en el **mismo** aislamiento (ficheros, hostname) pero lanza **otro** proceso. El `sleep` sigue siendo PID 1.

**Resultado esperado:** un hostname tipo `a1b2c3d4e5f6`; en `ps` ves `sleep 3600` **y** el `ps`/`sh` del exec; el fichero contiene `hola-desde-exec`.

> [!WARNING]
> `docker exec -it m00-vivo sh` abre una shell. Para salir: `exit`. Si cierras la pestaña a lo bruto, el contenedor **sigue** Running (`sleep` no era esa shell).

### 4 — Copiar ficheros al Codespace

**Acción:**

```bash
docker cp m00-vivo:/tmp/nota.txt /tmp/nota-del-contenedor.txt
cat /tmp/nota-del-contenedor.txt
```

**Por qué:** El Codespace y el contenedor no comparten el disco salvo volúmenes o `docker cp`.

**Resultado esperado:** `hola-desde-exec` en `/tmp/nota-del-contenedor.txt`.

### 5 — exec sobre un contenedor parado (el fallo útil)

**Acción:**

```bash
docker stop m00-vivo
docker exec m00-vivo hostname || echo "exec rechazo"
docker start m00-vivo
docker exec m00-vivo hostname
docker rm -f m00-vivo
```

**Por qué:** Sin PID 1 no hay “sitio” donde meter otro proceso.

**Resultado esperado:** el `exec` tras `stop` falla; tras `start` vuelve a funcionar.

## Comprueba tu entendimiento

**PID 1 no cambia**

Con un `m00-vivo` Running: `docker top m00-vivo` mientras haces `docker exec m00-vivo sleep 10` en otra terminal.

→ El PID 1 sigue siendo `sleep 3600`. El `sleep 10` es un proceso **hijo** temporal.

**logs vs exec**

`docker logs` ¿muestra lo que imprimiste con `echo` dentro de `exec`?

→ No. Eso fue stdout del proceso `exec`, no del PID 1. (Salvo que redirigieras al mismo sitio; aquí no.)

## Reto

### 1 — Shell interactiva breve

```bash
docker run -d --name m00-vivo alpine:3.20 sleep 3600
docker exec -it m00-vivo sh
```

Dentro de la shell: `uname -a`, `exit`. Luego `docker rm -f m00-vivo`.

<details>
<summary>Ver solución</summary>

`uname` muestra Linux (el kernel del Codespace). Has estado *dentro* del sistema de ficheros de Alpine, no en una VM distinta.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `is not running` | Contenedor Exited o parado | `docker start` o vuelve a `run -d` |
| Te quedas atrapado en `sh` | No has hecho `exit` | Escribe `exit` + Enter |
| `nota.txt` no está | Lo escribiste en otro contenedor | El `--name` tiene que ser el mismo |
