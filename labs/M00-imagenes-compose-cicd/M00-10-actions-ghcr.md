# M00-10 — Actions y GHCR

[← Página anterior](M00-09-compose-prod.md) · [Siguiente página →](../M01-entorno-codespace-kind/README.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Publicar `m00-web` en el GitHub Container Registry **desde tu fork**, con el workflow del repo.

### Prerrequisitos

- Trabajas en **tu fork** (no solo en el Codespace del repo original si no tienes permiso de Packages).
- GitHub Actions habilitado: en el fork, **Settings → Actions → General → Allow all actions** (o las del repo).

### En qué consiste

Leer el workflow, lanzarlo a mano (`workflow_dispatch`), ver el job en verde y localizar el paquete `m00-web`.

### 1 — Leer el pipeline

**Acción:** abre `.github/workflows/m00-publish-image.yml` (en el editor o en GitHub).

**Por qué:** Es el mismo `docker build` de M00-07, pero en un runner de GitHub. Empuja a `ghcr.io/<cuenta>/<repo>/m00-web`.

**Resultado esperado:** job `publish`, `docker/login-action` con `GITHUB_TOKEN`, `build-push-action` con `target: runtime` y context `infra/m00/web`.

### 2 — Lanzar el workflow

**Acción:** en GitHub, tu fork → **Actions → M00 publicar imagen → Run workflow → Run workflow** (rama `main`).

Si **Actions** está vacío: confirma que hiciste **fork** y que Actions no está deshabilitado. El primer acceso a Actions a veces pide un botón *I understand*.

**Por qué:** `workflow_dispatch` no espera a que cambies un fichero. Es el gesto de “publica ahora”.

**Resultado esperado:** un run en cola y luego el job **publish** en verde.

### 3 — Ver la imagen en Packages

**Acción:** en tu fork, **Packages** (columna derecha de la portada del repo) o
`https://github.com/users/TU_USUARIO/packages` y busca `m00-web`.

El nombre completo es:

```text
ghcr.io/tu-usuario/kubernetes-administradores-201/m00-web:latest
```

(todo en minúsculas).

**Por qué:** El registry es GHCR, no Docker Hub. El tag `latest` y el SHA del commit salen del workflow.

**Resultado esperado:** paquete con al menos el tag `latest`.

> [!TIP]
> Si el paquete sale **privado**, en el paquete → **Package settings → Change visibility → Public**
> (solo si quieres que otros lo bajen). Para este curso basta con que **tú** lo veas.

### 4 — (Opcional) Tirar la imagen al Codespace

**Acción:**

```bash
# sustituye TU_USUARIO
echo "$GITHUB_TOKEN" | docker login ghcr.io -u TU_USUARIO --password-stdin
# En Codespace a veces ya estás autenticado; si no, usa un PAT con read:packages
docker pull ghcr.io/tu-usuario/kubernetes-administradores-201/m00-web:latest
docker run --rm -p 8888:80 ghcr.io/tu-usuario/kubernetes-administradores-201/m00-web:latest
```

Si el login falla, sáltate el pull: el objetivo del lab es **ver el paquete publicado**.

**Por qué:** Es el mismo ciclo que usará un clúster: build en CI, `pull` en el nodo.

**Resultado esperado:** tarjeta verde (imagen `runtime`) en 8888, o al menos el paquete visible en GitHub.

### 5 — Limpieza local

**Acción:**

```bash
./scripts/m00-clean.sh
```

**Por qué:** M01 levantará kind. Mejor sin contenedores M00 ocupando 8888.

**Resultado esperado:** `docker ps` sin `m00-*` ni servicios compose `web`.

## Comprueba tu entendimiento

**Quién construye**

¿El Codespace publica la imagen en este lab?

→ No (salvo el paso opcional de pull). **Actions** construye y hace push.

**Qué etapa**

El workflow pone `target: runtime`. ¿Lleva bind mount?

→ No. Es el build de prod.

## Reto

### 1 — Disparar el workflow con un push

Haz un cambio mínimo en `infra/m00/web/site/index.html`, commit y push a `main` de **tu fork**.

<details>
<summary>Ver solución</summary>

El `on.push.paths` incluye `infra/m00/web/**`. Debe aparecer un run automático en Actions. Si no: Actions deshabilitado o push a otra rama.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| Actions no aparece | Estás en el repo original sin permisos / Actions off | Usa **tu fork**; Settings → Actions |
| `denied: permission` en GHCR | Falta `packages: write` o el repo es de una org restrictiva | El YAML del curso ya pide ese permiso; en orgs a veces hay que aceptar Packages |
| No veo el paquete | Job en rojo | Abre el run y lee el paso *Build y push* |
| `docker pull` denied | Paquete privado y no estás logueado | Login o visibilidad Public |
