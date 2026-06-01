# INPUT

servico,categoria,custo_mensal_usd,uso_medio_pct,observacao
EC2 reservada,compute,4200,72,contrato de 1 ano
EC2 on-demand,compute,8200,45,workloads variaveis
EKS,compute,6700,58,3 clusters
RDS PostgreSQL,databases,8200,62,multi-AZ
ElastiCache Redis,databases,2100,40,cluster de producao
S3 Standard,storage,3100,,5 buckets principais
EBS gp3,storage,1600,68,volumes de producao
CloudWatch Logs,observability,2800,,retencao de 90 dias
CloudWatch Metrics,observability,900,,
Data Transfer Out,network,1900,,trafego entre regioes
NAT Gateway,network,1200,,3 gateways ativos
Lambda,compute,900,30,~12M invocacoes/mes

# TASK
Analise o CSV acima elaborar um relatório estratégico de otimização de custos (FinOps) focado em oportunidades de economia, priorizadas pelo impacto financeiro.

# ACTION
Realize as seguintes atividades:
 - Calcular o custo total atual da conta AWS a partir do CSV.
 - Identificar e listar oportunidades de redução de custo baseando-se nas boas praticas de FinOps
 - Estruturar o relatório em uma tabela contendo as seguintes colunas obrigatórias:
   - Serviço / Categoria
   - Ação de Otimização Recomendada
   - Economia Estimada com o percentual % correspondente sobre a conta total
   - Esforço de Implementação (Baixo, Médio, Alto)
   - Riscos e Pré-requisitos envolvido em cada etapa

# GOAL
O objetivo final é fornecer um plano de ação para a diretoria (Goldie) que demonstre como atingir a meta do próximo trimestre de 15% de redução no custo total de cloud

