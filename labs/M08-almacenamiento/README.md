# M08 — Almacenamiento

[← Página anterior](../M07-mantenimiento-monitorizacion/M07-03-operator-pattern.md) · [Siguiente página →](M08-01-pvc-storageclass.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

## Qué aprenderás

- Pedir disco con un PVC y dejar que la StorageClass cree el PV.
- Comprobar que el dato sobrevive al reinicio del Pod.
- Usar un StatefulSet (identidad estable + un PVC por réplica).

## Teoría

El sistema de ficheros del contenedor **muere con el Pod**. Lo que debe sobrevivir va a un
volumen montado en el Pod (varios contenedores del mismo Pod pueden compartirlo).

![Volúmenes en el nodo, montados en los Pods](../img/M08-demo-volumes.png)

| Objeto | Analogía |
|--------|----------|
| **PersistentVolume (PV)** | El disco físico (o su equivalente). |
| **PersistentVolumeClaim (PVC)** | El contrato: “quiero 256Mi RWO”. |
| **StorageClass** | El provisioner automático (`local-path` en este clúster). |
| **StatefulSet** | Pods con nombre estable (`catalog-0`, `catalog-1`) y PVC propio. |

`volumeBindingMode: WaitForFirstConsumer` (local-path) espera a saber **en qué nodo** cae el Pod
antes de crear el PV. En kind cada nodo es un contenedor: el dato queda en el filesystem de ese nodo.

> [!NOTE]
> Un **Deployment** + un PVC `ReadWriteOnce` no escala a 2 réplicas en dos nodos.
> Para N réplicas con disco: StatefulSet + `volumeClaimTemplates`.

## Demostración guiada

> Recorrido que hace el formador en vivo.

1. Al aplicar `infra/manifests/m08/pvc-inventory.yaml` el PVC queda `Pending` hasta que el Pod
   se programa; luego `Bound` y aparece un PV `pvc-…`.
2. Se escribe una línea en `/data/log.txt`, se borra el Pod, el ReplicaSet crea otro, **el fichero sigue**.
3. El StatefulSet `catalog` crea `catalog-data-catalog-0` y `…-1`, dos PVC distintos.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M08-01 | [PVC y StorageClass](M08-01-pvc-storageclass.md) | Disco para `inventory` |
| M08-02 | [StatefulSet persistente](M08-02-statefulset.md) | Dos réplicas con volumen propio |

→ Empieza por **[M08-01 — PVC y StorageClass](M08-01-pvc-storageclass.md)**.
