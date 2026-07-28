# 🚀 Deployment Guide — Passo-a-Passo

Guia completo para provisionar o ambiente SolidaryTech em AWS EKS.

---

## 📋 Pré-requisitos

### 1. AWS Academy Credentials

Obtenha credenciais válidas de uma sessão AWS Academy (4h):

```bash
# Defina as variáveis de ambiente
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"

# Valide as credenciais
aws sts get-caller-identity
# Output: Account ID, ARN, UserID
```

### 2. GitHub Setup

- Fork/clone: https://github.com/dsrdantas/TC5-ST
- Configure secrets em **Settings → Secrets and variables → Actions**:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

### 3. Variáveis Terraform

Crie `terraform/environments/primary/terraform.tfvars`:

```hcl
project_name        = "solidarytech"
aws_region          = "us-east-1"
db_username         = "solidary"
db_password         = "YourSecurePassword123!"  # NUNCA commitar!
kubernetes_version  = "1.31"  # Via: aws eks describe-cluster-versions
postgres_version    = "16.4"  # Via: aws rds describe-db-engine-versions
repository          = "YOUR_GITHUB_USER/TC5-ST"
lab_role_arn        = "arn:aws:iam::ACCOUNT_ID:role/LabRole"
node_desired_size   = 2
azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

**Como descobrir valores:**

```bash
# Kubernetes versions
aws eks describe-cluster-versions --region us-east-1 \
  --query 'clusterVersions[].version' | head -5

# PostgreSQL versions
aws rds describe-db-engine-versions --engine postgres \
  --region us-east-1 \
  --query 'DBEngineVersions[].EngineVersion' | head -5

# Account ID
aws sts get-caller-identity --query Account --output text
```

---

## 🎯 Deployment via GitHub Actions (Recomendado)

### Opção 1: Trigger Automático

```bash
# Push para a branch deploy/main
git checkout -b deploy/main
git push origin deploy/main

# Workflow `setup-full-workflow` dispara automaticamente
# Acompanhe em: Actions → Setup Full Stack
```

### Opção 2: Trigger Manual

1. Vá para **Actions** → **Setup Full Stack**
2. Clique **Run workflow**
3. Marque o checkbox **"Skip terraform plan confirmation"** (auto_approve)
4. Clique **Run workflow**

### O workflow vai:

```
1. Pré-flight checks (fmt, validate, docker)
   ↓
2. Build & push de imagens ECR
   ↓
3. Terraform plan/apply (infrastructure)
   ↓
4. Gera & aplica secrets Kubernetes
   ↓
5. Instala Monitoring Stack (Prometheus, Grafana, Loki, OTEL)
   ↓
6. Deploy aplicações via ArgoCD
   ↓
7. Relatório com URLs de acesso
```

**Tempo total: 20-30 minutos**

---

## 📊 Acompanhar o Deploy

### 1. Checar logs do workflow

- Github → Actions → Setup Full Stack → latest run
- Acompanhe em tempo real

### 2. Verificar recursos AWS

```bash
# EKS Cluster
aws eks describe-cluster --name solidarytech-cluster --region us-east-1

# RDS Database
aws rds describe-db-instances --db-instance-identifier solidarytech-donation-db

# LoadBalancers criados
aws elbv2 describe-load-balancers --region us-east-1
```

### 3. Conectar ao cluster

```bash
# Configurar kubectl
aws eks update-kubeconfig --name solidarytech-cluster --region us-east-1

# Verificar pods
kubectl get pods -n solidarytech
kubectl get pods -n monitoring

# Ver logs
kubectl logs -n solidarytech deployment/donation-service -f
```

---

## 🌐 Acessar as UIs

Após o deploy, o workflow vai exibir os LoadBalancers. Exemplo:

```
- ArgoCD: https://abc123.elb.us-east-1.amazonaws.com (user: admin)
- Grafana: http://xyz789.elb.us-east-1.amazonaws.com (user: admin)
- Ingress: http://ingress-lb.elb.us-east-1.amazonaws.com
```

### Obter senhas

```bash
# ArgoCD (admin user)
argocd admin initial-password -n argocd

# Grafana
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d

# New Relic (se configurado)
kubectl get secret newrelic-license-key -n monitoring -o jsonpath='{.data.license-key}'
```

---

## ✅ Validar o Deployment

### 1. Verificar aplicações rodando

```bash
# Todos os pods devem estar Running
kubectl get pods -n solidarytech

# Esperado:
# NAME                               READY   STATUS
# donation-service-xxx               3/3     Running
# ngo-service-xxx                    3/3     Running
# volunteer-service-xxx              3/3     Running
```

### 2. Testar endpoints

```bash
# Obter ingress URL
INGRESS_LB=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Testar health check
curl http://$INGRESS_LB/donations/health

# Testar API
curl -X POST http://$INGRESS_LB/donations \
  -H "Content-Type: application/json" \
  -d '{"amount": 50, "donor_id": "test"}'
```

### 3. Verificar métricas

- Abra Grafana
- Dashboard → SolidaryTech → Overview
- Verifique:
  - CPU/Memory usage
  - HTTP Request Rate
  - Error Rate (deve estar 0%)
  - Latency P95

### 4. Verificar observabilidade

```bash
# Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Acesse: http://localhost:9090/targets

# Loki logs
kubectl port-forward -n monitoring svc/loki 3100:3100
# Query via Grafana → Explore → Loki
```

---

## 🚨 Troubleshooting

### Pods não estão rodando

```bash
# Ver status detalhado
kubectl describe pod -n solidarytech deployment/donation-service

# Ver logs de erro
kubectl logs -n solidarytech deployment/donation-service --previous
```

### LoadBalancer pending

```bash
# ALB leva ~2-3 minutos para provisionar
# Aguarde mais um pouco

# Ver status
kubectl get svc -A
# Se EXTERNAL-IP = <pending>, ainda inicializando
```

### Erro: "No space left on device"

```bash
# Clean up local Docker images (runner)
docker system prune -a
```

### Terraform error: "Module not installed"

```bash
# Solução aplicada no workflow, mas se rodar local:
terraform init -backend=false
terraform validate
```

### DB init jobs rodando múltiplas vezes

```bash
# Jobs foram corrigidos para:
# - Verificar se schema já existe (idempotência)
# - ttlSecondsAfterFinished: 86400 (24h, não 5min)
# - parallelism: 1, completions: 1 (garantia de execução única)

# Se ainda houver problema, deletar job antigo:
kubectl delete job donation-db-init -n solidarytech
kubectl delete job ngo-db-init -n solidarytech

# ArgoCD vai recriá-lo (mas desta vez com idempotência)
```

---

## 🔧 Customizações Comuns

### Mudar número de nodes

```hcl
# terraform/environments/primary/terraform.tfvars
node_desired_size = 3  # Default é 2
```

### Ativar New Relic APM

```bash
# 1. Crie um secret com sua license key
kubectl create secret generic newrelic-license-key \
  --namespace monitoring \
  --from-literal=license-key="YOUR_LICENSE_KEY"

# 2. Redeploy OTEL Collector
helm upgrade otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --values gitops/monitoring/otel-collector/values.yaml
```

### Configurar Alertmanager com Discord

Edite `gitops/monitoring/alerting/alertmanager-config.yaml` com seu webhook.

---

## 📋 Checklist de Validação

- [ ] AWS credentials válidas (4h token)
- [ ] GitHub secrets configurados
- [ ] terraform.tfvars preenchido
- [ ] Workflow disparado e aguardando
- [ ] Pods rodando (kubectl get pods -A)
- [ ] Grafana acessível e mostrando métricas
- [ ] ArgoCD sincronizado
- [ ] API health check respondendo
- [ ] Logs visíveis em Loki
- [ ] Alertmanager online

---

## 🤖 Auto-Healing (Opcional)

Para ativar auto-recovery de pods em caso de erro crítico:

```bash
# 1. Gerar GitHub PAT
# → https://github.com/settings/tokens/new
# Escopo: repo
# Expiration: 90 dias

# 2. Criar secret no cluster
kubectl create secret generic github-webhook-token \
  --namespace monitoring \
  --from-literal=token="ghp_seu_token_aqui"

# 3. Webhook receiver já está em gitops/monitoring/alerting/webhook-receiver.yaml
# ArgoCD sincroniza automaticamente

# 4. Testar (opcional)
gh workflow run self-healing.yaml \
  --repo dsrdantas/TC5-ST \
  -f service=donation-service \
  -f reason="Test"
```

**Quando dispara:**
- `PodCrashLooping` — >3 restarts em 15min
- `HighErrorRate5xx` — >5% de erros em 2min
- `DonationSLOFastBurn` — Error budget queimando rápido

**Status:**
- ✅ **CONCLUÍDO**: Pod restart bem-sucedido (Discord notificado)
- ❌ **FALHOU**: Escalação para on-call (Discord + PagerDuty)

Ver [SELF-HEALING-SETUP.md](SELF-HEALING-SETUP.md) para detalhes completos.

---

## 🛑 Cleanup (Destruir Ambiente)

Quando terminar e quiser destruir tudo:

```bash
# Via GitHub Actions (recomendado)
# Actions → Destroy Environment
# - Environment: primary (ou dr, ou both)
# - Confirmation: digitar "DESTROY"

# Ou manual (se rodar local)
cd terraform/environments/primary
terraform destroy -auto-approve
```

**⚠️ Isso vai:**
- Deletar EKS cluster
- Deletar RDS database
- Liberar Elastic IPs
- Remover subnets e VPC
- **Tudo vai ser deletado permanentemente**

---

## 📞 Suporte

Se tiver problemas:

1. Verifique [troubleshooting](ITSM-LIFECYCLE.md) runbooks
2. Cheque logs do workflow: GitHub → Actions
3. Verifique credenciais AWS: `aws sts get-caller-identity`
4. Leia [DR-STRATEGY.md](DR-STRATEGY.md) se for failover

Boa sorte! 🚀
