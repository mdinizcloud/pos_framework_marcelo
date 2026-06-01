# Documentação - Backup Diário PostgreSQL Ledger
## Sistema de Backup Automático para EC2 + S3

---

## 📋 ÍNDICE
1. [Descrição Geral](#descrição-geral)
2. [Arquitetura e Fluxo](#arquitetura-e-fluxo)
3. [Tratamento de Erros](#tratamento-de-erros)
4. [Segurança](#segurança)
5. [Setup e Instalação](#setup-e-instalação)
6. [Monitoramento](#monitoramento)
7. [Troubleshooting](#troubleshooting)

---

## Descrição Geral

### O que é este script?
Sistema robusto e profissional de backup automático para PostgreSQL que:
- ✅ Executa diariamente via Cron
- ✅ Faz dump do banco `ledger_prod` com pg_dump
- ✅ Compacta com gzip (máxima compressão)
- ✅ Envia para bucket S3 `hvt-ledger-backups`
- ✅ Implementa retenção automática de 30 dias
- ✅ Registra todas as operações em log
- ✅ Trata erros em cada etapa com exit codes
- ✅ Usa IAM Role (sem credenciais hardcoded)
- ✅ Implementa lock file (evita execução concorrente)

### Especificações Técnicas
```
Banco de Dados: PostgreSQL (ledger_prod)
Host: ledger-db.internal.hvt.io:5432
Usuário de Backup: backup_user
Compressão: gzip -9 (máxima)
Armazenamento: AWS S3 (hvt-ledger-backups)
Retenção: 30 dias (local + S3)
Log: /var/log/ledger-backup.log
Agendamento: Diariamente às 02:00 (UTC)
SO: Ubuntu 22.04 LTS / 24.04 LTS
```

---

## Arquitetura e Fluxo

### Diagrama do Fluxo de Execução

```
┌─────────────────────────────────────────────────────────────┐
│ CRON JOB (Diariamente às 02:00)                             │
│ └─> /opt/ledger-backup/ledger-backup.sh                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 1. VALIDAÇÕES INICIAIS          │
          ├────────────────────────────────┤
          │ ✓ Pré-requisitos (pg_dump, aws) │
          │ ✓ Diretórios (/var/backups)     │
          │ ✓ Lock file (evita concorrência)│
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 2. AUTENTICAÇÃO                 │
          ├────────────────────────────────┤
          │ IAM Role → AWS Secrets Manager  │
          │ Recupera: password do DB        │
          │ Exporta: PGPASSWORD (variável) │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 3. TESTE DE CONEXÃO             │
          ├────────────────────────────────┤
          │ pg_isready: valida conectividade│
          │ Garante que BD está online      │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 4. EXECUTAR PG_DUMP             │
          ├────────────────────────────────┤
          │ pg_dump -F c (formato custom)   │
          │ Saída: ledger_20250526_020000.sql
          │ Arquivo: /var/backups/ledger/   │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 5. COMPACTAR COM GZIP           │
          ├────────────────────────────────┤
          │ gzip -9 (máxima compressão)     │
          │ Entrada: .sql                   │
          │ Saída: ledger_20250526_020000.sql.gz
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 6. UPLOAD PARA S3               │
          ├────────────────────────────────┤
          │ aws s3 cp → S3 com metadados    │
          │ Bucket: hvt-ledger-backups      │
          │ Prefix: postgres-backups/       │
          │ SSE: AES256 (criptografia)      │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 7. LIMPEZA LOCAL (30 DIAS)      │
          ├────────────────────────────────┤
          │ find: arquivos > 30 dias        │
          │ remove: /var/backups/ledger/*.gz│
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 8. LIMPEZA S3 (30 DIAS)         │
          ├────────────────────────────────┤
          │ aws s3api list + delete         │
          │ Remove: objects antigos no S3   │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ 9. REGISTRAR LOGS               │
          ├────────────────────────────────┤
          │ /var/log/ledger-backup.log      │
          │ Timestamp: YYYY-MM-DD HH:MM:SS │
          │ Level: INFO, ERROR, WARNING     │
          └────────────────────────────────┘
```

### Variáveis de Ambiente e Configurable
| Variável | Valor | Propósito |
|----------|-------|----------|
| `DB_HOST` | ledger-db.internal.hvt.io | Host do PostgreSQL |
| `DB_PORT` | 5432 | Porta PostgreSQL |
| `DB_NAME` | ledger_prod | Nome do banco |
| `DB_USER` | backup_user | Usuário de backup |
| `BACKUP_DIR` | /var/backups/ledger | Diretório local de backups |
| `LOG_FILE` | /var/log/ledger-backup.log | Arquivo de log |
| `S3_BUCKET` | hvt-ledger-backups | Bucket S3 |
| `S3_PREFIX` | postgres-backups | Prefixo no S3 |
| `AWS_REGION` | us-east-1 | Região AWS (ajustar conforme necessário) |
| `RETENTION_DAYS` | 30 | Dias de retenção |
| `SECRETS_NAME` | ledger-db-backup-credentials | Nome do secret no Secrets Manager |

---

## Tratamento de Erros

### Estratégia de Tratamento de Erros

O script implementa uma estratégia **fail-fast** onde:

1. **Cada comando crítico é validado** - Exit code é checado imediatamente
2. **Mensagens de erro são descritivas** - Incluem contexto e números de erro
3. **Logs registram todas as falhas** - Facilita debugging e auditoria
4. **Execução é interrompida na primeira falha** - Evita corromper dados
5. **Exit codes diferentes de zero** - Cron notifica em caso de falha

### Pontos de Validação com Exit Code

#### 1️⃣ **Validação de Pré-requisitos**
```bash
# Verifica se pg_dump, gzip, aws, jq estão instalados
# Exit Code: 1 se alguma ferramenta estiver faltando
for tool in "${required_tools[@]}"; do
    if ! command -v "${tool}" &> /dev/null; then
        log_error "Ferramenta obrigatória não encontrada: ${tool}"
        # Exit 1 é chamado automaticamente
    fi
done
```
**Erro Esperado**: "Ferramenta obrigatória não encontrada: pg_dump"
**Solução**: `sudo apt-get install postgresql-client awscli`

---

#### 2️⃣ **Validação de Diretórios**
```bash
# Verifica se /var/backups/ledger existe e é acessível
if [[ ! -d "${BACKUP_DIR}" ]]; then
    mkdir -p "${BACKUP_DIR}" || log_error "Falha ao criar diretório"
fi

if [[ ! -w "${BACKUP_DIR}" ]]; then
    log_error "Diretório não possui permissão de escrita"
    # Exit 1
fi
```
**Erro Esperado**: "Diretório não possui permissão de escrita"
**Solução**: `sudo chown ubuntu:ubuntu /var/backups/ledger && sudo chmod 755 /var/backups/ledger`

---

#### 3️⃣ **Validação de Credenciais (AWS Secrets Manager)**
```bash
# Verifica IAM Role
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "IAM Role não disponível ou sem credenciais válidas"
fi

# Recupera secret
secret_json=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRETS_NAME}" \
    --region "${AWS_REGION}" \
    --query 'SecretString' \
    --output text 2>/dev/null)

if [[ -z "${secret_json}" ]]; then
    log_error "Falha ao recuperar credenciais do Secrets Manager"
fi

# Extrai password
DB_PASSWORD=$(echo "${secret_json}" | jq -r '.password')
if [[ -z "${DB_PASSWORD}" ]] || [[ "${DB_PASSWORD}" == "null" ]]; then
    log_error "Campo 'password' não encontrado no secret"
fi
```
**Erro Esperado**: "Falha ao recuperar credenciais do Secrets Manager"
**Solução**: 
- Verificar IAM Role: `aws sts get-caller-identity`
- Criar secret: `aws secretsmanager create-secret --name ledger-db-backup-credentials --secret-string '{"password":"sua_senha"}'`

---

#### 4️⃣ **Validação de Conexão com Banco**
```bash
# Testa conexão antes de fazer dump
if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" &> /dev/null; then
    log_error "Não foi possível conectar ao banco de dados"
fi
```
**Erro Esperado**: "Não foi possível conectar ao banco de dados"
**Solução**: 
- Verificar conectividade: `nc -zv ledger-db.internal.hvt.io 5432`
- Verificar grupo de segurança EC2: permitir porta 5432
- Verificar status do banco: `sudo systemctl status postgresql`

---

#### 5️⃣ **Validação de pg_dump**
```bash
# Executa pg_dump
pg_dump ... -f "${dump_file}" 2>> "${LOG_FILE}"
local pg_dump_exit_code=$?

if [[ ${pg_dump_exit_code} -ne 0 ]]; then
    log_error "pg_dump falhou com exit code ${pg_dump_exit_code}"
fi

# Valida se arquivo foi criado
if [[ ! -f "${dump_file}" ]]; then
    log_error "Arquivo de dump não foi criado: ${dump_file}"
fi

# Valida tamanho (> 0 bytes)
local dump_size=$(stat -c%s "${dump_file}")
if [[ ${dump_size} -le 0 ]]; then
    log_error "Arquivo de dump vazio ou inválido (tamanho: ${dump_size})"
fi
```
**Erro Esperado**: "pg_dump falhou com exit code 1"
**Solução**: 
- Verificar permissões do usuário: `psql -h ledger-db.internal.hvt.io -U backup_user -d ledger_prod -c "SELECT 1;"`
- Verificar PGPASSWORD: `PGPASSWORD=xxx pg_dump -h ... -U backup_user -d ledger_prod`

---

#### 6️⃣ **Validação de Compressão (gzip)**
```bash
# Compacta arquivo
gzip -v -9 "${dump_file}"
local gzip_exit_code=$?

if [[ ${gzip_exit_code} -ne 0 ]]; then
    log_error "gzip falhou com exit code ${gzip_exit_code}"
fi

# Valida arquivo compactado
if [[ ! -f "${compressed_file}" ]]; then
    log_error "Arquivo compactado não foi criado"
fi

local compressed_size=$(stat -c%s "${compressed_file}")
if [[ ${compressed_size} -le 0 ]]; then
    log_error "Arquivo compactado vazio"
fi
```
**Erro Esperado**: "Arquivo compactado vazio"
**Solução**: Verificar espaço em disco: `df -h /var/backups/ledger`

---

#### 7️⃣ **Validação de Upload S3**
```bash
# Upload para S3
aws s3 cp "${compressed_file}" \
    "s3://${S3_BUCKET}/${S3_PREFIX}/${filename}" \
    --region "${AWS_REGION}" \
    --storage-class STANDARD \
    --metadata "..." \
    --sse AES256 \
    --quiet 2>> "${LOG_FILE}"

local s3_upload_exit_code=$?

if [[ ${s3_upload_exit_code} -ne 0 ]]; then
    log_error "Upload S3 falhou com exit code ${s3_upload_exit_code}"
fi
```
**Erro Esperado**: "Upload S3 falhou com exit code 254"
**Solução**: 
- Verificar permissões S3: IAM Role precisa de `s3:PutObject` em `hvt-ledger-backups`
- Verificar conectividade AWS: `aws s3 ls`

---

### Redirecionamento de Saída

O script implementa redirecionamento cuidadoso da saída:

```bash
# STDERR para log (comando silencioso)
pg_dump ... 2>> "${LOG_FILE}"

# STDOUT para terminal e log (visibilidade em tempo real)
echo "[...] [INFO] Message" | tee -a "${LOG_FILE}"

# Erro crítico para STDERR
log_error "mensagem de erro" >&2

# Validação de exit codes
if [[ $? -ne 0 ]]; then
    log_error "Comando falhou"
fi
```

### Exit Codes Utilizados
| Exit Code | Significado | Exemplo |
|-----------|-------------|---------|
| 0 | Sucesso | Backup completado |
| 1 | Erro Fatal | pg_dump falhou |
| 124 | Timeout (find) | Comando foi interrompido |
| 127 | Comando não encontrado | pg_dump não está instalado |

---

## Segurança

### 1. Gerenciamento de Credenciais

#### ❌ **NÃO FAÇA ISSO** (inseguro)
```bash
# Nunca hardcode a senha no script!
pg_dump -h ledger-db.internal.hvt.io -U backup_user -W senha123 ...

# Nunca coloque na linha de comando!
export PGPASSWORD="senha123"
pg_dump ... -U backup_user ...
```

#### ✅ **FAÇA ISSO** (seguro)
```bash
# 1. Recupera do AWS Secrets Manager
secret_json=$(aws secretsmanager get-secret-value \
    --secret-id "ledger-db-backup-credentials" \
    --region "${AWS_REGION}" \
    --query 'SecretString' \
    --output text)

# 2. Extrai apenas a senha
DB_PASSWORD=$(echo "${secret_json}" | jq -r '.password')

# 3. Exporta em variável de ambiente
export PGPASSWORD="${DB_PASSWORD}"

# 4. Executa comando
pg_dump ... --no-password ...

# 5. Desprotege a variável
unset PGPASSWORD
```

**Por quê?**
- Secrets Manager cifra credenciais em repouso
- IAM Role fornece acesso temporário
- PGPASSWORD é limpado após uso
- Nenhuma credencial em arquivo ou processo

---

### 2. Permissões de Arquivo

```bash
# Script: 750 (rwxr-x---)
chmod 750 /opt/ledger-backup/ledger-backup.sh
# Apenas root e grupo podem executar

# Diretório de backup: 755 (rwxr-xr-x)
chmod 755 /var/backups/ledger
# Todos podem listar, apenas dono modifica

# Log file: 644 (rw-r--r--)
chmod 644 /var/log/ledger-backup.log
# Todos podem ler, apenas dono escreve
```

---

### 3. IAM Role e Políticas

#### Criar IAM Role para EC2

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetSecretForBackup",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:ledger-db-backup-credentials-*"
    },
    {
      "Sid": "S3BackupBucket",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::hvt-ledger-backups",
        "arn:aws:s3:::hvt-ledger-backups/*"
      ]
    }
  ]
}
```

#### Criar Secret no Secrets Manager

```bash
aws secretsmanager create-secret \
  --name ledger-db-backup-credentials \
  --description "Credenciais de backup para PostgreSQL Ledger" \
  --secret-string '{"password":"SUA_SENHA_POSTGRES_AQUI"}' \
  --region us-east-1

# Ou atualizar existente
aws secretsmanager update-secret \
  --secret-id ledger-db-backup-credentials \
  --secret-string '{"password":"NOVA_SENHA"}' \
  --region us-east-1
```

---

### 4. Segurança em Trânsito

```bash
# Upload S3 com criptografia AES-256
aws s3 cp file.gz s3://bucket/file.gz \
    --sse AES256 \
    --metadata "backup-timestamp=..."
```

- ✅ Dados criptografados em repouso (AES-256)
- ✅ Comunicação HTTPS com S3
- ✅ Metadados para rastreamento

---

### 5. Auditoria e Logging

Todos os eventos são registrados em `/var/log/ledger-backup.log`:

```
[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
[2025-05-26 02:00:00] [INFO] Host: ledger-db.internal.hvt.io:5432
[2025-05-26 02:00:00] [INFO] Banco: ledger_prod
[2025-05-26 02:00:01] [INFO] Validando pré-requisitos do sistema...
[2025-05-26 02:00:01] [INFO] ✓ Todos os pré-requisitos validados com sucesso
[2025-05-26 02:00:02] [INFO] Recuperando credenciais do AWS Secrets Manager...
[2025-05-26 02:00:02] [INFO] ✓ Credenciais recuperadas com sucesso
[2025-05-26 02:00:03] [INFO] Testando conexão com banco de dados...
[2025-05-26 02:00:03] [INFO] ✓ Conexão com banco de dados validada
[2025-05-26 02:00:05] [INFO] Iniciando dump do banco de dados PostgreSQL...
[2025-05-26 02:05:30] [INFO] ✓ Dump PostgreSQL concluído com sucesso (2456789 bytes)
[2025-05-26 02:05:45] [INFO] Compactando arquivo de backup com gzip...
[2025-05-26 02:06:10] [INFO] ✓ Compressão gzip concluída (345678 bytes)
[2025-05-26 02:06:25] [INFO] Iniciando upload para S3...
[2025-05-26 02:06:45] [INFO] ✓ Upload S3 concluído com sucesso
[2025-05-26 02:06:50] [INFO] ========== BACKUP CONCLUÍDO COM SUCESSO ==========
```

---

## Setup e Instalação

### Pré-requisitos

**Na Instância EC2:**

1. ✅ Ubuntu 22.04 LTS ou 24.04 LTS
2. ✅ Acesso root ou sudo
3. ✅ Conectividade com PostgreSQL (porta 5432)
4. ✅ IAM Role atribuída à instância
5. ✅ Espaço em disco (50 GB recomendado em `/var/backups`)

**Na AWS:**

1. ✅ Bucket S3 criado: `hvt-ledger-backups`
2. ✅ Secret no Secrets Manager: `ledger-db-backup-credentials`
3. ✅ IAM Role com permissões S3 e Secrets Manager

---

### Passo 1: Instalar Ferramentas Necessárias

```bash
# SSH na instância EC2
ssh -i sua-chave.pem ubuntu@seu-ip-ec2

# Atualizar pacotes
sudo apt-get update
sudo apt-get upgrade -y

# Instalar dependências
sudo apt-get install -y \
    postgresql-client \
    awscli \
    jq \
    curl

# Verificar instalação
pg_dump --version
aws --version
jq --version
```

---

### Passo 2: Criar Diretórios

```bash
# Criar diretório de backup
sudo mkdir -p /var/backups/ledger
sudo chown ubuntu:ubuntu /var/backups/ledger
sudo chmod 755 /var/backups/ledger

# Criar arquivo de log
sudo touch /var/log/ledger-backup.log
sudo chmod 644 /var/log/ledger-backup.log

# Criar diretório do script
sudo mkdir -p /opt/ledger-backup
sudo chown ubuntu:ubuntu /opt/ledger-backup
```

---

### Passo 3: Copiar Script de Backup

```bash
# Copiar do local ou via curl
sudo cp ledger-backup.sh /opt/ledger-backup/ledger-backup.sh
sudo chmod 750 /opt/ledger-backup/ledger-backup.sh

# OU fazer download
sudo curl -o /opt/ledger-backup/ledger-backup.sh \
    https://seu-repository/ledger-backup.sh
sudo chmod 750 /opt/ledger-backup/ledger-backup.sh
```

---

### Passo 4: Criar Secret no AWS Secrets Manager

```bash
# Criar secret com a senha do PostgreSQL
aws secretsmanager create-secret \
  --name ledger-db-backup-credentials \
  --description "Credenciais de backup para PostgreSQL Ledger" \
  --secret-string '{"password":"SUA_SENHA_DO_POSTGRES"}' \
  --region us-east-1

# Verificar criação
aws secretsmanager get-secret-value \
  --secret-id ledger-db-backup-credentials \
  --region us-east-1
```

---

### Passo 5: Verificar IAM Role

```bash
# Verificar identidade IAM
aws sts get-caller-identity

# Output esperado:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:instance-profile/ledger-backup-role"
# }
```

Se não funcionar, a instância precisa de uma IAM Role. Anexe a role com as permissões listadas na seção de Segurança.

---

### Passo 6: Testar Script Manualmente

```bash
# Executar script manualmente (primeira vez)
sudo /opt/ledger-backup/ledger-backup.sh

# Verificar logs
sudo tail -f /var/log/ledger-backup.log

# Verificar se arquivo foi criado
ls -lh /var/backups/ledger/

# Verificar se foi enviado ao S3
aws s3 ls s3://hvt-ledger-backups/postgres-backups/ --region us-east-1
```

---

### Passo 7: Configurar Cron Job

#### Opção A: Usando Script de Instalação

```bash
# Copiar script de instalação
sudo cp install-ledger-backup-cron.sh /tmp/

# Executar como root
sudo bash /tmp/install-ledger-backup-cron.sh

# Verificar crontab
sudo crontab -l | grep ledger
```

#### Opção B: Configurar Manualmente

```bash
# Editar crontab
sudo crontab -e

# Adicionar esta linha (Diariamente às 02:00)
0 2 * * * /opt/ledger-backup/ledger-backup.sh

# Ou (A cada 6 horas)
# 0 */6 * * * /opt/ledger-backup/ledger-backup.sh

# Salvar (:wq em VI)
```

#### Opção C: Usar cron.d

```bash
# Criar arquivo em /etc/cron.d
sudo tee /etc/cron.d/ledger-backup > /dev/null << 'EOF'
# Backup diário do PostgreSQL Ledger
0 2 * * * root /opt/ledger-backup/ledger-backup.sh >> /var/log/ledger-backup.log 2>&1
EOF

# Verificar
sudo cat /etc/cron.d/ledger-backup
```

---

## Monitoramento

### Verificar Status do Backup

```bash
# Ver últimas linhas do log
sudo tail -100 /var/log/ledger-backup.log

# Ver apenas erros
sudo grep "ERROR" /var/log/ledger-backup.log

# Contar backups realizados com sucesso
sudo grep "BACKUP CONCLUÍDO COM SUCESSO" /var/log/ledger-backup.log | wc -l

# Ver últimas 24 horas
sudo journalctl -u cron --since "24 hours ago" | grep ledger
```

---

### Verificar S3

```bash
# Listar backups no S3
aws s3 ls s3://hvt-ledger-backups/postgres-backups/ \
    --region us-east-1 \
    --recursive \
    --human-readable \
    --summarize

# Verificar metadados de um backup
aws s3api head-object \
    --bucket hvt-ledger-backups \
    --key postgres-backups/ledger_20250526_020000.sql.gz \
    --region us-east-1
```

---

### Verificar Disco Local

```bash
# Espaço em disco
df -h /var/backups/ledger

# Backups locais mais recentes
ls -lh /var/backups/ledger/ | tail -10

# Tamanho total de backups locais
du -sh /var/backups/ledger

# Arquivos com mais de 30 dias
find /var/backups/ledger -mtime +30 -type f
```

---

### Configurar Alertas CloudWatch (Opcional)

```bash
# Criar métrica customizada para falhas de backup
aws cloudwatch put-metric-alarm \
  --alarm-name "ledger-backup-failure" \
  --alarm-description "Alerta para falha no backup do PostgreSQL Ledger" \
  --metric-name "BackupFailures" \
  --namespace "PostgreSQL/Ledger" \
  --statistic Sum \
  --period 3600 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1

# Ou monitorar via CloudWatch Logs Insights
# Buscar erros no log:
# fields @timestamp, @message | filter @message like /ERROR/
```

---

## Troubleshooting

### Problema 1: "Ferramenta pg_dump não encontrada"

**Erro no log:**
```
[2025-05-26 02:00:01] [ERROR] Ferramenta obrigatória não encontrada: pg_dump
```

**Solução:**
```bash
# Instalar postgresql-client
sudo apt-get install -y postgresql-client

# Verificar
pg_dump --version
```

---

### Problema 2: "Não foi possível conectar ao banco de dados"

**Erro no log:**
```
[2025-05-26 02:00:03] [ERROR] Não foi possível conectar ao banco de dados ledger-db.internal.hvt.io:5432
```

**Checklist:**
```bash
# 1. Testar conectividade de rede
ping ledger-db.internal.hvt.io
nc -zv ledger-db.internal.hvt.io 5432

# 2. Testar com psql
psql -h ledger-db.internal.hvt.io -p 5432 -U backup_user -d ledger_prod -c "SELECT 1;"

# 3. Verificar grupo de segurança EC2
# - Inbound rule: port 5432 do IP da EC2 deve estar permitido

# 4. Verificar status do PostgreSQL
ssh seu-banco
sudo systemctl status postgresql
```

---

### Problema 3: "Falha ao recuperar credenciais do Secrets Manager"

**Erro no log:**
```
[2025-05-26 02:00:02] [ERROR] Falha ao recuperar credenciais do Secrets Manager (ledger-db-backup-credentials)
```

**Checklist:**
```bash
# 1. Verificar IAM Role
aws sts get-caller-identity

# 2. Testar acesso a Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id ledger-db-backup-credentials \
  --region us-east-1

# 3. Verificar política IAM
# A role deve ter:
# - secretsmanager:GetSecretValue
# - secretsmanager:DescribeSecret
```

---

### Problema 4: "Upload S3 falhou"

**Erro no log:**
```
[2025-05-26 02:06:45] [ERROR] Upload S3 falhou com exit code 254
```

**Checklist:**
```bash
# 1. Testar conectividade S3
aws s3 ls

# 2. Testar upload manualmente
echo "test" > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://hvt-ledger-backups/test.txt

# 3. Verificar permissões IAM
# A role deve ter:
# - s3:PutObject
# - s3:ListBucket
# - s3:DeleteObject (para limpeza automática)

# 4. Verificar bucket existe
aws s3api list-buckets | grep hvt-ledger-backups
```

---

### Problema 5: "pg_dump falhou com exit code 1"

**Erro no log:**
```
[2025-05-26 02:00:05] [ERROR] pg_dump falhou com exit code 1
```

**Checklist:**
```bash
# 1. Testar credenciais PostgreSQL
PGPASSWORD="sua_senha" pg_dump \
  -h ledger-db.internal.hvt.io \
  -p 5432 \
  -U backup_user \
  -d ledger_prod \
  --no-password \
  -F c \
  -f /tmp/test.dump

# 2. Verificar permissões do usuário backup_user
psql -h ledger-db.internal.hvt.io -U backup_user -d ledger_prod -c "\du"

# 3. Verificar se banco está online
pg_isready -h ledger-db.internal.hvt.io -p 5432

# 4. Ver erro detalhado
tail -50 /var/log/ledger-backup.log
```

---

### Problema 6: Cron job não está executando

**Verificar:**
```bash
# 1. Verificar se cron está rodando
sudo systemctl status cron

# 2. Ver crontab configurado
sudo crontab -l

# 3. Ver logs de execução cron
sudo journalctl -u cron -n 50

# 4. Testar execução manual
sudo /opt/ledger-backup/ledger-backup.sh

# 5. Verificar se script tem permissão de execução
ls -l /opt/ledger-backup/ledger-backup.sh
# Deve ser: -rwxr-x--- (750)
```

---

## Performance e Otimização

### Tamanho Esperado de Backup

```
Banco 100 GB (descompactado)
  ↓
pg_dump (.sql): ~100 GB
  ↓
gzip -9: ~10-20 GB (10-20% do original)
```

### Tempo de Execução Esperado

```
pg_dump (100 GB):     5-15 minutos
gzip -9:              5-10 minutos
S3 Upload (20 GB):    5-15 minutos (depende da rede)
TOTAL:                15-40 minutos
```

### Reduzir Tempo de Backup

```bash
# 1. Usar pg_dump com jobs paralelos (pg 10+)
pg_dump -h ... -d ... -F d -j 4 -f /backup/ledger_backup/
# -F d: directory format
# -j 4: usar 4 jobs paralelos

# 2. Executar em horário de baixa carga
# Mudar cron para 03:00 ou 04:00 da manhã

# 3. Usar storage class S3 INTELLIGENT_TIERING
# Reduz custos para backups acessados raramente
```

---

## Considerações de Custo (AWS)

```
S3 Standard Storage:
- $0.023 por GB/mês
- 20 GB backup × $0.023 = $0.46/mês × 12 = $5.52/ano

Secrets Manager:
- $0.40 por secret/mês = $4.80/ano

Data Transfer (S3):
- Primeira cópia é grátis (dentro da mesma região)
- Downloads: $0.09 por GB (fora da região)

TOTAL ESTIMADO: $10-20/ano (com 20 GB backup)
```

---

## Checklist de Deploy

- [ ] Instalar postgresql-client, awscli, jq
- [ ] Criar diretórios: /var/backups/ledger, logs
- [ ] Copiar script ledger-backup.sh para /opt/ledger-backup/
- [ ] Criar IAM Role com permissões S3 e Secrets Manager
- [ ] Criar secret no AWS Secrets Manager
- [ ] Testar script manualmente: `sudo /opt/ledger-backup/ledger-backup.sh`
- [ ] Configurar cron job
- [ ] Monitorar primeira execução automática
- [ ] Configurar alertas (opcional)
- [ ] Documentar para o time de SRE

---

## Suporte e Contato

Para dúvidas ou problemas:

1. Verificar logs: `/var/log/ledger-backup.log`
2. Executar manualmente para ver erros
3. Consultar seção de Troubleshooting acima
4. Contatar time de SRE/DevOps

---

**Documento versão 1.0 - Maio 2025**
