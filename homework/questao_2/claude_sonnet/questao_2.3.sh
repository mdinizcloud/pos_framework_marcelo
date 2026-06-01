#!/bin/bash

# ==============================================================================
# DESCRIÇÃO: Script de backup diário do banco de dados PostgreSQL (Ledger).
#            Realiza o dump, compactação, upload para o AWS S3 e rotação local/remota.
# AMBIENTE: Ubuntu 22.04 / 24.04 LTS (Executado via Cron)
# ==============================================================================

# Configurações estritas de Bash para tratamento de erros
# -e: Para imediatamente se um comando falhar
# -u: Para se uma variável não definida for utilizada
# -o pipefail: Garante o exit code correto em operações com '|'
set -Eeuo pipefail

# ==========================================
# CONFIGURAÇÕES E VARIÁVEIS
# ==========================================
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"
SECRET_NAME="ledger/prod/backup_user" # Nome do segredo no AWS Secrets Manager
REGION="us-east-1"                     # Altere para a região correta do seu bucket/segredo

BACKUP_DIR="/var/backups/ledger"
LOG_FILE="/var/log/ledger-backup.log"
S3_BUCKET="s3://hvt-ledger-backups"
RETENCAO_DIAS=30

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"
PGPASS_FILE="${HOME}/.pgpass_ledger_${TIMESTAMP}"

# ==========================================
# FUNÇÃO DE LOGGING
# ==========================================
log() {
    local LEVEL="$1"
    local MSG="$2"
    echo "$(date +"%Y-%m-%d %H:%M:%S") [${LEVEL}] - ${MSG}" | tee -a "${LOG_FILE}"
}

# ==========================================
# TRATAMENTO DE FALHAS (TRAP)
# ==========================================
failure_handler() {
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        log "ERROR" "O backup falhou na etapa anterior. Encerrando script com código ${EXIT_CODE}."
    fi
    # Limpeza de segurança: Remove o arquivo .pgpass temporário se ele existir
    if [ -f "${PGPASS_FILE}" ]; then
        rm -f "${PGPASS_FILE}"
    fi
}
# Ativa o handler para qualquer saída do script (sucesso ou falha)
trap failure_handler EXIT

# ==========================================
# EXECUÇÃO DO BACKUP
# ==========================================

log "INFO" "Iniciando o processo de backup do banco [${DB_NAME}]..."

# 1. Garantir que os diretórios e arquivos necessários existem
mkdir -p "${BACKUP_DIR}"
touch "${LOG_FILE}"

# 2. Busca a senha de forma segura no AWS Secrets Manager (Requer IAM Role na EC2)
log "INFO" "Buscando credenciais no AWS Secrets Manager..."
DB_PASS=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRET_NAME}" \
    --region "${REGION}" \
    --query SecretString \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    log "CRITICAL" "Falha ao recuperar a senha do Secrets Manager. Verifique a IAM Role."
    exit 1
fi

# 3. Configura o arquivo .pgpass temporário para o pg_dump não pedir senha interativa
log "INFO" "Configurando credenciais locais temporárias..."
echo "${DB_HOST}:${DB_PORT}:${DB_NAME}:${DB_USER}:${DB_PASS}" > "${PGPASS_FILE}"
chmod 600 "${PGPASS_FILE}"
export PGPASSFILE="${PGPASS_FILE}"

# 4. Executa o pg_dump e realiza o append do gzip via pipeline
log "INFO" "Executando pg_dump e compactando com gzip..."
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -F c "${DB_NAME}" | gzip > "${BACKUP_FILE}"

log "INFO" "Backup local gerado com sucesso: ${BACKUP_FILE}"

# 5. Upload do arquivo compactado para o Bucket S3
log "INFO" "Iniciando upload para o bucket S3: ${S3_BUCKET}"
aws s3 cp "${BACKUP_FILE}" "${S3_BUCKET}/${DB_NAME}_${TIMESTAMP}.sql.gz" 2>&1

log "INFO" "Upload concluído com sucesso para o S3."

# 6. Limpeza/Retenção Local (Remover arquivos com mais de 30 dias na EC2)
log "INFO" "Executando política de retenção local (Arquivos > ${RETENCAO_DIAS} dias)..."
find "${BACKUP_DIR}" -type f -name "${DB_NAME}_*.sql.gz" -mtime +"${RETENCAO_DIAS}" -exec rm -f {} \;

# 7. Limpeza/Retenção no S3 (Remover objetos antigos baseados na data)
# Nota: O ideal corporativo é usar S3 Lifecycle Rules, mas implementamos via CLI conforme solicitado.
log "INFO" "Executando política de retenção no S3 (Objetos > ${RETENCAO_DIAS} dias)..."
DATA_LIMITE=$(date -d "${RETENCAO_DIAS} days ago" +"%Y-%m-%d")

aws s3api list-objects-v2 --bucket "${S3_BUCKET#s3://}" --query "Contents[?LastModified<='${DATA_LIMITE}'].{Key:Key}" --output text | xargs -I {} sh -c '
    if [ "{}" != "None" ]; then
        log "INFO" "Removendo objeto antigo do S3: {}"
        aws s3 rm "'${S3_BUCKET}'/{}"
    fi
'

log "INFO" "Todo o processo de backup e retenção foi concluído com SUCESSO."
exit 0