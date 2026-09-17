# M04-01 — HA y fallo de un maestro

[← Página anterior](README.md) · [Siguiente página →](M04-02-helm-values.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Demostrar que el clúster `k8s-ops` sigue sirviendo la API cuando cae **un** control-plane.

### Prerrequisitos

- Cinco nodos Ready. No pares dos maestros a la vez.

### En qué consiste

Inventario Docker/kind, stop de `k8s-ops-control-plane`, comprobaciones con kubectl, start de nuevo.

### 1 — Topología antes del fallo

**Acción:**

```bash
kubectl get nodes
docker ps --format '{{.Names}}' | sort
```

**Por qué:** Necesitas el nombre exacto del contenedor a parar y confirmar que hay tres etcd.

**Resultado esperado:** `k8s-ops-control-plane`, `...-plane2`, `...-plane3`, workers y `...-external-load-balancer`.

### 2 — Simular la caída

**Acción:**

```bash
docker stop k8s-ops-control-plane
sleep 8
kubectl get nodes
kubectl get --raw=/readyz
kubectl -n shop get deploy
```

**Por qué:** El temario pide apagar un nodo maestro. En kind el “apagado” es `docker stop` de ese contenedor.

**Resultado esperado:** `k8s-ops-control-plane` `NotReady` (o unreachable). **Los demás Ready**. `readyz` ok. `shop` sigue listable.

> [!WARNING]
> Si paras **dos** control-plane, etcd pierde quórum y la API se queda muda. No lo hagas.

### 3 — Recuperar el maestro

**Acción:**

```bash
docker start k8s-ops-control-plane
kubectl wait --for=condition=Ready node/k8s-ops-control-plane --timeout=180s
kubectl get nodes
```

**Por qué:** Un clúster operativo no se recrea entero por un nodo caído: se reintegra.

**Resultado esperado:** otra vez cinco `Ready`.

## Comprueba tu entendimiento

**A quién apunta kubectl**

`kubectl cluster-info`

→ El control plane sigue siendo el LB, no el contenedor que paraste.

**etcd**

`kubectl -n kube-system get po -l component=etcd -o wide`

→ Tres miembros; durante el stop, uno desaparece o no está Ready.

## Reto

### 1 — ¿Qué pasaría con un solo maestro?

Sin hacerlo: escribe por qué un kind de un solo control-plane no habría pasado esta prueba.

<details>
<summary>Ver solución</summary>

Un único kube-apiserver/etcd vive en ese contenedor. `docker stop` corta la API: kubectl deja de responder.
La HA no es “tres VMs en el diagrama”; es quórum + LB.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| kubectl cuelga tras el stop | Paraste el LB o dos CP | `docker start` de lo que paraste; si no, `cluster-down` / `cluster-up` |
| Nodo NotReady eterno al volver | kubelet lento | Espera `kubectl wait`; revisa `docker logs k8s-ops-control-plane` |
