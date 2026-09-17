# M06-02 — TLS de Ingress y políticas

[← Página anterior](M06-01-rbac-usuario.md) · [Siguiente página →](../M07-mantenimiento-monitorizacion/README.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Servir `shop.local` por HTTPS en `:8443` y reafirmar el cierre de tráfico entre namespaces.

### Prerrequisitos

- Ingress HTTP de M05 funcionando. Usa el kubeconfig **admin** (`kind-k8s-ops`), no el de `appuser`.

### En qué consiste

Certificado del servidor Ingress (autofirmado), Secret TLS, patch del Ingress, curl HTTPS, NetworkPolicy.

### 1 — Certificado del borde (no el de la API)

**Acción:**

```bash
openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
  -keyout shop-tls.key -out shop-tls.crt \
  -subj "/CN=shop.local" -addext "subjectAltName=DNS:shop.local"
kubectl -n shop create secret tls shop-tls --cert=shop-tls.crt --key=shop-tls.key
```

**Por qué:** El TLS de Ingress es un secreto de aplicación. No sustituye los certs de `/etc/kubernetes/pki`.

**Resultado esperado:** Secret `shop-tls` tipo `kubernetes.io/tls`.

### 2 — Enganchar el Ingress

**Acción:**

```bash
kubectl -n shop patch ing shop-web --type=merge -p '{
  "spec": {
    "tls": [{"hosts": ["shop.local"], "secretName": "shop-tls"}]
  }
}'
kubectl -n shop get ing shop-web
```

**Por qué:** El controller lee `spec.tls` y abre 443 (mapeado a **8443** en tu Codespace).

**Resultado esperado:** columna HOSTS `shop.local` y TLS asociado.

### 3 — Probar HTTPS

**Acción:**

```bash
curl -skH 'Host: shop.local' https://127.0.0.1:8443/
echo | openssl s_client -connect 127.0.0.1:8443 -servername shop.local 2>/dev/null | openssl x509 -noout -subject
```

**Por qué:** `-k` acepta el autofirmado. `s_client` muestra que el CN es `shop.local`.

**Resultado esperado:** cuerpo de `shop-web` y subject `CN = shop.local`.

### 4 — Políticas entre Pods

**Acción:** si borramos las policies, reaplícalas y verifica el bloqueo shop → payments:

```bash
kubectl apply -f infra/manifests/m05/networkpolicy.yaml
kubectl -n shop exec netcheck -- curl -s --max-time 5 http://payments-api.payments || echo BLOQUEADO
```

**Por qué:** El temario de seguridad pide políticas de red además de RBAC: defensa en profundidad.

**Resultado esperado:** `BLOQUEADO` (o timeout).

## Comprueba tu entendimiento

**PKI de la API vs TLS de Ingress**

`docker exec k8s-ops-control-plane ls /etc/kubernetes/pki | head`

→ CA y certs de **apiserver/etcd**. Distintos del Secret `shop-tls`.

**Quién puede leer el Secret TLS**

`kubectl --kubeconfig=kubeconfig-appuser -n shop get secret shop-tls`

→ `Forbidden` (el Role de M06-01 no lista secrets). Eso es deseable.

## Reto

### 1 — Forzar HTTPS en el controller

Añade la anotación `nginx.ingress.kubernetes.io/ssl-redirect: "true"` y prueba HTTP :8080.

<details>
<summary>Ver solución</summary>

El controller responde **308/301** hacia HTTPS. `curl -sH 'Host: shop.local' http://127.0.0.1:8080/` ya no sirve el body de la app.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| SSL error | Probaste 8080 con https o 8443 con http | HTTP→8080, HTTPS→8443 |
| Secret not found | TLS en otro namespace | El Secret debe estar en `shop` |
