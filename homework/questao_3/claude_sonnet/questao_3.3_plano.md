### Plano de Ação Estratégico (Roadmap Trimestral)


### 1. Diagnóstico do Cenário Atual e Custo Total

A partir da análise detalhada dos dados de consumo mensal da conta AWS, o custo total atual da infraestrutura foi consolidado em **$\$41.800,00$ USD/mês**.

Para atingirmos a meta estabelecida pela diretoria de **$15\%$ de redução**, precisamos capturar uma economia recorrente de, no mínimo, **$\$6.270,00$ USD/mês**, estabelecendo um teto orçamentário alvo de **$\$35.530,00$ USD/mês** para o próximo trimestre.

Abaixo está a distribuição atual de custos por categoria macro, evidenciando que as frentes de _Compute_ e _Databases_ centralizam mais de $72\%$ dos gastos totais, sendo os alvos primários da estratégia:

- **Compute:** $\$20.000,00$ USD ($47,85\%$)
- **Databases:** $\$10.300,00$ USD ($24,64\%$)
- **Storage:** $\$4.700,00$ USD ($11,24\%$)
- **Observability:** $\$3.700,00$ USD ($8,85\%$)
- **Network:** $\$3.100,00$ USD ($7,42\%$)
    

---

### 2. Tabela de Oportunidades de Otimização (Priorizada por Impacto)

A estratégia proposta abaixo adota as boas práticas do framework FinOps, priorizando ações pelo equilíbrio entre o retorno financeiro e a complexidade técnica.

| **Serviço / Categoria**                                | **Ação de Otimização Recomendada**                                                                                                                                                                                                                            | **Economia Estimada**                                           | **Esforço de Implementação (Baixo, Médio, Alto)** | **Riscos e Pré-requisitos envolvidos em cada etapa**                                                                                                                                                                                                                                                 |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **EC2 on-demand**<br><br>  <br><br>_(Compute)_         | Realizar o _right-sizing_ (ajuste de tamanho) das instâncias que operam com apenas $45\%$ de uso médio. Na sequência, aplicar **Compute Savings Plans** (contrato de 1 ano, _No Upfront_) cobrindo o baseline estável desses workloads variáveis.             | **$\$2.460,00$ USD**<br><br>  <br><br>($5,89\%$ da conta total) | **Médio**                                         | **Riscos:** Degradação de performance caso o _right-sizing_ seja agressivo demais.<br><br>  <br><br>**Pré-requisitos:** Análise detalhada de métricas de CPU/Memória por 14 dias; aprovação financeira para o compromisso de 1 ano do Savings Plan.                                                  |
| **RDS PostgreSQL**<br><br>  <br><br>_(Databases)_      | Adquirir **Instâncias Reservadas (RI)** de 1 ano, modalidade _No Upfront_, para a infraestrutura existente. Como o banco opera em Multi-AZ para fins produtivos, o desconto padrão de reserva mitiga drasticamente o custo fixo.                              | **$\$2.460,00$ USD**<br><br>  <br><br>($5,89\%$ da conta total) | **Baixo**                                         | **Riscos:** Desperdício de capital caso haja migração planejada para outro motor de banco de dados ou Serverless a curto prazo.<br><br>  <br><br>**Pré-requisitos:** Confirmação com o time de arquitetura de que a engine (PostgreSQL) e a família de instâncias não mudarão nos próximos 12 meses. |
| **EKS**<br><br>  <br><br>_(Compute)_                   | Otimizar a alocação de recursos nos 3 clusters (uso atual de $58\%$) implementando ferramentas de autoscaling dinâmico e consolidação de nós (ex: **Karpenter**), além de desligamento programado ou uso de instâncias _Spot_ para ambientes de não-produção. | **$\$1.340,00$ USD**<br><br>  <br><br>($3,21\%$ da conta total) | **Alto**                                          | **Riscos:** Indisponibilidade momentânea ou desalocação incorreta de pods durante a reorganização dos nós produtivos.<br><br>  <br><br>**Pré-requisitos:** Configuração correta de HPA/VPA (_Horizontal/Vertical Pod Autoscaler_) e execução de testes de resiliência em ambiente de homologação.    |
| **CloudWatch Logs**<br><br>  <br><br>_(Observability)_ | Reduzir o período de retenção ativa dos logs de 90 dias para 30 dias (ou menos para ambientes de teste). Configurar regras de ciclo de vida para expirar logs obsoletos ou movê-los para o S3 Glacier se houver necessidade histórica.                        | **$\$1.120,00$ USD**<br><br>  <br><br>($2,68\%$ da conta total) | **Baixo**                                         | **Riscos:** Indisponibilidade de logs antigos para auditorias retroativas imediatas.<br><br>  <br><br>**Pré-requisitos:** Alinhamento prévio e aprovação formal do time de Segurança e Compliance regulatório sobre as políticas de retenção de dados.                                               |
| **S3 Standard**<br><br>  <br><br>_(Storage)_           | Habilitar o **S3 Intelligent-Tiering** ou criar _Lifecycle Policies_ personalizadas nos 5 buckets principais para mover objetos sem acessos após 30 dias para classes de armazenamento mais baratas (_Infrequent Access_ / _Glacier_).                        | **$\$775,00$ USD**<br><br>  <br><br>($1,85\%$ da conta total)   | **Baixo**                                         | **Riscos:** Custos adicionais por requisição se houver leitura frequente de arquivos que sofreram a transição automática.<br><br>  <br><br>**Pré-requisitos:** Mapeamento do padrão de acesso aos dados nos buckets principais via _S3 Storage Lens_.                                                |
| **ElastiCache Redis**<br><br>  <br><br>_(Databases)_   | Com uso médio de $40\%$, recomenda-se avaliar o _downsize_ do tamanho dos nós do cluster produtivos ou realizar a compra de _Reserved Nodes_ de 1 ano para consolidar o desconto.                                                                             | **$\$525,00$ USD**<br><br>  <br><br>($1,26\%$ da conta total)   | **Médio**                                         | **Riscos:** Perda de dados em cache ou gargalo de IOPS se o pico de uso de memória ultrapassar a nova capacidade.<br><br>  <br><br>**Pré-requisitos:** Monitorar rigorosamente os picos históricos de utilização de memória (não apenas a média).                                                    |
| **NAT Gateway**<br><br>  <br><br>_(Network)_           | Criar **VPC Endpoints** (do tipo Gateway para S3 e Interface para outros serviços utilizados internamente). Isso evita que o tráfego interno passe pelo NAT Gateway, reduzindo o custo por GB processado.                                                     | **$\$240,00$ USD**<br><br>  <br><br>($0,57\%$ da conta total)   | **Médio**                                         | **Riscos:** Erros de roteamento interno na rede se as tabelas de rotas da VPC forem configuradas incorretamente.<br><br>  <br><br>**Pré-requisitos:** Homologação prévia das tabelas de rotas e políticas de IAM associadas aos Endpoints da VPC.                                                    |
| **Data Transfer Out**<br><br>  <br><br>_(Network)_     | Avaliar a distribuição do tráfego entre regiões e otimizar a arquitetura ou adotar o **Amazon CloudFront** se houver entrega de conteúdo público, reduzindo as taxas de transferência direta.                                                                 | **$\$380,00$ USD**<br><br>  <br><br>($0,91\%$ da conta total)   | **Médio / Alto**                                  | **Riscos:** Mudanças em regras de DNS e latência na propagação inicial do CDN.<br><br>  <br><br>**Pré-requisitos:** Análise detalhada da origem e destino do tráfego utilizando _VPC Flow Logs_.                                                                                                     |

---

Para mitigar riscos operacionais e garantir o atingimento progressivo da meta sem sobrecarregar o time de engenharia, dividiremos o plano de ação nas três fases do ciclo de vida FinOps (_Inform, Optimize, Operate_) ao longo do trimestre:

#### **Mês 1: Quick Wins & Compromissos Comerciais (Fase Inform/Optimize)**

- **Foco:** Capturar economias imediatas com baixo esforço arquitetural.
    
- **Ações:** 1. Executar a alteração de retenção do _CloudWatch Logs_ (Economia: $\$1.120,00$ USD).
    
    2. Ativar as políticas de ciclo de vida no _S3 Standard_ (Economia: $\$775,00$ USD).
    3. Efetuar a compra das Instâncias Reservadas para o _RDS PostgreSQL_ (Economia: $\$2.460,00$ USD).
- **Resultado do Mês 1:** Redução imediata na taxa de execução de **$\$4.355,00$ USD/mês** (Atinge **$10,42\%$** de economia logo no início).
    

#### **Mês 2: Eficiência e Modernização de Recursos (Fase Optimize)**

- **Foco:** Otimização de sizing e engenharia de custos em infraestrutura de computação interna.
    
- **Ações:**
    1. Realizar o _right-sizing_ do _EC2 On-Demand_ e assinar o _Compute Savings Plans_ (Economia: $\$2.460,00$ USD).
    2. Otimizar e aplicar reservas ao _ElastiCache Redis_ (Economia: $\$525,00$ USD).
    3. Implementar _VPC Endpoints_ para reduzir tráfego no _NAT Gateway_ (Economia: $\$240,00$ USD).
        
- **Resultado do Mês 2:** Adiciona **$\$3.225,00$ USD/mês** em economias. O acumulado chega a **$\$7.580,00$ USD/mês** (Totalizando **$18,13\%$** de redução).
    

#### **Mês 3: Consolidação Arquitetural e Governança (Fase Operate)**

- **Foco:** Mudanças estruturais profundas e estabelecimento de cultura de governança contínua.
    
- **Ações:**
    1. Finalizar a implementação do _Karpenter_ e autoscaling nos clusters _EKS_ (Economia: $\$1.340,00$ USD).
    2. Ajustar e otimizar as taxas de _Data Transfer Out_ via rede interna/CloudFront (Economia: $\$380,00$ USD).
    3. Implementar painéis de monitoramento de FinOps diários para evitar desvios (_budgets_ e alertas).
        
- **Resultado Final do Trimestre:** Potencial máximo mapeado de **$\$9.300,00$ USD/mês** de economia.
    

---

### 4. Conclusão e Recomendação para Goldie

A meta de redução de **$15\%$ ($\$6.270,00$ USD)** estipulada pela diretoria é não apenas totalmente **viável**, mas pode ser **superada de forma segura**, alcançando até **$22,25\%$ ($\$9.300,00$ USD)** de otimização total ao término do trimestre.

**Próximos Passos recomendados para aprovação imediata:**
1. Autorizar a aquisição das Instâncias Reservadas de RDS (Baixo esforço, retorno imedito).
2. Dar aval para o time de Segurança validar a redução do tempo de retenção do CloudWatch Logs para 30 dias.
3. Liberar o início do mapeamento técnico de métricas das instâncias EC2 On-demand para a execução do plano no Mês 2.