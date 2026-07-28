#!/bin/bash
###############################################################################
# install-monitoring.sh
#
# Instala stack de observabilidade no cluster EKS:
#   Prometheus (kube-prometheus-stack) + Grafana + Alertmanager
#   Loki + Promtail (logs)
#   OpenTelemetry Collector (hub: traces+metrics->NR, logs->Loki, metrics->Prom)
#
# Pre-requisitos:
#   - kubectl conectado ao cluster
#   - helm 3.12+ instalado
#   - (opcional) gitops/monitoring/newrelic-secret.yaml aplicado para APM
###############################################################################
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MONITORING_DIR="$PROJECT_DIR/gitops/monitoring"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "============================================"
echo "  SolidaryTech - Monitoring Stack Installer"
echo "============================================"
echo ""

# -------------------------------------------------------
# 1. Namespace + secret grafana-admin (password random)
# -------------------------------------------------------
log_info "[1/6] Garantindo namespace monitoring + secret grafana-admin..."
kubectl apply -f "$MONITORING_DIR/namespace.yaml"

# Gera password random apenas na 1a vez (preserva entre installs)
if ! kubectl get secret grafana-admin -n monitoring > /dev/null 2>&1; then
    GRAFANA_PASS=$(openssl rand -base64 24 | tr -d '=+/' | head -c 24)
    kubectl create secret generic grafana-admin \
        --namespace monitoring \
        --from-literal=admin-user=admin \
        --from-literal=admin-password="$GRAFANA_PASS"
    log_ok "Secret grafana-admin criado (password random 24 chars)"
else
    log_ok "Secret grafana-admin ja existe (password preservada)"
fi

# -------------------------------------------------------
# 2. Helm repos
# -------------------------------------------------------
log_info "[2/6] Adicionando Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null
helm repo add grafana https://grafana.github.io/helm-charts > /dev/null
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts > /dev/null
helm repo update > /dev/null
log_ok "Repos atualizados"

# -------------------------------------------------------
# 3. kube-prometheus-stack
# -------------------------------------------------------
log_info "[3/6] Instalando kube-prometheus-stack (Prometheus + Grafana + Alertmanager)..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values "$MONITORING_DIR/prometheus/values.yaml" \
    --wait --timeout 10m

# -------------------------------------------------------
# 4. Loki
# -------------------------------------------------------
log_info "[4/6] Instalando Loki..."
helm upgrade --install loki grafana/loki \
    --namespace monitoring \
    --values "$MONITORING_DIR/loki/values.yaml" \
    --wait --timeout 10m

# -------------------------------------------------------
# 5. Promtail
# -------------------------------------------------------
log_info "[5/6] Instalando Promtail..."
helm upgrade --install promtail grafana/promtail \
    --namespace monitoring \
    --values "$MONITORING_DIR/promtail/values.yaml" \
    --wait --timeout 5m

# -------------------------------------------------------
# 6. OTel Collector
# -------------------------------------------------------
log_info "[6/6] Instalando OpenTelemetry Collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace monitoring \
    --values "$MONITORING_DIR/otel-collector/values.yaml" \
    --wait --timeout 5m

echo ""
log_ok "Stack instalada"

# -------------------------------------------------------
# Aplicar Alertmanager config
# -------------------------------------------------------
if [ -f "$MONITORING_DIR/alerting/alertmanager-config.yaml" ]; then
    log_info "Aplicando configuração do Alertmanager..."
    kubectl apply -f "$MONITORING_DIR/alerting/alertmanager-config.yaml"
    log_ok "Alertmanager config aplicada"
fi

# -------------------------------------------------------
# Aplicar PrometheusRules customizadas (SLO + Hot Path)
# -------------------------------------------------------
if [ -f "$MONITORING_DIR/alerting/prometheus-rules.yaml" ]; then
    log_info "Aplicando PrometheusRules customizadas..."
    kubectl apply -f "$MONITORING_DIR/alerting/prometheus-rules.yaml"
    log_ok "Alertas SLO+pods+resources aplicados"
fi

# -------------------------------------------------------
# Dashboard customizado (agora é um ConfigMap YAML)
# -------------------------------------------------------
DASHBOARD_FILE="$MONITORING_DIR/grafana/dashboards/configmap.yaml"
if [ -f "$DASHBOARD_FILE" ]; then
    log_info "Carregando dashboard Grafana customizado..."
    kubectl apply -f "$DASHBOARD_FILE"
    log_ok "Dashboard aplicado"
fi

echo ""
echo "============================================"
echo "  Acessos"
echo "============================================"
GRAFANA_URL=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pendente")
echo ""
echo "Grafana:"
echo "  URL:  http://$GRAFANA_URL"
echo "  User: admin"
echo "  Pass: kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
echo "OTel Collector (endpoint para os microsservicos):"
echo "  gRPC: otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317"
echo "  HTTP: otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318"
echo ""
# -------------------------------------------------------
# New Relic Secret (APM)
# -------------------------------------------------------
NEWRELIC_SECRET_FILE="$MONITORING_DIR/newrelic-secret.yaml"
if [ -f "$NEWRELIC_SECRET_FILE" ]; then
    log_info "Aplicando New Relic secret..."
    kubectl apply -f "$NEWRELIC_SECRET_FILE"
    log_ok "New Relic secret aplicado"
else
    log_warn "New Relic secret NAO encontrado — distributed tracing desativado"
    echo "  Para ativar New Relic APM:"
    echo "    cp gitops/monitoring/newrelic-secret.yaml.example gitops/monitoring/newrelic-secret.yaml"
    echo "    # editar com sua license-key"
    echo "    ./scripts/install-monitoring.sh  (ou helm upgrade otel-collector)"
fi
