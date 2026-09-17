# M03-01 — Despliegue, ConfigMap y Secret

[← Página anterior](README.md) · [Siguiente página →](M03-02-rolling-rollback-escala.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Publicar `shop-web` con configuración externalizada y comprobar que el Service apunta a los Pods.

### Prerrequisitos

- Clúster `k8s-ops` Ready.

### En qué consiste

Aplicar el manifiesto de `shop`, inspeccionar env inyectada y hacer un `curl` interno al Service.

### 1 — Aplicar la aplicación

**Acción:**

```bash
kubectl apply -f infra/manifests/m03/shop.yaml
kubectl -n shop get deploy,po,svc,cm,secret
```

**Por qué:** Un apply declarativo es el hábito de administración: el YAML es el contrato, no los clics.

**Resultado esperado:** namespace `shop`, Deployment `shop-web` con 2/2, Service ClusterIP, ConfigMap y Secret.

### 2 — Config y secreto en el contenedor

**Acción:**

```bash
POD=$(kubectl -n shop get pod -l app=shop-web -o jsonpath='{.items[0].metadata.name}')
kubectl -n shop exec "$POD" -- printenv | grep APP_
```

**Por qué:** `envFrom` monta **todas** las claves. ConfigMap y Secret se distinguen por el objeto, no por el nombre de variable.

**Resultado esperado:** `APP_TITLE`, `APP_ENV` y `APP_TOKEN` presentes.

> [!TIP]
> `kubectl -n shop get secret shop-secret -o jsonpath='{.data.APP_TOKEN}' | base64 -d; echo`
> enseña que un Secret no está cifrado en etcd por defecto: está ofuscado.

### 3 — Service como nombre estable

**Acción:**

```bash
kubectl -n shop run curl --rm -it --restart=Never --image=busybox:1.37 -- wget -qO- http://shop-web
```

**Por qué:** Las IPs de Pod cambian en cada rolling update. El Service DNS `shop-web.shop.svc` se mantiene.

**Resultado esperado:** texto `shop-web v1`.

## Comprueba tu entendimiento

**Quién es el padre del Pod**

`kubectl -n shop get po,rs,deploy`

→ Cada Pod tiene un ReplicaSet; el ReplicaSet lo posee el Deployment `shop-web`.

**Endpoints**

`kubectl -n shop get endpoints shop-web`

→ Dos IPs, una por Pod Ready.

## Reto

### 1 — Cambiar solo la config

Edita el ConfigMap `APP_TITLE` y reinicia el Deployment. ¿El Service sigue respondiendo?

<details>
<summary>Ver solución</summary>

```bash
kubectl -n shop edit cm shop-config
kubectl -n shop rollout restart deploy/shop-web
kubectl -n shop rollout status deploy/shop-web
```

Un ConfigMap ya montado como env **no** se refresca solo: hace falta nuevo Pod.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| ImagePullBackOff | Docker Hub lento | Reintentar; el curso usa imágenes pequeñas |
| wget: bad address | Lanzaste curl fuera de `shop` | `-n shop` o FQDN `shop-web.shop.svc.cluster.local` |
