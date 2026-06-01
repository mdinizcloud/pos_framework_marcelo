#!/bin/bash

################################################################################
# SCRIPT DE TESTE E VALIDAÇÃO - Backup PostgreSQL Ledger
#
# Propósito: Validar o ambiente antes de ativar o backup em produção
# Uso: sudo bash test-ledger-backup.sh
#
# Checklist de Validação:
# ✓ Ferramentas instaladas
# ✓ Conectividade com PostgreSQL
# ✓ Credenciais no Secrets Manager
# ✓ IAM Role configurado
# ✓ Bucket S3 acessível
# ✓ Permissões de disco
# ✓ Script pode ser executado
#
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
SCRIPT_PATH="/opt/ledger-backup/ledger-backup.sh"
LOG_FILE="/var/log/ledger-backup.log"
BACKUP_DIR="/var/backups/ledger"
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
S3_BUCKET="hvt-ledger-backups"
SECRETS_NAME="ledger-db-backup-credentials"
AWS_REGION="us-east-1"

TESTS_PASSED=0
TESTS_FAILED=0

# Função para imprimir resultado do teste
print_test_result() {
    local test_name="$1"
    local result="$2"
    
    if [[ "${result}" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} ${test_name}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} ${test_name}"
        ((TESTS_FAILED++))
    fi
}

# Função para imprimir seção
print_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

################################################################################
# TESTES
################################################################################

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   TESTE E VALIDAÇÃO - Backup PostgreSQL Ledger             ║"
echo "║   Sistema de Backup Automático para EC2 + S3               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# 1. Teste de Ferramentas
# ==============================================================================

print_section "1. FERRAMENTAS INSTALADAS"

# Teste: pg_dump
if command -v pg_dump &> /dev/null; then
    print_test_result "pg_dump (PostgreSQL client)" "PASS"
    echo "   Versão: $(pg_dump --version)"
else
    print_test_result "pg_dump (PostgreSQL client)" "FAIL"
fi

# Teste: gzip
if command -v gzip &> /dev/null; then
    print_test_result "gzip (compressor)" "PASS"
else
    print_test_result "gzip (compressor)" "FAIL"
fi

# Teste: aws cli
if command -v aws &> /dev/null; then
    print_test_result "aws (AWS CLI)" "PASS"
    echo "   Versão: $(aws --version)"
else
    print_test_result "aws (AWS CLI)" "FAIL"
fi

# Teste: jq
if command -v jq &> /dev/null; then
    print_test_result "jq (JSON processor)" "PASS"
    echo "   Versão: $(jq --version)"
else
    print_test_result "jq (JSON processor)" "FAIL"
fi

# ==============================================================================
# 2. Teste de Autenticação AWS
# ==============================================================================

print_section "2. AUTENTICAÇÃO AWS"

# Teste: IAM Role
if aws sts get-caller-identity &> /dev/null; then
    print_test_result "IAM Role disponível" "PASS"
    echo "   Identidade: $(aws sts get-caller-identity --output json | jq -r '.Arn')"
else
    print_test_result "IAM Role disponível" "FAIL"
    echo "   Erro: Instância EC2 não possui IAM Role configurada"
fi

# ==============================================================================
# 3. Teste de Secrets Manager
# ==============================================================================

print_section "3. AWS SECRETS MANAGER"

# Teste: Acesso ao secret
if aws secretsmanager get-secret-value \
    --secret-id "${SECRETS_NAME}" \
    --region "${AWS_REGION}" \
    --query 'SecretString' \
    --output text &> /dev/null; then
    print_test_result "Secret '${SECRETS_NAME}' acessível" "PASS"
    
    # Validar conteúdo
    secret_json=$(aws secretsmanager get-secret-value \
        --secret-id "${SECRETS_NAME}" \
        --region "${AWS_REGION}" \
        --query 'SecretString' \
        --output text)
    
    if echo "${secret_json}" | jq -e '.password' &> /dev/null; then
        print_test_result "Campo 'password' existe no secret" "PASS"
    else
        print_test_result "Campo 'password' existe no secret" "FAIL"
        echo "   Erro: Secret não contém campo 'password'"
    fi
else
    print_test_result "Secret '${SECRETS_NAME}' acessível" "FAIL"
    echo "   Erro: Secret não encontrado ou sem permissão"
fi

# ==============================================================================
# 4. Teste de Conectividade PostgreSQL
# ==============================================================================

print_section "4. CONECTIVIDADE POSTGRESQL"

# Teste: pg_isready
if pg_isready -h "${DB_HOST}" -p "${DB_PORT}" &> /dev/null; then
    print_test_result "Conectividade com ${DB_HOST}:${DB_PORT}" "PASS"
else
    print_test_result "Conectividade com ${DB_HOST}:${DB_PORT}" "FAIL"
    echo "   Erro: Não foi possível conectar ao banco"
    echo "   Verificar: Security Group, firewall, status do PostgreSQL"
fi

# Teste: Credenciais PostgreSQL
if aws secretsmanager get-secret-value \
    --secret-id "${SECRETS_NAME}" \
    --region "${AWS_REGION}" \
    --query 'SecretString' \
    --output text &> /dev/null; then
    
    secret_json=$(aws secretsmanager get-secret-value \
        --secret-id "${SECRETS_NAME}" \
        --region "${AWS_REGION}" \
        --query 'SecretString' \
        --output text)
    
    DB_PASSWORD=$(echo "${secret_json}" | jq -r '.password')
    
    export PGPASSWORD="${DB_PASSWORD}"
    
    if psql -h "${DB_HOST}" -p "${DB_PORT}" -U backup_user -d ledger_prod -c "SELECT 1;" &> /dev/null; then
        print_test_result "Credenciais PostgreSQL válidas" "PASS"
    else
        print_test_result "Credenciais PostgreSQL válidas" "FAIL"
        echo "   Erro: Usuário backup_user ou senha incorreta"
    fi
    
    unset PGPASSWORD
fi

# ==============================================================================
# 5. Teste de Bucket S3
# ==============================================================================

print_section "5. BUCKET S3"

# Teste: Bucket existe
if aws s3 ls "s3://${S3_BUCKET}" --region "${AWS_REGION}" &> /dev/null; then
    print_test_result "Bucket S3 '${S3_BUCKET}' acessível" "PASS"
else
    print_test_result "Bucket S3 '${S3_BUCKET}' acessível" "FAIL"
    echo "   Erro: Bucket não existe ou sem permissão"
fi

# Teste: Permissão de escrita (upload)
TEST_FILE=$(mktemp)
echo "test" > "${TEST_FILE}"

if aws s3 cp "${TEST_FILE}" "s3://${S3_BUCKET}/test-write-$(date +%s).txt" \
    --region "${AWS_REGION}" &> /dev/null; then
    print_test_result "Permissão de escrita no S3" "PASS"
    
    # Limpar arquivo de teste
    aws s3 rm "s3://${S3_BUCKET}/test-write-$(date +%s).txt" \
        --region "${AWS_REGION}" &> /dev/null || true
else
    print_test_result "Permissão de escrita no S3" "FAIL"
    echo "   Erro: Sem permissão s3:PutObject"
fi

rm -f "${TEST_FILE}"

# ==============================================================================
# 6. Teste de Diretórios
# ==============================================================================

print_section "6. PERMISSÕES DE DIRETÓRIO"

# Teste: Diretório de backup
if [[ -d "${BACKUP_DIR}" ]]; then
    print_test_result "Diretório ${BACKUP_DIR} existe" "PASS"
else
    print_test_result "Diretório ${BACKUP_DIR} existe" "FAIL"
    echo "   Erro: Diretório não existe"
fi

# Teste: Permissão de escrita
if [[ -w "${BACKUP_DIR}" ]]; then
    print_test_result "Permissão de escrita em ${BACKUP_DIR}" "PASS"
else
    print_test_result "Permissão de escrita em ${BACKUP_DIR}" "FAIL"
    echo "   Erro: Sem permissão de escrita"
fi

# Teste: Espaço em disco
AVAILABLE_SPACE=$(df "${BACKUP_DIR}" | awk 'NR==2 {print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1048576))

if [[ ${AVAILABLE_GB} -gt 50 ]]; then
    print_test_result "Espaço em disco > 50 GB" "PASS"
    echo "   Disponível: ${AVAILABLE_GB} GB"
else
    print_test_result "Espaço em disco > 50 GB" "FAIL"
    echo "   Disponível: ${AVAILABLE_GB} GB (recomendado: 50+ GB)"
fi

# ==============================================================================
# 7. Teste de Script
# ==============================================================================

print_section "7. SCRIPT DE BACKUP"

# Teste: Script existe
if [[ -f "${SCRIPT_PATH}" ]]; then
    print_test_result "Script existe em ${SCRIPT_PATH}" "PASS"
else
    print_test_result "Script existe em ${SCRIPT_PATH}" "FAIL"
    echo "   Erro: Script não encontrado"
fi

# Teste: Script é executável
if [[ -x "${SCRIPT_PATH}" ]]; then
    print_test_result "Script é executável" "PASS"
else
    print_test_result "Script é executável" "FAIL"
    echo "   Erro: Script não possui permissão de execução"
fi

# Teste: Sintaxe do script
if bash -n "${SCRIPT_PATH}" &> /dev/null; then
    print_test_result "Sintaxe do script válida" "PASS"
else
    print_test_result "Sintaxe do script válida" "FAIL"
    echo "   Erro: Script contém erros de sintaxe"
    bash -n "${SCRIPT_PATH}"
fi

# ==============================================================================
# 8. Teste de Log
# ==============================================================================

print_section "8. ARQUIVO DE LOG"

LOG_DIR=$(dirname "${LOG_FILE}")

# Teste: Diretório de log
if [[ -d "${LOG_DIR}" ]]; then
    print_test_result "Diretório ${LOG_DIR} existe" "PASS"
else
    print_test_result "Diretório ${LOG_DIR} existe" "FAIL"
fi

# Teste: Arquivo de log
if [[ -f "${LOG_FILE}" ]]; then
    print_test_result "Arquivo ${LOG_FILE} existe" "PASS"
else
    print_test_result "Arquivo ${LOG_FILE} existe" "FAIL"
    echo "   Aviso: Arquivo será criado na primeira execução"
fi

# ==============================================================================
# RESUMO
# ==============================================================================

print_section "RESUMO DOS TESTES"

echo -e "${GREEN}Testes Aprovados: ${TESTS_PASSED}${NC}"
echo -e "${RED}Testes Falhados: ${TESTS_FAILED}${NC}"

echo ""

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ TODOS OS TESTES PASSARAM COM SUCESSO!  ║${NC}"
    echo -e "${GREEN}║  O backup pode ser ativado em produção.   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    
    echo ""
    echo "PRÓXIMOS PASSOS:"
    echo "1. Executar manualmente para validar:"
    echo "   sudo ${SCRIPT_PATH}"
    echo ""
    echo "2. Verificar logs após execução:"
    echo "   sudo tail -f ${LOG_FILE}"
    echo ""
    echo "3. Verificar arquivo no S3:"
    echo "   aws s3 ls s3://${S3_BUCKET}/postgres-backups/ --region ${AWS_REGION}"
    echo ""
    echo "4. Configurar cron job:"
    echo "   sudo crontab -e"
    echo "   0 2 * * * ${SCRIPT_PATH}"
    
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ ALGUNS TESTES FALHARAM!                ║${NC}"
    echo -e "${RED}║  Corrija os erros acima antes de continuar ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
    
    exit 1
fi
