#!/bin/bash

################################################################################
# SCRIPT: Backup Diário - Banco de Dados PostgreSQL (Ledger)
# 
# DESCRIÇÃO:
# Script profissional de backup para PostgreSQL com integração AWS S3,
# retenção automática de 30 dias, logging completo e tratamento robusto de erros.
# 
# Desenvolvido para: Ubuntu 22.04 LTS / 24.04 LTS
# Rodedor: IAM Role na instância EC2 (sem credenciais hardcoded)
# 
# FLUXO:
# 1. Recupera credenciais do AWS Secrets Manager via IAM Role
# 2. Realiza dump do banco PostgreSQL com pg_dump
# 3. Compacta o dump com gzip
# 4. Faz upload para S3 com metadados de retenção
# 5. Remove backups locais com mais de 30 dias
# 6. Remove backups no S3 com mais de 30 dias (Lifecycle Policy)
# 7. Registra todas as operações em log com timestamp
# 8. Implementa tratamento de erros em cada etapa com exit codes
#
################################################################################

# ==============================================================================
# CONFIGURAÇÃO DE VARIÁVEIS GLOBAIS
# ==============================================================================

# Configurações do Banco de Dados
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"

# Configurações de Diretórios e Arquivos
BACKUP_DIR="/var/backups/ledger"
LOG_FILE="/var/log/ledger-backup.log"
LOCK_FILE="/tmp/ledger-backup.lock"

# Configurações AWS
AWS_REGION="us-east-1"  # Ajuste conforme sua região
S3_BUCKET="hvt-ledger-backups"
S3_PREFIX="postgres-backups"
SECRETS_NAME="ledger-db-backup-credentials"  # Nome do secret no AWS Secrets Manager

# Configuração de Retenção (dias)
RETENTION_DAYS=30

# Timestamp para nomes de arquivo
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_ONLY=$(date +%Y%m%d)

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================

# Função: Log com timestamp
# Registra mensagens no arquivo de log com data/hora formatada
log_message() {
    local message="$1"
    local log_level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Escreve tanto no log quanto no stdout para auditoria
    echo "[${timestamp}] [${log_level}] ${message}" | tee -a "${LOG_FILE}"
}

# Função: Log de erro e exit com código de erro
# Registra erro, envia para stderr e encerra com exit code 1
log_error() {
    local message="$1"
    log_message "ERRO: ${message}" "ERROR" >&2
    exit 1
}

# Função: Validar pré-requisitos
# Verifica se todas as ferramentas necessárias estão instaladas
validate_prerequisites() {
    log_message "Validando pré-requisitos do sistema..."
    
    local required_tools=("pg_dump" "gzip" "aws" "jq" "aws")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "${tool}" &> /dev/null; then
            log_error "Ferramenta obrigatória não encontrada: ${tool}"
        fi
    done
    
    log_message "✓ Todos os pré-requisitos validados com sucesso"
}

# Função: Validar diretórios
# Verifica se o diretório de backup existe e é acessível
validate_directories() {
    log_message "Validando diretórios..."
    
    # Cria diretório se não existir
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_message "Criando diretório de backup: ${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}" || log_error "Falha ao criar diretório ${BACKUP_DIR}"
    fi
    
    # Verifica permissões de escrita
    if [[ ! -w "${BACKUP_DIR}" ]]; then
        log_error "Diretório ${BACKUP_DIR} não possui permissão de escrita"
    fi
    
    log_message "✓ Diretórios validados com sucesso"
}

# Função: Obter credenciais do AWS Secrets Manager
# Recupera senha e configurações de forma segura via IAM Role
# Não armazena credenciais em variáveis globais persistentes
get_db_credentials() {
    log_message "Recuperando credenciais do AWS Secrets Manager..."
    
    # Valida IAM Role na instância EC2
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "IAM Role não disponível ou sem credenciais válidas"
    fi
    
    # Recupera secret do Secrets Manager
    local secret_json
    secret_json=$(aws secretsmanager get-secret-value \
        --secret-id "${SECRETS_NAME}" \
        --region "${AWS_REGION}" \
        --query 'SecretString' \
        --output text 2>/dev/null)
    
    if [[ -z "${secret_json}" ]]; then
        log_error "Falha ao recuperar credenciais do Secrets Manager (${SECRETS_NAME})"
    fi
    
    # Extrai a senha do JSON retornado
    # Esperado: {"password":"sua_senha_aqui"}
    DB_PASSWORD=$(echo "${secret_json}" | jq -r '.password' 2>/dev/null)
    
    if [[ -z "${DB_PASSWORD}" ]] || [[ "${DB_PASSWORD}" == "null" ]]; then
        log_error "Campo 'password' não encontrado ou inválido no secret"
    fi
    
    log_message "✓ Credenciais recuperadas com sucesso"
}

# Função: Testar conexão com banco de dados
# Valida se há conectividade com o PostgreSQL antes de fazer o dump
test_db_connection() {
    log_message "Testando conexão com banco de dados: ${DB_HOST}:${DB_PORT}/${DB_NAME}..."
    
    # Usa pg_isready para validar conexão sem criar transações
    if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" &> /dev/null; then
        log_error "Não foi possível conectar ao banco de dados ${DB_HOST}:${DB_PORT}"
    fi
    
    log_message "✓ Conexão com banco de dados validada"
}

# Função: Executar pg_dump
# Realiza o dump do banco com compressão custom (para melhor compressão posterior)
execute_pg_dump() {
    log_message "Iniciando dump do banco de dados PostgreSQL..."
    
    local dump_file="${BACKUP_DIR}/ledger_${TIMESTAMP}.sql"
    
    # Exporta a senha em variável de ambiente (sem exposição em linha de comando)
    export PGPASSWORD="${DB_PASSWORD}"
    
    # pg_dump com:
    # -h: host do banco
    # -p: porta
    # -U: usuário
    # -d: banco de dados
    # --no-password: não solicita senha (usa PGPASSWORD)
    # -F: formato customizado (melhor compressão)
    # -v: verbose (para auditoria)
    pg_dump \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --no-password \
        -F c \
        -v \
        -f "${dump_file}" \
        2>> "${LOG_FILE}"
    
    local pg_dump_exit_code=$?
    
    # Desprotege a variável de ambiente após uso
    unset PGPASSWORD
    
    # Valida exit code do pg_dump
    if [[ ${pg_dump_exit_code} -ne 0 ]]; then
        log_error "pg_dump falhou com exit code ${pg_dump_exit_code}"
    fi
    
    # Valida se arquivo foi criado
    if [[ ! -f "${dump_file}" ]]; then
        log_error "Arquivo de dump não foi criado: ${dump_file}"
    fi
    
    # Valida tamanho do arquivo (deve ser > 0 bytes)
    local dump_size=$(stat -f%z "${dump_file}" 2>/dev/null || stat -c%s "${dump_file}" 2>/dev/null)
    if [[ ${dump_size} -le 0 ]]; then
        log_error "Arquivo de dump vazio ou inválido (tamanho: ${dump_size} bytes)"
    fi
    
    log_message "✓ Dump PostgreSQL concluído com sucesso (${dump_size} bytes)"
    echo "${dump_file}"  # Retorna caminho do arquivo para próxima etapa
}

# Função: Compactar arquivo de dump
# Realiza compressão gzip do dump SQL
compress_backup() {
    local dump_file="$1"
    
    log_message "Compactando arquivo de backup com gzip..."
    
    local compressed_file="${dump_file}.gz"
    
    # gzip com:
    # -v: verbose
    # -9: máxima compressão
    gzip -v -9 "${dump_file}" 2>> "${LOG_FILE}"
    local gzip_exit_code=$?
    
    if [[ ${gzip_exit_code} -ne 0 ]]; then
        log_error "gzip falhou com exit code ${gzip_exit_code} no arquivo ${dump_file}"
    fi
    
    # Valida se arquivo compactado foi criado
    if [[ ! -f "${compressed_file}" ]]; then
        log_error "Arquivo compactado não foi criado: ${compressed_file}"
    fi
    
    # Valida tamanho do arquivo compactado
    local compressed_size=$(stat -f%z "${compressed_file}" 2>/dev/null || stat -c%s "${compressed_file}" 2>/dev/null)
    if [[ ${compressed_size} -le 0 ]]; then
        log_error "Arquivo compactado vazio ou inválido (tamanho: ${compressed_size} bytes)"
    fi
    
    log_message "✓ Compressão gzip concluída (${compressed_size} bytes)"
    echo "${compressed_file}"  # Retorna caminho do arquivo compactado
}

# Função: Upload para S3
# Envia arquivo compactado para S3 com metadados e validação
upload_to_s3() {
    local compressed_file="$1"
    local filename=$(basename "${compressed_file}")
    
    log_message "Iniciando upload para S3: s3://${S3_BUCKET}/${S3_PREFIX}/${filename}..."
    
    # aws s3 cp com:
    # --storage-class: STANDARD ou INTELLIGENT_TIERING
    # --metadata: metadados customizados para auditoria
    # --sse: criptografia no lado do servidor (SSE-S3)
    aws s3 cp "${compressed_file}" \
        "s3://${S3_BUCKET}/${S3_PREFIX}/${filename}" \
        --region "${AWS_REGION}" \
        --storage-class STANDARD \
        --metadata "backup-timestamp=${TIMESTAMP},database=${DB_NAME},hostname=$(hostname)" \
        --sse AES256 \
        --quiet \
        2>> "${LOG_FILE}"
    
    local s3_upload_exit_code=$?
    
    if [[ ${s3_upload_exit_code} -ne 0 ]]; then
        log_error "Upload S3 falhou com exit code ${s3_upload_exit_code}"
    fi
    
    log_message "✓ Upload S3 concluído com sucesso"
}

# Função: Limpar arquivos locais antigos
# Remove arquivos de backup locais com mais de 30 dias
cleanup_local_backups() {
    log_message "Limpando backups locais com mais de ${RETENTION_DAYS} dias..."
    
    # find com:
    # -maxdepth 1: apenas arquivos no diretório raiz
    # -name "ledger_*.sql.gz": padrão de arquivo de backup
    # -mtime +${RETENTION_DAYS}: modificado há mais de N dias
    # -type f: apenas arquivos (não diretórios)
    local files_deleted=0
    
    while IFS= read -r file; do
        if [[ -f "${file}" ]]; then
            rm -f "${file}"
            local rm_exit_code=$?
            
            if [[ ${rm_exit_code} -eq 0 ]]; then
                log_message "Arquivo removido: ${file}"
                ((files_deleted++))
            else
                log_message "AVISO: Falha ao remover arquivo ${file}" "WARNING"
            fi
        fi
    done < <(find "${BACKUP_DIR}" -maxdepth 1 -name "ledger_*.sql.gz" -mtime +${RETENTION_DAYS} -type f)
    
    log_message "✓ Limpeza local concluída (${files_deleted} arquivos removidos)"
}

# Função: Limpar backups antigos no S3
# Remove backups no S3 com mais de 30 dias (usando S3 List + Delete)
cleanup_s3_backups() {
    log_message "Limpando backups no S3 com mais de ${RETENTION_DAYS} dias..."
    
    # Calcula a data limite (30 dias atrás)
    local retention_date=$(date -u -d "${RETENTION_DAYS} days ago" +%Y-%m-%d 2>/dev/null || date -u -v-${RETENTION_DAYS}d +%Y-%m-%d)
    
    log_message "Data limite de retenção: ${retention_date}"
    
    # Lista objetos do S3
    local s3_files
    s3_files=$(aws s3api list-objects-v2 \
        --bucket "${S3_BUCKET}" \
        --prefix "${S3_PREFIX}/" \
        --region "${AWS_REGION}" \
        --query "Contents[].{Key:Key,LastModified:LastModified}" \
        --output json 2>/dev/null)
    
    if [[ -z "${s3_files}" ]] || [[ "${s3_files}" == "[]" ]]; then
        log_message "Nenhum arquivo S3 encontrado para limpeza"
        return 0
    fi
    
    # Processa cada arquivo e remove os antigos
    local files_deleted=0
    echo "${s3_files}" | jq -r '.[] | "\(.LastModified) \(.Key)"' | while read -r last_modified key; do
        # Extrai apenas a data (YYYY-MM-DD)
        local file_date=$(echo "${last_modified}" | cut -d'T' -f1)
        
        # Compara datas
        if [[ "${file_date}" < "${retention_date}" ]]; then
            aws s3api delete-object \
                --bucket "${S3_BUCKET}" \
                --key "${key}" \
                --region "${AWS_REGION}" \
                2>> "${LOG_FILE}"
            
            local delete_exit_code=$?
            if [[ ${delete_exit_code} -eq 0 ]]; then
                log_message "Objeto S3 removido: s3://${S3_BUCKET}/${key}"
                ((files_deleted++))
            else
                log_message "AVISO: Falha ao remover objeto S3: ${key}" "WARNING"
            fi
        fi
    done
    
    log_message "✓ Limpeza S3 concluída (${files_deleted} arquivos removidos)"
}

# Função: Criar lock para evitar execução concorrente
# Implementa mutex para garantir que apenas uma instância rode por vez
create_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local lock_age=$(($(date +%s) - $(stat -f%m "${LOCK_FILE}" 2>/dev/null || stat -c%Y "${LOCK_FILE}" 2>/dev/null)))
        
        # Se lock é mais antigo que 24 horas, remove (assumindo crash da execução anterior)
        if [[ ${lock_age} -gt 86400 ]]; then
            log_message "Lock file obsoleto removido (idade: ${lock_age}s)"
            rm -f "${LOCK_FILE}"
        else
            log_error "Backup já está em execução (lock file: ${LOCK_FILE}). Abortando para evitar concorrência."
        fi
    fi
    
    # Cria lock file
    touch "${LOCK_FILE}" || log_error "Falha ao criar lock file: ${LOCK_FILE}"
    log_message "Lock file criado: ${LOCK_FILE}"
}

# Função: Remover lock
# Remove mutex após conclusão (sucesso ou falha)
remove_lock() {
    rm -f "${LOCK_FILE}"
    log_message "Lock file removido"
}

# Função: Trap para limpeza em caso de interrupção
# Implementa handlers para signals (SIGTERM, SIGINT, etc)
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_message "========== BACKUP CONCLUÍDO COM SUCESSO ==========" "SUCCESS"
    else
        log_message "========== BACKUP FALHOU COM CÓDIGO ${exit_code} ==========" "ERROR"
    fi
    
    remove_lock
    exit ${exit_code}
}

# ==============================================================================
# MAIN - FLUXO PRINCIPAL
# ==============================================================================

main() {
    # Registra início da execução
    log_message "========== INICIANDO BACKUP DO BANCO DE DADOS =========="
    log_message "Host: ${DB_HOST}:${DB_PORT}"
    log_message "Banco: ${DB_NAME}"
    log_message "Bucket S3: s3://${S3_BUCKET}/${S3_PREFIX}"
    log_message "Retenção: ${RETENTION_DAYS} dias"
    
    # Setup trap para limpeza em caso de interrupção
    trap cleanup_on_exit EXIT
    trap 'log_error "Script interrompido por sinal de término"' SIGTERM SIGINT
    
    # Cria lock para evitar execução concorrente
    create_lock
    
    # Valida pré-requisitos
    validate_prerequisites
    
    # Valida diretórios
    validate_directories
    
    # Recupera credenciais do Secrets Manager
    get_db_credentials
    
    # Testa conexão com banco antes de fazer dump
    test_db_connection
    
    # Executa pg_dump
    local dump_file
    dump_file=$(execute_pg_dump) || log_error "Falha em execute_pg_dump"
    
    # Compacta arquivo de backup
    local compressed_file
    compressed_file=$(compress_backup "${dump_file}") || log_error "Falha em compress_backup"
    
    # Upload para S3
    upload_to_s3 "${compressed_file}" || log_error "Falha em upload_to_s3"
    
    # Limpeza de arquivos locais antigos
    cleanup_local_backups
    
    # Limpeza de backups antigos no S3
    cleanup_s3_backups
    
    log_message "✓ Todas as etapas completadas com sucesso!"
    return 0
}

# ==============================================================================
# EXECUTA MAIN
# ==============================================================================

# Executa função principal
main "$@"

# Exit code é tratado por cleanup_on_exit via trap
