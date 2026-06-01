#!/bin/bash

# ==============================================================================
# Script de Backup Diário: PostgreSQL (Ledger Prod)
# SO: Ubuntu 24.04 LTS
# Autor: SRE Sênior
# ==============================================================================

# Definição de Variáveis de Ambiente e Caminhos
LOG_FILE="/var/log/ledger-backup.log"
BACKUP_DIR="/var/backups/ledger"
S3_BUCKET="s3://hvt-ledger-backups"
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"
SECRET_ID="prod/ledger/db-credentials" # Substitua pelo ID/Nome exato do seu Secret na AWS
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/ledger_prod_${TIMESTAMP}.sql"
GZ_FILE="${BACKUP_FILE}.gz"

# Garante que o diretório de backup e o arquivo de log existam
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

# ==============================================================================
# Funções Auxiliares
# ==============================================================================

# Função para registrar logs com Timestamp
log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

# Função para registrar falhas e encerrar o script (Exit 1)
handle_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    # Limpa a variável de senha da memória por segurança antes de sair
    unset PGPASSWORD
    exit 1
}

# ==============================================================================
# Execução Principal
# ==============================================================================

log_info "Iniciando o job de backup diário do banco: $DB_NAME"

# 1. Obtenção Segura de Credenciais
log_info "Buscando credenciais no AWS Secrets Manager..."
# O comando aws secretsmanager assume que a EC2 tem uma IAM Role apropriada.
# Redirecionamos os erros para o log. Em caso de falha, acionamos o handle_error.
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --query SecretString --output text 2>> "$LOG_FILE")
if [ $? -ne 0 ]; then
    handle_error "Falha ao obter o secret no AWS Secrets Manager."
fi

# Extrai a senha do JSON e exporta a variável de ambiente nativa do PostgreSQL
export PGPASSWORD=$(echo "$SECRET_JSON" | jq -r .password 2>> "$LOG_FILE")
if [ -z "$PGPASSWORD" ] || [ "$PGPASSWORD" == "null" ]; then
    handle_error "Falha ao extrair a senha usando jq."
fi
log_info "Credenciais obtidas com sucesso."

# 2. Execução do Dump (pg_dump)
log_info "Iniciando o dump do banco de dados (pg_dump)..."
# Redireciona stdout e stderr para o log file para auditoria
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F p -f "$BACKUP_FILE" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log_info "pg_dump concluído com sucesso."
else
    handle_error "Falha na execução do pg_dump."
fi

# Limpa a senha do ambiente assim que o pg_dump for concluído para minimizar exposição
unset PGPASSWORD

# 3. Compactação (gzip)
log_info "Iniciando compactação via gzip..."
# Compacta o arquivo SQL, substituindo-o pelo arquivo .gz
gzip "$BACKUP_FILE" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log_info "Compactação concluída com sucesso. Arquivo gerado: $GZ_FILE"
else
    handle_error "Falha ao compactar o arquivo com gzip."
fi

# 4. Upload para o S3
log_info "Iniciando upload para o S3 ($S3_BUCKET)..."
aws s3 cp "$GZ_FILE" "$S3_BUCKET/" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log_info "Upload para o S3 concluído com sucesso."
else
    handle_error "Falha durante o upload para o S3."
fi

# 5. Limpeza e Retenção (Arquivos Locais)
log_info "Executando limpeza de backups locais com mais de 30 dias..."
# Procura arquivos .gz modificados há mais de 30 dias e os deleta.
find "$BACKUP_DIR" -type f -name "ledger_prod_*.sql.gz" -mtime +30 -exec rm {} \; >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log_info "Limpeza de arquivos locais antigos concluída."
else
    handle_error "Falha ao realizar a limpeza de arquivos locais antigos."
fi

# Finalização
log_info "Job de backup diário finalizado com sucesso."
exit 0