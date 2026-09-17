# M07-03 — Operator Pattern

[← Página anterior](M07-02-etcd-backup.md) · [Siguiente página →](../M08-almacenamiento/README.md)

> Práctica del módulo. La teoría y la demo están en el [README del módulo](README.md).

### Objetivo

Inspeccionar el Prometheus Operator y crear un `ServiceMonitor` que gestione el scrape de `shop-web`.

### Prerrequisitos

- Release `kps` instalado ([M07-01](M07-01-prometheus-grafana.md)). Si lo desinstalaste, vuelve a instalarlo.

### En qué consiste

Leer CRs, aplicar un ServiceMonitor sobre el Service `shop-web` y ver el target en Prometheus.

### 1 — El operador y sus CR

**Acción:**

```bash
kubectl -n monitoring get deploy | grep operator
kubectl get prometheus -A
kubectl get servicemonitor -A | head
```

**Por qué:** No “hay un Prometheus instalado a mano”: hay un **custom resource** `Prometheus` que el operador reconcilia a StatefulSet + config.

**Resultado esperado:** un `Prometheus` (habitualmente `kps-kube-prometheus-stack-prometheus`) y varios ServiceMonitor.

### 2 — Etiquetar el Service de la app

**Acción:**

```bash
kubectl -n shop label svc shop-web app=shop-web --overwrite
cat <<'EOF' | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: shop-web
  namespace: monitoring
  labels:
    release: kps
spec:
  selector:
    matchLabels:
      app: shop-web
  namespaceSelector:
    matchNames:
      - shop
  endpoints:
    - port: http
      interval: 30s
EOF
```

**Por qué:** Implementas un recurso **específico** que el operador sabe gestionar. El label `release: kps` encaja con el selector por defecto del Helm chart.

**Resultado esperado:** `servicemonitor.monitoring.coreos.com/shop-web` created.

> [!NOTE]
> http-echo no exporta métricas Prometheus. El target puede quedar DOWN: igual ves el Operator **intentando** scrape. El aprendizaje es el CR, no el dashboard de la tienda.

### 3 — Targets

**Acción:** con el port-forward de Prometheus (:9090) abre **Status → Targets** y busca `shop-web`.

O:

```bash
kubectl -n monitoring get servicemonitor shop-web -o yaml | head -40
```

**Por qué:** El operador ha fusionado este monitor en la config de Prometheus. Tú no editaste `prometheus.yml`.

**Resultado esperado:** el objeto persiste; en la UI aparece un job asociado (up o down).

### 4 — Relación operador / recurso

**Acción:**

```bash
kubectl -n monitoring delete servicemonitor shop-web
```

**Por qué:** Borrar el CR es el gesto inverso: el controlador deja de scrape. El Deployment `shop-web` no se toca.

**Resultado esperado:** `shop-web` (app) sigue Running; el monitor desaparece.

## Comprueba tu entendimiento

**Quién crea los Pods de Prometheus**

`kubectl -n monitoring get prometheus -o yaml | grep -A2 kind`

→ kind `Prometheus`. El StatefulSet lo materializa el operator, no el lab a mano.

**CRD vs objeto**

`kubectl get crd prometheuses.monitoring.coreos.com`

→ La **definición**. `kubectl get prometheus` son las **instancias**.

## Reto

### 1 — Otro recurso del operador

Lista `PrometheusRule` y lee uno. ¿Qué representa?

<details>
<summary>Ver solución</summary>

Reglas de alerting/recording. También las reconcilia el mismo operator. Es el mismo patrón: YAML declarativo → controlador → config viva.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| ServiceMonitor ignored | Falta label `release: kps` | El Prometheus del chart selecciona por ese label |
| CRD not found | Stack no instalado | Repite M07-01 |
