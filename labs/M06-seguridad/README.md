# M06 — Seguridad

[← Página anterior](../M05-red-networking/M05-02-networkpolicy.md) · [Siguiente página →](M06-01-rbac-usuario.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero la **teoría**, luego la **demostración guiada** del
> formador, y después **practicas tú** en el/los laboratorio(s).

## Qué aprenderás

- Separar autenticación (quién eres) de autorización (qué puedes).
- Crear un usuario de certificado con RBAC limitado a un namespace.
- Montar TLS en Ingress con un Secret.
- Cerrar tráfico entre Pods con NetworkPolicy (continuación de M05).

## Teoría

kubectl presenta un **cliente TLS** (o un token). El apiserver **autentica**.
Después RBAC **autoriza**: Role (un namespace) o ClusterRole (todo el clúster) + Binding.

| Identidad | Típico en lab | Típico en prod |
|-----------|---------------|----------------|
| User certificado | CSR + kubeconfig | Raro (humanos van a OIDC) |
| ServiceAccount | Tokens de Pod | Apps y operadores |
| Grupo | `O=` del certificado | Grupos del IdP |

TLS del **apiserver** ya lo generó kubeadm/kind (`/etc/kubernetes/pki`).
TLS que tú montas en este módulo es el del **borde HTTP** (Secret `kubernetes.io/tls` + Ingress).

> [!NOTE]
> Un Role Binding a `User: appuser` no funciona si el kubeconfig sigue usando el cliente **admin**.
> El `--kubeconfig` tiene que presentar el CN `appuser`.

## Demostración guiada

> Recorrido que hace el formador en vivo.

1. Se genera una clave y un CSR. El apiserver firma con la CA del clúster. El kubeconfig de
   `appuser` lista pods en `shop` y recibe `Forbidden` al listar nodos o secretos.
2. Un Secret TLS se referencia en el Ingress; `curl -k https://127.0.0.1:8443` con Host
   `shop.local` habla HTTPS.
3. La policy entre Pods (ya vista en M05) se relee como control de seguridad, no solo de red.

## Ahora practica tú

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M06-01 | [Usuario RBAC limitado](M06-01-rbac-usuario.md) | Certificado + Role en `shop` |
| M06-02 | [TLS de Ingress y políticas](M06-02-tls-networkpolicy.md) | HTTPS y cierre este-oeste |

→ Empieza por **[M06-01 — Usuario RBAC limitado](M06-01-rbac-usuario.md)**.
