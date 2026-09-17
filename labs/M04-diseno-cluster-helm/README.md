# M04 — Diseño y configuración del clúster

[← Página anterior](../M03-ciclo-vida-aplicaciones/M03-02-rolling-rollback-escala.md) · [Siguiente página →](M04-01-ha-fallo-maestro.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

## Qué aprenderás

- Diseñar un control-plane en HA (quórum de etcd, load balancer de API).
- Probar tolerancia a fallos parando un nodo maestro.
- Distinguir instalación del clúster (kind/kubeadm) de instalación de *software en* el clúster (Helm).
- Instalar y actualizar un chart con values personalizados.

## Teoría

etcd es un clúster Raft. Con **tres** miembros, puedes perder **uno** y seguir teniendo quórum.
Dos maestros no bastan: un fallo te deja sin mayoría.

kind, con varios `role: control-plane`, crea un contenedor **external-load-balancer** delante
de los kube-apiserver. kubectl habla con el LB, no con un maestro concreto.

| Capa | Qué hay en este lab |
|------|---------------------|
| Nodos | 3 CP + 2 workers (kind = kubeadm por nodo) |
| Red de Pods | Calico |
| Entrada | ingress-nginx + hostPorts |
| Paquetes | Helm (charts) |

> [!NOTE]
> **Helm** no instala Kubernetes. Instala **aplicaciones y operadores** *dentro* del clúster
> (Deployments, CRDs, Services) versionados y parametrizados con `values.yaml`.

## Demostración guiada

> Recorrido que hace el formador en vivo.

1. `docker ps` lista tres control-plane, dos workers y el LB. `kubectl get --raw=/readyz` sigue
   ok.
2. Al hacer `docker stop k8s-ops-control-plane` ese nodo pasa a `NotReady`. Un `kubectl get nodes`
   **posterior** sigue funcionando: el LB ha enviado la petición a otro apiserver.
3. `helm install` del chart `infra/charts/ops-web` con `-f values-staging.yaml` materializa réplicas
   y, si se activa, un Ingress. `helm upgrade` cambia el mensaje sin reescribir YAML a mano.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M04-01 | [HA y fallo de un maestro](M04-01-ha-fallo-maestro.md) | Parar un control-plane y validar la API |
| M04-02 | [Helm con values](M04-02-helm-values.md) | Instalar y actualizar `ops-web` |

→ Empieza por **[M04-01 — HA y fallo de un maestro](M04-01-ha-fallo-maestro.md)**.
