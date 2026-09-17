# M03 — Ciclo de vida de aplicaciones

[← Página anterior](../M02-introduccion-kubernetes/M02-02-validar-nodos-sistema.md) · [Siguiente página →](M03-01-despliegue-config.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

## Qué aprenderás

- Desplegar una aplicación con Deployment + Service.
- Externalizar config (`ConfigMap`) y secretos (`Secret`).
- Hacer un Rolling Update, comprobar el historial y revertir con rollback.
- Escalar réplicas a mano.

## Teoría

| Objeto | Responsabilidad |
|--------|-----------------|
| **Pod** | Instancia en ejecución (efímera). |
| **ReplicaSet** | “Quiero N pods con esta plantilla”. |
| **Deployment** | Cómo actualizar esa plantilla (rolling, historial, rollback). |
| **ConfigMap** | Config no sensible inyectada como env o fichero. |
| **Secret** | Igual, pero para credenciales (sigue siendo base64, no magia). |
| **Service** | IP/nombre estable delante de pods que nacen y mueren. |

Estrategia **RollingUpdate**: Kubernetes sube pods nuevos y baja los viejos respetando
`maxUnavailable` / `maxSurge`. Si la versión nueva no pone `Ready`, puedes
`kubectl rollout undo`.

> [!WARNING]
> Editar un Pod huérfano o `kubectl delete pod` no cambia el estado deseado: el ReplicaSet crea otro.
> El contrato que debes cambiar es el **Deployment**.

## Demostración guiada

> Recorrido que hace el formador en vivo.

1. Al aplicar `infra/manifests/m03/shop.yaml` aparece el namespace `shop`, dos réplicas
   `shop-web` y el Service ClusterIP.
2. Un `kubectl -n shop set` o un cambio de `args` del contenedor dispara un nuevo ReplicaSet.
   `kubectl -n shop rollout status deploy/shop-web` espera a que los pods nuevos estén Ready.
3. `kubectl -n shop rollout history deploy/shop-web` lista revisiones; `rollout undo` vuelve a la anterior.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M03-01 | [Despliegue, ConfigMap y Secret](M03-01-despliegue-config.md) | Publicar `shop-web` |
| M03-02 | [Rolling update, rollback y escala](M03-02-rolling-rollback-escala.md) | Actualizar, revertir y escalar |

→ Empieza por **[M03-01 — Despliegue, ConfigMap y Secret](M03-01-despliegue-config.md)**.
