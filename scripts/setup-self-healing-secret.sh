#!/bin/bash
###############################################################################
# setup-self-healing-secret.sh
#
# Configura o GitHub PAT token para o self-healing-bridge:
#
# 1. Se rodando em GitHub Actions: cria secret Kubernetes do GitHub Secret
# 2. Se rodando localmente: pede ao usuário para criar/fornecer o token
#
# Pre-requisitos:
#   - kubectl conectado ao cluster
#   - gh CLI instalado (para modo interativo)
#   - GitHub PAT fine-grained com Actions: write permission
###############################################################################
set -e
set -o pipefail

NAMESPACE="monitoring"
SECRET_NAME="self-healing-bridge-secret"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERR]${NC} $1"; }

echo "============================================"
echo "  Self-Healing Bridge — Secret Setup"
echo "============================================"
echo ""

# -------------------------------------------------------
# Detectar ambiente (GitHub Actions vs local)
# -------------------------------------------------------
if [ -n "$GITHUB_ACTIONS" ]; then
    # Modo: GitHub Actions
    log_info "Detectado: GitHub Actions"

    if [ -z "$PAT_TOKEN_SELF_HEALING" ]; then
        log_err "GitHub Secret 'PAT_TOKEN_SELF_HEALING' NAO encontrado!"
        log_err "Configure em: Settings → Secrets and variables → Actions → New repository secret"
        log_err "Nome: PAT_TOKEN_SELF_HEALING"
        log_err "Valor: seu token fine-grained (ghp_...)"
        log_err ""
        log_err "⚠️  NOTA: Não pode começar com GITHUB_ (reservado pelo GitHub Actions)"
        exit 1
    fi

    # Verificar se secret já existe
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
        log_warn "Secret já existe. Atualizando..."
        kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
    fi

    # Criar secret a partir do GitHub Secret
    kubectl create secret generic "$SECRET_NAME" \
        --from-literal=GITHUB_TOKEN="$GITHUB_PAT_TOKEN" \
        -n "$NAMESPACE"

    log_ok "Secret criado a partir de GitHub Secret (GITHUB_PAT_TOKEN)"

else
    # Modo: Local/Manual
    log_info "Detectado: Execução local"

    # Verificar se secret já existe
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
        log_warn "Secret já existe!"
        read -p "Deseja atualizar? (s/n): " -r
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_info "Cancelado"
            exit 0
        fi
        kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
    fi

    # Opção 1: Usar variável de ambiente
    if [ -n "$PAT_TOKEN_SELF_HEALING" ]; then
        log_info "Usando PAT_TOKEN_SELF_HEALING da variável de ambiente"
        TOKEN="$PAT_TOKEN_SELF_HEALING"
    else
        # Opção 2: Pedir ao usuário
        echo ""
        echo "Como deseja fornecer o token?"
        echo "1) Colar token diretamente"
        echo "2) Ler de arquivo"
        echo "3) Usar gh CLI para gerar"
        read -p "Escolha (1-3): " choice

        case $choice in
            1)
                read -sp "Cole seu GitHub PAT token (fine-grained): " TOKEN
                echo ""
                ;;
            2)
                read -p "Caminho do arquivo com token: " token_file
                if [ ! -f "$token_file" ]; then
                    log_err "Arquivo NAO encontrado: $token_file"
                    exit 1
                fi
                TOKEN=$(cat "$token_file" | tr -d '\n')
                ;;
            3)
                if ! command -v gh &> /dev/null; then
                    log_err "gh CLI NAO instalado"
                    log_info "Instale: https://cli.github.com/"
                    exit 1
                fi
                log_info "Abrindo GitHub para criar token..."
                gh auth token | head -1 > /dev/null 2>&1 || {
                    log_err "NAO autenticado no GitHub. Execute: gh auth login"
                    exit 1
                }
                log_warn "Crie um fine-grained PAT manualmente em:"
                log_warn "  https://github.com/settings/tokens?type=beta"
                echo ""
                read -sp "Cole seu GitHub PAT token (fine-grained): " TOKEN
                echo ""
                ;;
            *)
                log_err "Opção inválida"
                exit 1
                ;;
        esac
    fi

    # Validar formato do token
    if [[ ! $TOKEN =~ ^ghp_ ]]; then
        log_err "Token inválido! Deve começar com 'ghp_'"
        log_info "Certifique-se de usar um fine-grained PAT (beta)"
        exit 1
    fi

    # Criar secret
    kubectl create secret generic "$SECRET_NAME" \
        --from-literal=GITHUB_TOKEN="$TOKEN" \
        -n "$NAMESPACE"

    log_ok "Secret criado com sucesso"
fi

echo ""
# -------------------------------------------------------
# Verificar se secret foi criado
# -------------------------------------------------------
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    log_ok "Secret '$SECRET_NAME' existe no namespace '$NAMESPACE'"

    # Mostrar tamanho do token (não o conteúdo)
    TOKEN_SIZE=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.GITHUB_TOKEN}' | base64 -d | wc -c)
    log_ok "Token armazenado: $TOKEN_SIZE bytes"
else
    log_err "Falha ao criar secret!"
    exit 1
fi

echo ""
# -------------------------------------------------------
# Próximos passos
# -------------------------------------------------------
echo "============================================"
echo "  ✅ Setup Completo"
echo "============================================"
echo ""
echo "Próximos passos:"
echo "  1. Deploy self-healing-bridge:"
echo "     kubectl apply -f gitops/monitoring/self-healing-bridge/deployment.yaml"
echo ""
echo "  2. Verificar logs:"
echo "     kubectl logs -n monitoring -l app=self-healing-bridge -f"
echo ""
echo "  3. Testar webhook:"
echo "     kubectl port-forward -n monitoring svc/self-healing-bridge 9095:9095 &"
echo "     curl -X POST http://localhost:9095/ \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"alerts\": [{\"status\": \"firing\", \"labels\": {\"alertname\": \"Test\", \"service\": \"donation-service\"}}]}'"
echo ""
