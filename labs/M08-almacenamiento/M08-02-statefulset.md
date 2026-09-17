# M08-02 — StatefulSet persistente

[← Página anterior](M08-01-pvc-storageclass.md) · [Siguiente página →](../../README.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Desplegar un StatefulSet de 2 réplicas y demostrar que cada una tiene su propio PVC y nombre estable.

### Prerrequisitos

- [M08-01](M08-01-pvc-storageclass.md) (sabes qué es un PVC Bound).

### En qué consiste

Apply de `catalog`, inspección de pods `catalog-0`/`catalog-1`, escritura por réplica, delete ordenado.

### 1 — Crear el StatefulSet

**Acción:**

```bash
kubectl apply -f infra/manifests/m08/statefulset-catalog.yaml
kubectl -n shop get sts,po,pvc,svc -l app=catalog
```

**Por qué:** El Service `clusterIP: None` (headless) da DNS `catalog-0.catalog.shop.svc`.

**Resultado esperado:** `catalog-0` y `catalog-1` Running; PVC `catalog-data-catalog-0` y `…-1`.

### 2 — Identidad y disco

**Acción:**

```bash
kubectl -n shop exec catalog-0 -- cat /data/id.txt
kubectl -n shop exec catalog-1 -- cat /data/id.txt
kubectl -n shop exec catalog-0 -- sh -c 'echo solo-cero >> /data/id.txt'
```

**Por qué:** Cada réplica monta **su** PVC. Lo que escribes en `-0` no aparece en `-1`.

**Resultado esperado:** hostnames distintos; `solo-cero` solo en `catalog-0`.

### 3 — Borrar un Pod con nombre

**Acción:**

```bash
kubectl -n shop delete pod catalog-0
kubectl -n shop wait --for=condition=Ready pod/catalog-0 --timeout=90s
kubectl -n shop exec catalog-0 -- cat /data/id.txt
```

**Por qué:** El StatefulSet **recrea el mismo nombre** `catalog-0` y reatacha el mismo PVC.

**Resultado esperado:** el Pod vuelve a llamarse `catalog-0` y `solo-cero` sigue ahí.

### 4 — Escala controlada

**Acción:**

```bash
kubectl -n shop scale sts/catalog --replicas=1
kubectl -n shop get po,pvc -l app=catalog
```

**Por qué:** Al bajar réplicas, `catalog-1` se apaga; su PVC **permanece** (política por defecto). Subir otra vez reutiliza el disco.

**Resultado esperado:** solo `catalog-0`; PVC `-1` sigue Bound o Released según versión; no se borra el dato automáticamente.

Cuando termines, deja 2 réplicas si quieres el clúster “completo”:

```bash
kubectl -n shop scale sts/catalog --replicas=2
```

## Comprueba tu entendimiento

**DNS headless**

`kubectl -n shop exec netcheck -- nslookup catalog-0.catalog.shop.svc.cluster.local`

→ Resuelve a la IP del Pod 0 (si `netcheck` sigue existiendo).

**Diferencia con Deployment**

El Pod de inventory cambiaba de nombre en M08-01; `catalog-0` no.

→ Esa estabilidad es el motivo de StatefulSet (y de las bases de datos).

## Reto

### 1 — Orden de arranque

Borra `catalog-0` y `catalog-1` a la vez y observa el orden en que vuelven.

<details>
<summary>Ver solución</summary>

El controlador levanta `catalog-0` primero y espera Ready antes de `catalog-1` (salvo `podManagementPolicy: Parallel`). Es el contrato de aplicaciones ordenadas.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `catalog-1` Pending | Disco del nodo / local-path | `kubectl describe po catalog-1` |
| PVC huérfanos | Escalaste a 0 y esperabas borrado | Los PVC de STS no se borran al downscale; bórralos a mano si el lab lo pide |
