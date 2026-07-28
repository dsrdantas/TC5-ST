# 🎤 Roteiro Completo — Pitch SolidaryTech

> **Duração Total:** 15-20 minutos  
> **Formato:** 1 apresentador principal + screen share + voz  
> **Ferramentas:** PDF slides + links prontos  
> **Públoalbvo:** Diretoria da ONG + banca avaliadora

---

## ⏱️ Timeline Geral

| Seção | Tempo | Tempo Acumulado |
|-------|-------|-----------------|
| **Abertura** | 1 min | 1 min |
| **Problema & Contexto** | 2 min | 3 min |
| **Solução (Arquitetura)** | 2 min | 5 min |
| **SRE** | 2 min | 7 min |
| **FinOps** | 2 min | 9 min |
| **DR (Segurança)** | 2 min | 11 min |
| **ITSM/AIOps** | 1 min | 12 min |
| **Demo (Screenshots)** | 6-7 min | 18-19 min |
| **Conclusão & ROI** | 1-2 min | 20 min |

---

## 🎯 SEÇÃO 1: ABERTURA (1 minuto)

### O Que Dizer

> "Olá, somos o grupo **Daniel e Thiago** da FIAP Pós-Tech DevOps.  
> Hoje apresentamos a **SolidaryTech** — uma plataforma que conecta ONGs a doadores e voluntários em todo o Brasil.
>
> Nos próximos 20 minutos, mostraremos como construímos uma infraestrutura preparada para **escalar, sobreviver a desastres e operar com custo controlado**.
>
> Tudo que vamos mostrar está funcionando **de verdade** — não é teoria."

### Visual
- **Slide 1 (CAPA):** Logo + Título + Equipe  
- Deixar visível: Links do repositório e vídeo

### Dica
- Tome uma respiração, fale devagar
- Faça contato visual com a banca
- Apresente a equipe com confiança

---

## 🔴 SEÇÃO 2: PROBLEMA & CONTEXTO (2 minutos)

### O Que Dizer

> "**Hoje, o desafio das ONGs é claro:**
>
> As doações chegam por SMS e email — levam 1 a 2 dias para processar.  
> Não há transparência — o doador não sabe aonde foi seu dinheiro.  
> Não há rastreabilidade — faltam dados para melhorar."

**Pausa para ênfase**

> "**O impacto disso?**
> 
> Perda de doadores. Desconfiança.  
> Oportunidades perdidas de receita recorrente.  
> Impossível escalar quando a demanda cresce."

### Visual
- **Slide 2 (Visão Geral):** Problema + Impacto  
- Deixar visível o texto de "Problema"

### Dica
- Use voz com emoção — isso é real
- Relate a urgência: "1-2 dias" é inaceitável no século 21

---

## 🟢 SEÇÃO 3: SOLUÇÃO & ARQUITETURA (2 minutos)

### O Que Dizer

> "**Nossa solução: uma plataforma digital moderna.**
>
> 3 microsserviços independentes:
> - **NGO Service** (Python/Flask) — cadastro de ONGs
> - **Donation Service** (Go) — processamento de doações (**Hot Path** crítico)
> - **Volunteer Service** (Python) — engajar voluntários
>
> Tudo rodando em **Kubernetes na AWS**, com observabilidade completa desde o início."

**Pausa**

> "Mas aqui está a diferença: não é só infraestrutura bonita. É infraestrutura **resiliente, observável e barata**."

### Visual
- **Slide 3 (Arquitetura):** Stack Tecnológico  
- Point para cada tecnologia:
  - Frontend (React/Vue)
  - APIs (NGINX)
  - Microsserviços (ngo, donation, volunteer)
  - Kubernetes (EKS)
  - Bancos (PostgreSQL, DynamoDB)
  - GitOps (ArgoCD)
  - Observabilidade (Prometheus, Grafana, New Relic)
  - CI/CD (GitHub Actions)
  - IaC (Terraform)

### Dica
- Não entre em detalhes técnicos aqui — é pitch, não tech talk
- Foque no "por quê" escolhemos cada tecnologia

---

## 📊 SEÇÃO 4: SRE (2 minutos)

### O Que Dizer

> "**Requisito #1: Confiabilidade (SRE)**
>
> Doações não podem parar. Ponto.
>
> Por isso estabelecemos um SLO formal:
> - **99.9% de disponibilidade** — isso significa máximo 43 minutos de downtime por mês
> - **Latência < 300ms** — o doador não espera
> - **Error budget calculado** — sabemos exatamente quanto temos pra falhar
>
> E quando algo falha? **Auto-healing** — a própria plataforma se recupera em menos de 3 minutos, sem intervenção manual."

**Ênfase:**

> "Burn Rate Alerts nos avisam com 2 horas de antecedência se estamos queimando nosso orçamento de erros. Tempo suficiente para agir."

### Visual
- **Slide 4 (SRE):** Tabela SLI/SLO/SLA  
- Realçar: "99.9%" e "43 minutos"

### Dica
- SRE é sobre **previsibilidade** — fale isso
- "Auto-healing em 3 minutos" é um diferencial — enfatize

---

## 💰 SEÇÃO 5: FINOPS (2 minutos)

### O Que Dizer

> "**Requisito #2: Controle de Custos (FinOps)**
>
> Você sabe quanto a ONG está gastando em infraestrutura?  
> Consegue rastrear por serviço? Por ambiente?
>
> Nós conseguimos. Porque **toda** infraestrutura tem tags:
> - **Project** — identifica o projeto
> - **Environment** — Production vs DR
> - **CostCenter** — quem paga?
> - **ManagedBy** — quem administra (Terraform)
>
> Isso é aplicado em **todo recurso** — EC2, RDS, DynamoDB, SQS, ECR."

**Pausa**

> "**O custo mensal?** Aproximadamente **$297 por mês**:
> - EKS: $73
> - Servidores: $90
> - Banco de dados: $24
> - Gateway de saída: $32
> - Outros: $12
>
> **Por ano? Menos de $4 mil** mantendo alta disponibilidade e disaster recovery ativo.
>
> E temos propostas de otimização que reduzem ainda mais em 15%."

### Visual
- **Slide 5 (FinOps):** Tabela de Tags + Forecast  
- Mostrar breakdown de custos
- Realçar: "$297/mês" e "99.9% disponibilidade"

### Dica
- FinOps é sobre **justificativa de gasto** — "cada centavo é rastreável"
- A banca adora: "custo é baixo MAS a qualidade é alta"

---

## 🛡️ SEÇÃO 6: DISASTER RECOVERY (2 minutos)

### O Que Dizer

> "**Requisito #3: Segurança & Resiliência**
>
> E se a AWS us-east-1 cair?  
> A gente tem plano.
>
> **Padrão Warm Standby:** mantemos uma réplica hot em us-west-2
> - Banco de dados replicado em tempo real (5 minutos de lag máximo)
> - Dados voluntários sincronizados < 1 segundo (DynamoDB Global Tables)
> - Backups diários com Velero (pronto pra restore)
>
> **RTO (tempo pra recuperar):** 15 minutos
> - Detecção: 2 min
> - Promover banco: 3 min
> - Escalar Kubernetes: 5 min
> - Atualizar DNS: 1 min
> - Validar saúde: 2 min
>
> **RPO (perda de dados):** 5 minutos no máximo
>
> **Custo?** Apenas $65/mês manter esse estado de prontidão."

### Visual
- **Slide 6 (DR):** Tabela Primary vs DR  
- Realçar: "RTO 15 min" e "RPO 5 min"  
- Mostrar custo: "$65/mês"

### Dica
- DR é sobre **responsabilidade** — "não queremos surpresas"
- "15 minutos é nosso compromisso" — garanta com a voz
- Diretoria adora: "preparado pra tudo"

---

## 🔧 SEÇÃO 7: ITSM/AOPS (1 minuto)

### O Que Dizer

> "**Requisito #4: Operações Inteligentes (ITSM/AIOps)**
>
> Quando um incidente acontece, temos um ciclo de vida definido:
>
> 1. **Detecção** (2 min) — Prometheus e New Relic detectam
> 2. **Triagem** (2-5 min) — On-call valida e classifica (P1-P4)
> 3. **Mitigação** (3-15 min) — Auto-healing dispara automaticamente
> 4. **Comunicação** — Time é notificado via Discord + PagerDuty
> 5. **Resolução** — Valida SLO e error budget
> 6. **Post-Mortem** (24h) — Root cause analysis
>
> **Resultado:** MTTR reduzido em 80% (de 10 min pra 3 min)"

### Visual
- **Slide 7 (ITSM):** Tabela do Ciclo de Vida  
- Realçar: "80% redução em MTTR"

### Dica
- ITSM é sobre **preparação** — "sabemos exatamente como reagir"
- Auto-healing é o diferencial — enfatize

---

## 📹 SEÇÃO 8: DEMO COM SCREENSHOTS (6-7 minutos)

### Preparação ANTES de Começar

Abra em abas do navegador:
1. PDF PITCH-APRESENTACAO.pdf (slides 8-15)
2. GitHub: https://github.com/dsrdantas/TC5-ST (fundo)
3. Terminal ready para `kubectl` (se necessário)

---

### SCREENSHOT 1: Grafana Dashboard (1 min)

**Slide 8 do PDF**

### O Que Dizer

> "Começamos aqui — **Grafana Dashboard 'SolidaryTech - Ecosystem Health'**.
>
> Veem esses gráficos? São os **Golden Metrics** do SRE:
> - **CPU/Memory by Namespace** — se algo consome recursos anormalmente, vemos aqui
> - **HTTP Request Rate** — tráfego de requisições pra cada serviço
> - **Error Rate (5xx)** — em vermelho se > 5% (alerta dispara)
> - **Latência P95** — confirmando < 300ms sempre
> - **Pod Status** — todos Running? Pronto pra lidar com tráfego
>
> Tudo isso é colhido automaticamente por Prometheus a cada 15-30 segundos."

### Visual
- Mostrar o screenshot completo
- Point para CPU/Memory, Request Rate, Error Rate, P95

### Dica
- "Não é configurado manualmente — é automático"
- "Temos visibilidade 24/7"

---

### SCREENSHOT 2: ArgoCD (1 min)

**Slide 9 do PDF**

### O Que Dizer

> "Agora — **GitOps em ação com ArgoCD**.
>
> Quando fazemos push pro GitHub em `main`, **automaticamente**:
> 1. GitHub Actions roda testes + SAST + build
> 2. Nova imagem é feita e enviada pra ECR
> 3. ArgoCD detecta que há uma versão nova
> 4. **Aplica no Kubernetes automaticamente**
>
> Status: **Healthy** (verde) = tudo OK  
> Sync: **Synced** = o que está no GitHub é exatamente o que está rodando
>
> Sem downtime. Sem intervenção manual. Isso é deploy moderno."

### Visual
- Mostrar ArgoCD interface
- Point: Healthy status, Synced status, última sincronização

### Dica
- "Confiança total" — o que eu comito, sobe sozinho
- "Velocidade" — deploy em minutos, não horas

---

### SCREENSHOT 3: Pods Running (1 min)

**Slide 10 do PDF**

### O Que Dizer

> "**Kubernetes rodando os 3 microsserviços**:
>
> - **ngo-service** — 3 réplicas rodando (se 1 cai, as outras continuam)
> - **donation-service** — 4 réplicas (é o Hot Path, precisa de mais)
> - **volunteer-service** — 2 réplicas
>
> Tudo em status **Running**.
>
> Se um pod crashea? Kubernetes reinicia automaticamente.  
> Se um nó cai? Pods são reschedulados em outro nó.  
> Isso é **alta disponibilidade de verdade**."

### Visual
- Mostrar lista de pods com status
- Contar: ngo (3), donation (4), volunteer (2)

### Dica
- "Replicas = resiliência"
- "Kubernetes faz self-healing nativo"

---

### SCREENSHOT 4: FinOps Tags (1 min)

**Slide 11 do PDF**

### O Que Dizer

> "**AWS Tag Editor — veem todas as tags?**
>
> Cada um desses recursos (EC2, RDS, DynamoDB, SQS, ECR) tem:
> - Project = SolidaryTech
> - Environment = Production ou DR
> - CostCenter = NGO-Core
> - ManagedBy = Terraform
>
> Por quê? Porque **sem tags, você não sabe onde está gastando dinheiro**.
>
> Com isso, consigo:
> - Filtrar custo por projeto
> - Comparar Production vs DR
> - Justificar gastos pra diretoria
> - Achar recursos órfãos (que ninguém tá usando)"

### Visual
- Mostrar AWS Tag Editor
- Point para exemplos de tags em diferentes recursos

### Dica
- "Rastreabilidade = poder"
- "Governança de custos desde dia 1"

---

### SCREENSHOT 5: Alertas Discord (1 min)

**Slide 12 do PDF**

### O Que Dizer

> "**Discord — nosso canal de alertas em tempo real**.
>
> Quando algo sai do esperado:
> 1. Prometheus detecta (ex: erro 5xx > 5% por 2 min)
> 2. Alertmanager processa
> 3. Discord notifica o time
> 4. **GitHub Actions dispara automaticamente** o workflow de auto-healing
> 5. Pod que tá crashando é reiniciado
>
> Tudo em **menos de 3 minutos**, sem ninguém tocar em nada.
>
> Resultado: ninguém precisa estar acordado às 3 da manhã — a plataforma se recupera sozinha."

### Visual
- Mostrar mensagens de alerta no Discord
- Point: timestamp, mensagem de alerta, resultado (✅ ou ❌)

### Dica
- "Auto-remediation é o futuro"
- "ChatOps = visibilidade + ação"

---

### SCREENSHOT 6: New Relic Traces (30 seg)

**Slide 13 do PDF**

### O Que Dizer

> "**New Relic APM — rastreamento distribuído**.
>
> Uma requisição de doação passa por:
> - ngo-service (validar ONG) → 50ms
> - donation-service (processar doação) → 120ms
> - DynamoDB (guardar voluntário) → 30ms
> - SQS (fila de notificação) → 10ms
>
> Total: 210ms (dentro do SLO de 300ms)
>
> Se algum serviço fica lento, vemos exatamente qual e por quê."

### Visual
- Mostrar Trace Timeline
- Point para cada serviço e latência

### Dica
- "Visibilidade end-to-end"
- "Sem rastreamento, você está cego"

---

### SCREENSHOT 7: PagerDuty (1 min)

**Slide 14 do PDF**

### O Que Dizer

> "**PagerDuty — gerenciamento de incidentes enterprise**.
>
> Quando um alerta crítico dispara (P1 = problema total):
> 1. PagerDuty notifica o on-call
> 2. Se não responder em 5 min, escalona pra gerente
> 3. Todo o contexto está ali: logs, métricas, traces
> 4. Ao resolver, gera post-mortem automático
>
> Isso garante que **sempre** alguém sabe o que tá acontecendo.
>
> Sem PagerDuty? Incidente passa despercebido, perda de $ em receita."

### Visual
- Mostrar lista de incidentes em PagerDuty
- Point: severidade, status, timestamp, assignee

### Dica
- "Escalação automática = responsabilidade garantida"
- "Rastreabilidade completa de incidentes"

---

### SCREENSHOT 8: Velero Backup (30 seg)

**Slide 15 do PDF**

### O Que Dizer

> "**Velero — Backups diários da infraestrutura inteira**.
>
> Toda noite às 3 da manhã:
> - Kubernetes (manifests, configs)
> - Persistent Volumes (dados)
> - Secrets (senhas)
>
> Tudo é enviado pra S3 em us-west-2.
>
> Se a região inteira cair? **Restore em 15 minutos**."

### Visual
- Mostrar backups completados
- Point: data/hora, tamanho, status (completed)

### Dica
- "Backup é seguro de vida da infraestrutura"
- "Sem backup, um incidente vira desastre"

---

### SCREENSHOT 9: CI/CD Pipeline (1 min)

**Slide 16 do PDF**

### O Que Dizer

> "**GitHub Actions — Pipeline completo de CI/CD**.
>
> Toda vez que eu faço push:
> 1. **Testes unitários** rodão automaticamente
> 2. **SAST (Static Analysis)** — busca vulnerabilidades no código
> 3. **SCA (Software Composition Analysis)** — checa dependências maliciosas
> 4. **Trivy** — escaneia a imagem Docker por vulnerabilidades
> 5. **Build** da imagem (multi-stage, otimizado)
> 6. **Push** pra ECR (repositório de imagens)
> 7. **Deploy** via ArgoCD
>
> Se qualquer etapa falha, **nada sobe**. Qualidade garantida.
>
> DevSecOps desde o primeiro commit."

### Visual
- Mostrar histórico de builds
- Point: ✅ passed e ❌ failed
- Mostrar tempo de execução (ex: 5 min)

### Dica
- "Segurança não é afterthought"
- "Testes automáticos = menos bugs em produção"

---

## 💎 SEÇÃO 9: CONCLUSÃO & ROI (1-2 minutos)

### O Que Dizer

> "**Resumindo — implementamos TODOS os requisitos:**
>
> ✅ **SRE:** SLO 99.9%, burn rate alerts, auto-healing em 3 minutos  
> ✅ **FinOps:** Tags estruturadas, forecast $297/mês, otimizações -15%  
> ✅ **DR:** RTO 15 min, RPO 5 min, Warm Standby pronto  
> ✅ **ITSM/AIOps:** Ciclo de vida 6 fases, PagerDuty + Discord integrado  
> ✅ **DevSecOps:** Pipeline completo com testes + SAST + SCA + Trivy  

---

> "**E o impacto? Real:**
>
> Hoje: 100 doações/dia = ~R$ 1.140k/ano  
> Com SolidaryTech: 140 doações/dia = ~R$ 1.515k/ano  
> **Ganho: +R$ 375k/ano**
>
> Investimento: ~R$ 150k (dev) + R$ 45k/ano (ops)  
> Payback: **2-3 meses**
>
> Depois disso? Pura margem.
>
> E tudo isso rodando com confiabilidade enterprise (99.9%), 
> disaster recovery ativo, e custo controlado ($297/mês)."

---

> "**O repositório com TODO o código está no GitHub:**
>
> https://github.com/dsrdantas/TC5-ST
>
> **O vídeo de demonstração técnica (20 min):**
>
> https://github.com/dsrdantas/TC5-ST/blob/main/docs/tc5-st.mp4
>
> **Documentação técnica completa:**
>
> https://github.com/dsrdantas/TC5-ST/tree/main/docs
>
> Tudo está lá pra vocês avaliar. Não é teoria — é código rodando em produção."

---

> "**Obrigado. Perguntas?**"

---

## 🎙️ DICAS FINAIS PARA A APRESENTAÇÃO

### Antes de Começar
- [ ] Testar áudio/vídeo 5 min antes
- [ ] Ter 2 abas abertas (PDF + GitHub)
- [ ] Terminal pronto (se precisar rodar comandos)
- [ ] Discord aberto (pra mostrar alertas)
- [ ] Ter água/café à mão

### Durante
- [ ] Fale devagar — pausas são boas
- [ ] Faça contato visual com a câmera
- [ ] Aponte pra tela quando mostrar algo importante
- [ ] Use voz com emoção — isso é real, não é robótico
- [ ] Se errar, continue — ninguém vai notar

### Ordem de Apresentação
1. **Capa** (apresentação pessoal)
2. **Problema** (contexto)
3. **Solução** (arquitetura)
4. **SRE** (confiabilidade)
5. **FinOps** (custos)
6. **DR** (segurança)
7. **ITSM** (operações)
8. **Screenshots** (evidências)
9. **Conclusão** (impacto + ROI)
10. **Links** (repositório + vídeo)

### Respostas Rápidas pra Perguntas Comuns

**P: "Por que Go pra donation-service?"**  
R: "Go é baixa latência, alta throughput e fácil de fazer deploy. É ideal pra Hot Path."

**P: "E se a AWS falhar?"**  
R: "Temos Warm Standby em us-west-2. RTO 15 minutos. Dados replicados em tempo real."

**P: "Quanto custa manter isso?"**  
R: "$297/mês production + $65/mês DR. Menos de $5k/ano mantendo 99.9% de uptime."

**P: "Como vocês sabem que está funcionando?"**  
R: "Grafana + New Relic + PagerDuty têm visibilidade 24/7. Se algo cai, sabemos em 2 minutos."

**P: "E se vocês desistirem?"**  
R: "Todo o código está no GitHub com IaC (Terraform). Qualquer time consegue pegar e rodar."

---

## 📊 Checklist Final

- [ ] PDF slides aberto e navegável
- [ ] Screenshots visíveis e comentadas
- [ ] Links prontos (copiar/colar)
- [ ] Voz aquecida (beba água)
- [ ] Cronômetro mental (20 min max)
- [ ] Confiança total no projeto ✅

---

**Boa sorte! Vocês têm um projeto extraordinário. 🚀**

