#!/bin/bash
###############################################################################
# cleanup-aws-dependencies.sh
#
# Limpa dependências que impedem destroy do Terraform:
# - Elastic IPs não desanexadas
# - ENIs (Network Interfaces) órfãs
# - Load Balancers em subnets
# - Instâncias EC2 ainda rodando
# - NAT Gateways
#
# Pre-requisitos:
#   - AWS CLI instalado
#   - Credenciais AWS configuradas
#   - Cluster/VPC específica já identificada
###############################################################################
set -e
set -o pipefail

REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${1:-solidarytech-cluster}"

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
echo "  AWS Dependencies Cleanup"
echo "============================================"
echo "Region: $REGION"
echo "Cluster: $CLUSTER_NAME"
echo ""

# -------------------------------------------------------
# 1. Encontrar VPC associada ao cluster
# -------------------------------------------------------
log_info "Procurando VPC do cluster '$CLUSTER_NAME'..."

VPC_ID=$(aws ec2 describe-vpcs \
    --region "$REGION" \
    --filters "Name=tag:Name,Values=$CLUSTER_NAME" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || echo "")

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
    log_warn "VPC não encontrada com tag Name=$CLUSTER_NAME"
    log_info "Listando VPCs disponíveis:"
    aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output text
    read -p "Digite o VPC ID: " VPC_ID
fi

if [ -z "$VPC_ID" ]; then
    log_err "VPC ID não fornecido"
    exit 1
fi

log_ok "VPC encontrada: $VPC_ID"
echo ""

# -------------------------------------------------------
# 2. Liberar Elastic IPs
# -------------------------------------------------------
log_info "[1/6] Liberando Elastic IPs não associadas..."

ALLOCATION_IDS=$(aws ec2 describe-addresses \
    --region "$REGION" \
    --filters "Name=domain,Values=vpc" \
    --query "Addresses[?AssociationId==null].AllocationId" \
    --output text)

if [ -n "$ALLOCATION_IDS" ]; then
    for AID in $ALLOCATION_IDS; do
        log_warn "Liberando EIP: $AID"
        aws ec2 release-address --allocation-id "$AID" --region "$REGION" || log_warn "Falha ao liberar $AID"
    done
    log_ok "EIPs liberadas"
else
    log_ok "Nenhuma EIP órfã encontrada"
fi
echo ""

# -------------------------------------------------------
# 3. Remover Network Interfaces órfãs
# -------------------------------------------------------
log_info "[2/6] Removendo Network Interfaces (ENIs) órfãs..."

ENI_IDS=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=status,Values=available" \
    --query "NetworkInterfaces[].NetworkInterfaceId" \
    --output text)

if [ -n "$ENI_IDS" ]; then
    for ENI in $ENI_IDS; do
        log_warn "Deletando ENI: $ENI"
        aws ec2 delete-network-interface --network-interface-id "$ENI" --region "$REGION" || log_warn "Falha ao deletar ENI $ENI"
    done
    log_ok "ENIs órfãs removidas"
else
    log_ok "Nenhuma ENI órfã encontrada"
fi
echo ""

# -------------------------------------------------------
# 4. Parar/Terminar instâncias EC2
# -------------------------------------------------------
log_info "[3/6] Terminando instâncias EC2 na VPC..."

INSTANCE_IDS=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    for IID in $INSTANCE_IDS; do
        log_warn "Terminando instância: $IID"
        aws ec2 terminate-instances --instance-ids "$IID" --region "$REGION" || log_warn "Falha ao terminar $IID"
    done
    log_info "Aguardando término de instâncias..."
    aws ec2 wait instance-terminated \
        --instance-ids $INSTANCE_IDS \
        --region "$REGION" || log_warn "Timeout ao aguardar término"
    log_ok "Instâncias EC2 terminadas"
else
    log_ok "Nenhuma instância EC2 ativa encontrada"
fi
echo ""

# -------------------------------------------------------
# 5. Remover Load Balancers (ALB/NLB)
# -------------------------------------------------------
log_info "[4/6] Removendo Load Balancers..."

# ALB/NLB
ALB_ARNS=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
    --output text)

if [ -n "$ALB_ARNS" ]; then
    for ARN in $ALB_ARNS; do
        LB_NAME=$(echo $ARN | awk -F':' '{print $NF}')
        log_warn "Deletando Load Balancer: $LB_NAME"
        aws elbv2 delete-load-balancer --load-balancer-arn "$ARN" --region "$REGION" || log_warn "Falha ao deletar LB"
    done
    log_ok "Load Balancers (ALB/NLB) removidos"
else
    log_ok "Nenhum Load Balancer encontrado"
fi
echo ""

# -------------------------------------------------------
# 6. Remover NAT Gateways
# -------------------------------------------------------
log_info "[5/6] Removendo NAT Gateways..."

NAT_GW_IDS=$(aws ec2 describe-nat-gateways \
    --region "$REGION" \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query "NatGateways[].NatGatewayId" \
    --output text)

if [ -n "$NAT_GW_IDS" ]; then
    for NGID in $NAT_GW_IDS; do
        log_warn "Deletando NAT Gateway: $NGID"
        aws ec2 delete-nat-gateway --nat-gateway-id "$NGID" --region "$REGION" || log_warn "Falha ao deletar NAT GW"
    done
    log_info "Aguardando deleção de NAT Gateways (max 2min)..."
    sleep 30  # NAT GW leva tempo para deletar
    log_ok "NAT Gateways removidos"
else
    log_ok "Nenhum NAT Gateway encontrado"
fi
echo ""

# -------------------------------------------------------
# 7. Resumo de status
# -------------------------------------------------------
log_info "[6/6] Verificando status final..."
echo ""

# Verificar EIPs restantes
EIP_COUNT=$(aws ec2 describe-addresses \
    --region "$REGION" \
    --query "length(Addresses)" \
    --output text)

# Verificar ENIs na VPC
ENI_COUNT=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "length(NetworkInterfaces)" \
    --output text)

# Verificar instâncias ativas
INSTANCE_COUNT=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" \
    --query "length(Reservations[].Instances[])" \
    --output text)

# Verificar IGWs
IGW_COUNT=$(aws ec2 describe-internet-gateways \
    --region "$REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "length(InternetGateways)" \
    --output text)

echo "============================================"
echo "  Status Final"
echo "============================================"
echo "Elastic IPs: $EIP_COUNT"
echo "Network Interfaces na VPC: $ENI_COUNT"
echo "Instâncias EC2 ativas: $INSTANCE_COUNT"
echo "Internet Gateways: $IGW_COUNT"
echo ""

if [ "$INSTANCE_COUNT" -eq 0 ] && [ "$ENI_COUNT" -eq 0 ]; then
    log_ok "✅ Dependências limpas! Agora é seguro rodar terraform destroy"
    echo ""
    echo "Próximo passo:"
    echo "  cd terraform/environments/primary"
    echo "  terraform destroy -auto-approve"
else
    log_warn "⚠️  Ainda há dependências na VPC"
    log_warn "Pode ser necessário limpar manualmente ou aguardar mais tempo"
    echo ""
    echo "Para investigar manualmente:"
    echo "  aws ec2 describe-instances --region $REGION --filters \"Name=vpc-id,Values=$VPC_ID\" --query 'Reservations[].Instances[].InstanceId'"
    echo "  aws ec2 describe-network-interfaces --region $REGION --filters \"Name=vpc-id,Values=$VPC_ID\" --query 'NetworkInterfaces[].NetworkInterfaceId'"
fi
