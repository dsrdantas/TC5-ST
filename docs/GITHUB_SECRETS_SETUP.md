# GitHub Secrets Setup — Self-Healing Bridge

Este documento explica como configurar o GitHub Secret `PAT_TOKEN_SELF_HEALING` necessário para o self-healing-bridge automatizar o `repository_dispatch` do GitHub Actions.

## 📋 O que é o GitHub PAT Token?

Um **Personal Access Token (PAT)** é um token de autenticação que:
- Permite ao self-healing-bridge disparar workflows do GitHub Actions
- Usa permissão fine-grained "Actions: write"
- É mais seguro que colocar a senha do GitHub em plain text

## 🚀 Passo 1: Criar o Fine-Grained PAT Token

### 1.1 Ir para GitHub Settings

```
https://github.com/settings/tokens?type=beta
```

Ou via UI:
- GitHub → Settings (canto superior direito)
- Developer settings (sidebar)
- Personal access tokens (expandir)
- Fine-grained tokens

### 1.2 Clique em "Generate new token"

Preencha:
- **Token name**: `TC5-ST-SelfHealing` (ou similar)
- **Expiration**: 90 days (ou conforme sua política)
- **Repository access**: Selecione seu repo (`seu-usuario/TC5-ST`)

### 1.3 Configurar Permissions

Procure por **"Actions"** e marque:
- ✅ **Actions: write** (para disparar `repository_dispatch`)

Pode deixar tudo mais restritivo assim. Outras permissões não são necessárias.

### 1.4 Gerar e Copiar

- Clique "Generate token"
- **Copie o token imediatamente** (formato: `ghp_xxxxxxxxx...`)
- Não feche a página sem copiar — você só vê uma vez!

## 🔐 Passo 2: Adicionar GitHub Secret ao Repositório

### 2.1 Ir para Settings → Secrets

```
https://github.com/seu-usuario/TC5-ST/settings/secrets/actions
```

Ou via UI:
- Repository → Settings (aba)
- Secrets and variables (sidebar)
- Actions

### 2.2 Criar novo Secret

- Clique "New repository secret"
- **Name**: `PAT_TOKEN_SELF_HEALING`
- **Secret**: Cole o token que copiou (começa com `ghp_`)

### 2.3 Salvar

- Clique "Add secret"
- Confirmado ✅

## ✅ Passo 3: Testar

### 3.1 Via GitHub Actions

1. Dispare o workflow: Settings → Actions → "Deploy - SolidaryTech Full Stack"
2. Clique "Run workflow" → "Run workflow"
3. Monitore os logs do job "Setup Self-Healing Bridge Secret"
   - Deve mostrar: `✅ Secret 'self-healing-bridge-secret' existe no namespace 'monitoring'`

### 3.2 Verificar no Cluster

```bash
kubectl get secret self-healing-bridge-secret -n monitoring
kubectl get secret self-healing-bridge-secret -n monitoring -o jsonpath='{.data.GITHUB_TOKEN}' | base64 -d | head -c 10
# Deve mostrar: ghp_xxxxx...
```

### 3.3 Teste Manual (Local)

Se estiver rodando localmente:

```bash
# Executar script de setup (pede token interativo)
./scripts/setup-self-healing-secret.sh

# Verificar secret foi criado
kubectl get secret self-healing-bridge-secret -n monitoring -o jsonpath='{.data.GITHUB_TOKEN}' | base64 -d | wc -c
# Deve mostrar: ~100 (tamanho do token)
```

## 🔄 Usar o Secret no Workflow

No workflow, acesse assim:

```yaml
env:
  PAT_TOKEN_SELF_HEALING: ${{ secrets.PAT_TOKEN_SELF_HEALING }}
run: |
  # Token está disponível em $PAT_TOKEN_SELF_HEALING
  ./scripts/setup-self-healing-secret.sh
```

## 🛡️ Boas Práticas

### ✅ Faça

- ✅ Use fine-grained tokens (não classic)
- ✅ Defina expiração (90 dias recomendado)
- ✅ Limite a repo específica (`TC5-ST`)
- ✅ Limite a permissão mínima necessária (`Actions: write`)
- ✅ Rotacione o token periodicamente
- ✅ Revogue tokens antigos depois de gerar novos

### ❌ Não Faça

- ❌ Não use classic PAT (menos seguro)
- ❌ Não compartilhe o token em chat/email
- ❌ Não commite o token no git
- ❌ Não dê permissões extras desnecessárias
- ❌ Não deixe expiração indefinida

## 🔄 Rotacionar Token (após expirar)

1. Ir para https://github.com/settings/tokens?type=beta
2. Encontre o token expirado
3. Clique "Regenerate"
4. Copie o novo token
5. Volte para Settings → Secrets
6. Clique no secret `PAT_TOKEN_SELF_HEALING`
7. Clique "Update"
8. Cole o novo token

## 🚨 Troubleshooting

### Erro: "PAT_TOKEN_SELF_HEALING secret not configured"

```
⚠️  PAT_TOKEN_SELF_HEALING secret not configured
   Set it in: Settings → Secrets and variables → Actions → New repository secret
```

**Solução:**
- Ir para: `https://github.com/seu-usuario/TC5-ST/settings/secrets/actions`
- Criar novo secret chamado `PAT_TOKEN_SELF_HEALING`
- Colar o fine-grained PAT token (começa com `ghp_`)

### Erro: "[ERR] GitHub 401 for donation-service"

**Significa:** Token é inválido ou expirou

**Solução:**
1. Verificar se token não expirou em https://github.com/settings/tokens?type=beta
2. Se expirou, regenerar (veja seção "Rotacionar Token")
3. Atualizar o secret no repositório

### Erro: "[ERR] GitHub 403 for donation-service"

**Significa:** Token não tem permissão "Actions: write"

**Solução:**
1. Ir para https://github.com/settings/tokens?type=beta
2. Clicar no token usado
3. Verificar "Permissions" → "Actions: write" está ✅
4. Se não tiver, editar token e adicionar permissão

### Erro: Token ainda funciona mas secret não é criado

**Significa:** Namespace `monitoring` não existe

**Solução:**
```bash
# Criar namespace
kubectl create namespace monitoring
kubectl label namespace monitoring app.kubernetes.io/part-of=solidarytech
```

## 📚 Links Úteis

- [GitHub Fine-Grained PAT Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Repository Dispatch Event](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch)
- [Self-Healing Bridge README](../gitops/monitoring/self-healing-bridge/README.md)
- [Self-Healing Setup Guide](../gitops/monitoring/alerting/SELF-HEALING-SETUP.md)

## ❓ FAQs

**P: Posso usar um classic PAT?**
A: Tecnicamente sim, mas não é recomendado. Fine-grained são mais seguros.

**P: O que acontece se o token expirar?**
A: Self-healing deixa de funcionar. Workflow vai falhar com erro 401.

**P: Preciso dar mais permissões?**
A: Não, apenas "Actions: write" é necessário para `repository_dispatch`.

**P: Posso usar o token em múltiplos repos?**
A: Cada fine-grained PAT é específico para uma repo. Se precisar de múltiplos repos, crie tokens separados.

**P: E se quiser compartilhar com a equipe?**
A: Use um organization-wide secret em vez de repository secret. Vá para organization → Settings → Secrets and variables → Actions.
