# Configuração do Self-Healing com Alertmanager

## Visão Geral

O fluxo de auto-remediation (self-healing) integra:

1. **Prometheus** → detecta problema (ex: HighErrorRate5xx)
2. **Alertmanager** → agrupa e roteia alertas
3. **Self-Healing Bridge** → traduz webhook em GitHub `repository_dispatch`
4. **GitHub Actions** (`.github/workflows/self-healing.yaml`) → executa `kubectl rollout restart`
5. **Discord** → notifica time que auto-remediation foi executada

## Pré-requisitos

### 1. Self-Healing Bridge Deploy

Certifique-se de que o deployment está rodando:

```bash
kubectl get pods -n monitoring -l app=self-healing-bridge
```

Se não estiver, faça o deploy:

```bash
kubectl apply -f gitops/monitoring/self-healing-bridge/deployment.yaml

# Criar o secret com GitHub token
kubectl create secret generic self-healing-bridge-secret \
  --from-literal=GITHUB_TOKEN='ghp_seu_token_aqui' \
  -n monitoring
```

### 2. GitHub Token com "Actions: write"

O token precisa ter permissão para disparar `repository_dispatch` events:

- Vá para GitHub → Settings → Developer settings → Personal access tokens
- Fine-grained tokens → New token
- **Repository access**: `TC5-ST`
- **Permissions**: Actions → `write`
- Copie o token e adicione ao secret acima

## Configuração de Alertas

### Labels Necessários

Para que o self-healing-bridge identifique qual serviço reiniciar, os alertas **DEVEM** incluir um dos labels:

- `service: "donation-service"` (preferido)
- `service: "ngo-service"`
- `service: "volunteer-service"`

OU

- `pod` começando com o nome do serviço (ex: `pod: "donation-service-abc123"`)

### Exemplo: PrometheusRule com Service Label

No seu `gitops/prometheus/rules.yaml` ou equivalente, adicione o label `service` aos alertas:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: donation-service-alerts
spec:
  groups:
    - name: donation-service
      interval: 30s
      rules:
        # ❌ Problema: sem label 'service', self-healing não funciona
        - alert: DonationHighErrorRate
          expr: rate(http_requests_total{job="donation-service",status=~"5.."}[5m]) > 0.05
          annotations:
            summary: "Donation service high error rate"
            description: "Error rate > 5%"

        # ✅ Correto: com label 'service' que o self-healing precisa
        - alert: DonationHighErrorRate
          expr: rate(http_requests_total{job="donation-service",status=~"5.."}[5m]) > 0.05
          labels:
            service: "donation-service"  # 👈 Essencial para self-healing
            severity: critical
          annotations:
            summary: "Donation service high error rate"
            description: "Error rate > 5%"
```

### Mapeamento de Serviços

| Service | Labels Válidos |
|---------|---|
| donation-service | `service: "donation-service"` ou `pod: "donation-service-*"` |
| ngo-service | `service: "ngo-service"` ou `pod: "ngo-service-*"` |
| volunteer-service | `service: "volunteer-service"` ou `pod: "volunteer-service-*"` |

## Teste End-to-End

### 1. Simular webhook do Alertmanager

```bash
# Port-forward para o self-healing-bridge
kubectl port-forward -n monitoring svc/self-healing-bridge 9095:9095 &

# Enviar webhook simulado
curl -X POST http://localhost:9095/ \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "status": "firing",
      "labels": {
        "alertname": "HighErrorRate5xx",
        "severity": "critical",
        "service": "donation-service"
      },
      "annotations": {
        "summary": "High error rate on donation-service",
        "description": "Error rate > 5% for last 5m"
      }
    }]
  }'
```

Resposta esperada:
```json
{"triggered": [{"service": "donation-service", "alert": "HighErrorRate5xx", "dispatched": true}]}
```

### 2. Ver logs do self-healing-bridge

```bash
kubectl logs -n monitoring -l app=self-healing-bridge -f
```

Procure por linhas como:
```
[OK] dispatched donation-service/HighErrorRate5xx HTTP 204
```

### 3. Verificar GitHub Actions

Vá para seu repo → Actions → "Self-Healing — Pod Recovery"

Você deve ver um novo run com status `success` ou verificar os logs:

```bash
gh run list --repo <GITHUB_USER>/TC5-ST \
  --workflow=self-healing.yaml \
  --limit=5
```

### 4. Verificar Discord

No canal #alerts, procure por:
- `🛠️ Self-Healing INICIADO` (quando o workflow começou)
- `✅ Self-Healing CONCLUIDO` (quando o rollout terminou)

## Troubleshooting

### Self-Healing não é disparado

**Problema:** Alerta é recebido mas webhook não dispara remediation

**Solução:**
1. Verifique se o label `service` está presente no alerta:
   ```bash
   # Verificar alertas no Prometheus
   # UI: http://prometheus.local/alerts
   # Procure pelo alert e confirme que tem label 'service'
   ```

2. Verifique logs do self-healing-bridge:
   ```bash
   kubectl logs -n monitoring -l app=self-healing-bridge | grep "\[WARN\]"
   ```

3. Confirme que webhook está alcançando o bridge:
   ```bash
   kubectl logs -n monitoring -l app=self-healing-bridge | grep "POST"
   ```

### GitHub token inválido

**Erro:** `[ERR] GitHub 401 for donation-service`

**Solução:**
```bash
# Atualizar token no secret
kubectl patch secret self-healing-bridge-secret -n monitoring \
  -p='{"stringData":{"GITHUB_TOKEN":"ghp_novo_token"}}'

# Reiniciar pod para pegar novo token
kubectl rollout restart deployment/self-healing-bridge -n monitoring
```

### Nenhum serviço encontrado

**Erro:** `[WARN] no service for HighErrorRate5xx labels={...}`

**Solução:**
- Adicione o label `service` ao seu PrometheusRule
- Ou adicione label `pod` que comece com o nome do serviço

### Webhook não atinge o bridge

**Erro:** Curl test funciona, mas Alertmanager não dispara

**Solução:**
1. Verificar DNS:
   ```bash
   kubectl run -it --rm debug --image=busybox --restart=Never -- \
     wget -O- http://self-healing-bridge.monitoring.svc.cluster.local:9095/
   ```

2. Verificar se o Service existe:
   ```bash
   kubectl get svc self-healing-bridge -n monitoring
   ```

3. Verificar logs do Alertmanager:
   ```bash
   kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0 -f | grep webhook
   ```

## Rotas de Alerta

Confira em `alertmanager-config.yaml`:

- **Critical** → PagerDuty + Discord + **Self-Healing Webhook**
- **Warning** → Discord apenas
- **Watchdog** → null (silenciado)

Você pode customizar quais alertas disparam self-healing editando as `routes` no ConfigMap.

## Monitorar Self-Healing

### Alertas que devem disparar auto-remediation

Estes são considerados "críticos" e tentarão auto-remediation:

- `HighErrorRate5xx` (service specific)
- `PodCrashLooping`
- `DonationSLOFastBurn` (SLO burn rate alto)
- Qualquer alerta com `severity: critical`

### Desabilitar self-healing para um alerta

Se não quer que um alerta dispare auto-remediation, **não adicione o label `service`** ou crie uma rota com `receiver: 'solidarytech-warning'`:

```yaml
routes:
  - match:
      alertname: MyNonHealing
      severity: warning
    receiver: 'solidarytech-warning'  # Sem webhook
```

## Links Úteis

- [Alertmanager Docs](https://prometheus.io/docs/alerting/latest/configuration/)
- [PrometheusRule Docs](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusrule)
- [GitHub Repository Dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch)
