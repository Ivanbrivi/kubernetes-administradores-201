# M02 — Introducción a Kubernetes

[← Página anterior](../M01-entorno-codespace-kind/M01-02-cluster-operativo.md) · [Siguiente página →](M02-01-arquitectura-api.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

## Qué aprenderás

- Nombrar los componentes del control-plane y de un nodo worker.
- Explicar qué es la API de Kubernetes y dónde persiste (etcd).
- Inspeccionar nodos, namespaces y pods de sistema con kubectl.
- Relacionar kind + kubeadm: los ficheros de `/etc/kubernetes` dentro del nodo.

## Teoría

Un clúster Kubernetes es un **plano de control** que expone una API y unos **nodos** que ejecutan Pods.

| Plano | Componentes | Pregunta que responden |
|-------|-------------|------------------------|
| **Control-plane** | kube-apiserver, etcd, scheduler, controller-manager | ¿Cuál es el estado deseado? ¿Dónde coloco este Pod? |
| **Nodo** | kubelet, kube-proxy (y el runtime de contenedores) | ¿Este Pod está vivo en esta máquina? |
| **Red** | CNI (aquí Calico) | ¿Cómo se alcanzan los Pods entre nodos? |

**Objetos** (Deployment, Service, Pod…) son documentos JSON/YAML que envías a la API.
**etcd** guarda esa verdad. kubectl nunca “habla con Docker”: habla con el apiserver.

> [!NOTE]
> **Pod** no es un contenedor suelto: es el átomo de scheduling (uno o más contenedores, red y volúmenes compartidos).
> Un **Deployment** no corre él mismo el proceso: crea ReplicaSets que crean Pods.

kind arranca cada nodo con **kubeadm**. Por eso en el temario aparece kubeadm *o* kind:
aquí usas kind y **observas** el resultado de kubeadm (`admin.conf`, manifiestos estáticos en
`/etc/kubernetes/manifests`).

## Demostración guiada

> Recorrido que hace el formador en vivo. Tono descriptivo, sin imperativos.

1. Al ejecutar `kubectl get componentstatuses` o, en versiones recientes,
   `kubectl get pods -n kube-system`, aparecen `kube-apiserver`, `etcd`, `kube-scheduler` y
   `kube-controller-manager` **en cada control-plane** (estáticos, un pod por nodo).
2. `kubectl get --raw=/apis | head` muestra grupos de API (`apps`, `networking.k8s.io`…).
   Todo objeto vive en un grupo/versión/recurso.
3. `docker exec k8s-ops-control-plane ls /etc/kubernetes` lista `admin.conf`, `pki/` y
   `manifests/`: es el arranque kubeadm que kind ya hizo.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M02-01 | [Arquitectura y API](M02-01-arquitectura-api.md) | Recorrer control-plane, etcd y grupos de API |
| M02-02 | [Validar nodos y sistema](M02-02-validar-nodos-sistema.md) | `describe nodes`, pods de todos los namespaces |

→ Empieza por **[M02-01 — Arquitectura y API](M02-01-arquitectura-api.md)**.
