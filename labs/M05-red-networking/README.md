# M05 — Red y networking

[← Página anterior](../M04-diseno-cluster-helm/M04-02-helm-values.md) · [Siguiente página →](M05-01-services-ingress.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

## Qué aprenderás

- Encadenar Pod → Service (ClusterIP) → Ingress (borde).
- Balancear tráfico entre réplicas.
- Restringir este-oeste con NetworkPolicy entre namespaces.

## Teoría

Cada Pod recibe una IP del CIDR de Calico (`192.168.0.0/16` aquí). Esa IP muere con el Pod,
así que no sirve como nombre estable. Un **Service** es la abstracción que agrupa Pods
(por labels) y define **cómo acceder** a ellos (ClusterIP, NodePort, puerto).

![Service delante de Pods en varios nodos](../img/M05-demo-service.png)

**Ingress** mapea host y rutas HTTP hacia Services. En cloud suele haber un balanceador
de pago delante; aquí el controller **ingress-nginx** (proxy inverso) entra por `:8080`/`:8443`
del Codespace.

| Tipo | Alcance | Uso típico |
|------|---------|------------|
| **ClusterIP** | Solo dentro del clúster | Este-oeste |
| **NodePort** | Puerto alto en cada nodo | Labs / legado |
| **LoadBalancer** | IP externa (cloud) | En kind casi nunca hay LB cloud |
| **Ingress** | L7 HTTP(S) en el controller | Host + path → Service |

**NetworkPolicy** es firewall de Pod. Por defecto **todo está permitido**. En cuanto existe una
policy que selecciona un Pod, ese Pod pasa a “deny + lo que la policy permite”.

> [!WARNING]
> Una policy de egress que no lista DNS (`kube-system`, puerto 53) “rompe internet” dentro del namespace.
> Calico hace cumplir estas reglas; kindnet (CNI por defecto de kind) no era suficiente para este curso.

## Demostración guiada

> Recorrido que hace el formador en vivo.

1. `kubectl -n shop get svc shop-web` muestra ClusterIP. Varios `wget` al Service caen en réplicas
   distintas (http-echo no muestra hostname, pero `kubectl get ep` confirma varias IPs).
2. El Ingress `shop.local` entra por `:8080` del Codespace (hostPort del control-plane `ingress-ready`).
3. Tras aplicar las policies, un `netcheck` en `shop` sigue llegando a `shop-web` y **deja de**
   llegar a `payments-api.payments`.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M05-01 | [Services, Ingress y balanceo](M05-01-services-ingress.md) | Exponer y balancear `shop-web` |
| M05-02 | [NetworkPolicy entre namespaces](M05-02-networkpolicy.md) | Cortar shop → payments |

→ Empieza por **[M05-01 — Services, Ingress y balanceo](M05-01-services-ingress.md)**.
