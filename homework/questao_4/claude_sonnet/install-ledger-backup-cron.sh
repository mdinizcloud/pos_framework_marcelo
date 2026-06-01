#!/bin/bash
# ==============================================================================
# INSTALAÇÃO E CONFIGURAÇÃO DO CRON JOB
# ==============================================================================
# 
# Execute este script na instância EC2 como root ou com sudo:
#   sudo bash /tmp/install-ledger-backup-cron.sh
# 
# Ou configure manualmente com:
#   sudo crontab -e
#   E adicione a linha do cron abaixo
#
# ==============================================================================

# Verificar se está sendo executado como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script deve ser executado como root (use: sudo bash $0)"
   exit 1
fi

echo "=================================="
echo "Instalando Backup Ledger Cron Job"
echo "=================================="

# Diretório de trabalho do script
SCRIPT_DIR="/opt/ledger-backup"
SCRIPT_FILE="${SCRIPT_DIR}/ledger-backup.sh"

# Criar diretório se não existir
mkdir -p "${SCRIPT_DIR}"
echo "✓ Diretório criado: ${SCRIPT_DIR}"

# Copiar script (assumindo que está em /tmp/ledger-backup.sh)
if [[ -f "/tmp/ledger-backup.sh" ]]; then
    cp /tmp/ledger-backup.sh "${SCRIPT_FILE}"
    chmod 750 "${SCRIPT_FILE}"
    echo "✓ Script copiado para: ${SCRIPT_FILE}"
else
    echo "⚠ Script /tmp/ledger-backup.sh não encontrado"
    echo "Por favor, execute este script depois de copiar ledger-backup.sh para /tmp"
    exit 1
fi

# Criar diretório de backups com permissões corretas
mkdir -p /var/backups/ledger
chmod 755 /var/backups/ledger
echo "✓ Diretório de backups criado: /var/backups/ledger"

# Criar diretório de logs com permissões corretas
mkdir -p $(dirname /var/log/ledger-backup.log)
touch /var/log/ledger-backup.log
chmod 644 /var/log/ledger-backup.log
echo "✓ Arquivo de log criado: /var/log/ledger-backup.log"

# ==============================================================================
# CONFIGURAÇÃO DO CRON JOB
# ==============================================================================
# 
# Formato Cron: MIN HOUR DAY MONTH DAYWEEK COMMAND
# 
# Opções de agendamento:
# 
# 1) Diariamente às 02:00 (2 AM) - RECOMENDADO (fora do horário de pico)
#    0 2 * * * /opt/ledger-backup/ledger-backup.sh
#
# 2) Diariamente às 03:30 (3:30 AM)
#    30 3 * * * /opt/ledger-backup/ledger-backup.sh
#
# 3) A cada 6 horas (00:00, 06:00, 12:00, 18:00)
#    0 */6 * * * /opt/ledger-backup/ledger-backup.sh
#
# ==============================================================================

# Entrada do cron job (executar diariamente às 02:00)
CRON_ENTRY="0 2 * * * /opt/ledger-backup/ledger-backup.sh"

# Adicionar cron job ao crontab do root
(crontab -l 2>/dev/null | grep -v "ledger-backup.sh"; echo "$CRON_ENTRY") | crontab -
echo "✓ Cron job adicionado com sucesso"
echo "  Agendamento: Diariamente às 02:00"
echo "  Comando: ${CRON_ENTRY}"

# Verificar crontab
echo ""
echo "=================================="
echo "Crontab atual (root):"
echo "=================================="
crontab -l | grep -i ledger

echo ""
echo "=================================="
echo "Instalação concluída!"
echo "=================================="
echo ""
echo "PRÓXIMOS PASSOS:"
echo "1. Criar o secret no AWS Secrets Manager:"
echo "   aws secretsmanager create-secret \\"
echo "     --name ledger-db-backup-credentials \\"
echo "     --description 'Credenciais de backup para PostgreSQL Ledger' \\"
echo "     --secret-string '{\"password\":\"SUA_SENHA_AQUI\"}' \\"
echo "     --region us-east-1"
echo ""
echo "2. Verificar IAM Role na instância EC2:"
echo "   - Acesso a: secretsmanager:GetSecretValue"
echo "   - Acesso a: s3:PutObject, s3:ListBucket"
echo ""
echo "3. Testar o script manualmente:"
echo "   sudo ${SCRIPT_FILE}"
echo ""
echo "4. Monitorar logs:"
echo "   tail -f /var/log/ledger-backup.log"
echo ""
