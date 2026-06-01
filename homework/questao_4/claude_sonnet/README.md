# Backup Diário PostgreSQL Ledger - README

## 🚀 Quick Start (5 minutos)

### 1. Instalar Dependências
```bash
sudo apt-get update && sudo apt-get install -y postgresql-client awscli jq
```

### 2. Criar Diretórios
```bash
sudo mkdir -p /var/backups/ledger /opt/ledger-backup
sudo chown ubuntu:ubuntu /var/backups/ledger /opt/ledger-backup
```

### 3. Copiar Script
```bash
# Se tiver o arquivo localmente:
sudo cp ledger-backup.sh /opt/ledger-backup/
sudo chmod 750 /opt/ledger-backup/ledger-backup.sh

# Ou fazer download:
sudo curl -o /opt/ledger-backup/ledger-backup.sh https://seu-repo/ledger-backup.sh
sudo chmod 750 /opt/ledger-backup/ledger-backup.sh
```

### 4. Criar Secret no AWS Secrets Manager
```bash
aws secretsmanager create-secret \
  --name ledger-db-backup-credentials \
  --secret-string '{"password":"SUA_SENHA_POSTGRES"}' \
  --region us-east-1
```

### 5. Testar Script
```bash
sudo /opt/ledger-backup/ledger-backup.sh
```

### 6. Configurar Cron (Diariamente às 02:00)
```bash
sudo crontab -e
# Adicionar: 0 2 * * * /opt/ledger-backup/ledger-backup.sh
```

### 7. Monitorar Logs
```bash
sudo tail -f /var/log/ledger-backup.log
```

---

## 📁 Arquivos Inclusos

| Arquivo | Propósito |
|---------|----------|
| **ledger-backup.sh** | Script principal de backup (⭐ use este) |
| **test-ledger-backup.sh** | Script de teste e validação |
| **install-ledger-backup-cron.sh** | Instalador automático de cron job |
| **LEDGER_BACKUP_DOCUMENTATION.md** | Documentação completa (detalhada) |
| **README.md** | Este arquivo (instruções rápidas) |

---

## ✅ Checklist de Setup

- [ ] Dependências instaladas (pg_dump, awscli, jq)
- [ ] Diretórios criados (/var/backups/ledger, /opt/ledger-backup)
- [ ] Script copiado e com permissão 750
- [ ] Secret criado no Secrets Manager
- [ ] IAM Role anexada à instância com permissões
- [ ] Teste de conectividade com banco OK
- [ ] Script testado manualmente (sem erros)
- [ ] Cron job configurado
- [ ] Primeira execução automática validada

---

## 🔍 Validar Setup

Executar script de teste (recomendado):
```bash
sudo bash test-ledger-backup.sh
```

Se todos os testes passarem ✓, o setup está correto!

---

## 📊 Monitoramento Básico

### Ver últimas execuções
```bash
sudo tail -50 /var/log/ledger-backup.log
```

### Ver apenas erros
```bash
sudo grep "ERROR" /var/log/ledger-backup.log
```

### Verificar backups no S3
```bash
aws s3 ls s3://hvt-ledger-backups/postgres-backups/ --region us-east-1
```

### Verificar espaço em disco
```bash
df -h /var/backups/ledger
```

---

## 🚨 Troubleshooting Rápido

### Erro: "pg_dump not found"
```bash
sudo apt-get install -y postgresql-client
```

### Erro: "Não foi possível conectar ao banco"
```bash
# Testar conectividade
nc -zv ledger-db.internal.hvt.io 5432

# Testar com psql
PGPASSWORD=sua_senha psql -h ledger-db.internal.hvt.io -U backup_user -d ledger_prod -c "SELECT 1;"
```

### Erro: "Falha ao recuperar credenciais"
```bash
# Verificar IAM Role
aws sts get-caller-identity

# Testar acesso ao secret
aws secretsmanager get-secret-value --secret-id ledger-db-backup-credentials --region us-east-1
```

### Erro: "Upload S3 falhou"
```bash
# Testar S3
aws s3 ls s3://hvt-ledger-backups

# Verificar permissões IAM (role precisa de s3:PutObject)
```

---

## 📝 Detalhes Técnicos

### Fluxo de Execução
1. ✓ Validar ferramentas e diretórios
2. ✓ Recuperar credenciais do Secrets Manager via IAM Role
3. ✓ Testar conexão com PostgreSQL
4. ✓ Executar pg_dump com formato custom
5. ✓ Compactar com gzip -9 (máxima compressão)
6. ✓ Fazer upload para S3 com criptografia AES-256
7. ✓ Remover backups locais > 30 dias
8. ✓ Remover backups no S3 > 30 dias
9. ✓ Registrar todas as etapas em log

### Segurança
- ✅ Sem credenciais hardcoded no script
- ✅ Credenciais via AWS Secrets Manager
- ✅ Autenticação via IAM Role da EC2
- ✅ Criptografia em trânsito (HTTPS para S3)
- ✅ Criptografia em repouso (AES-256)
- ✅ PGPASSWORD é limpado após uso

### Tratamento de Erros
- ✅ Exit code validado em cada etapa
- ✅ Mensagens de erro descritivas em log
- ✅ Execução interrompida na primeira falha
- ✅ Lock file evita execução concorrente
- ✅ Trap para limpeza em caso de interrupção

---

## 🔐 Configurar Permissões IAM (AWS Console ou CLI)

A instância EC2 precisa de uma IAM Role com esta política:

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

---

## 📚 Documentação Detalhada

Para mais informações:
- **Tratamento de Erros**: Ver `LEDGER_BACKUP_DOCUMENTATION.md` - Seção "Tratamento de Erros"
- **Segurança**: Ver `LEDGER_BACKUP_DOCUMENTATION.md` - Seção "Segurança"
- **Troubleshooting**: Ver `LEDGER_BACKUP_DOCUMENTATION.md` - Seção "Troubleshooting"
- **Performance**: Ver `LEDGER_BACKUP_DOCUMENTATION.md` - Seção "Performance e Otimização"

---

## 🆘 Suporte

1. Executar script de teste: `sudo bash test-ledger-backup.sh`
2. Verificar logs: `sudo tail -100 /var/log/ledger-backup.log`
3. Consultar documentação detalhada: `LEDGER_BACKUP_DOCUMENTATION.md`
4. Contatar time de SRE/DevOps

---

## 📊 Agendamento Padrão

```
Dia: Segunda a Domingo
Hora: 02:00 UTC
Frequência: Diariamente
Retenção: 30 dias (local + S3)
```

Para alterar, editar crontab:
```bash
sudo crontab -e

# Exemplos:
# 0 2 * * * - Diariamente às 02:00 (PADRÃO)
# 0 3 * * * - Diariamente às 03:00
# 0 */6 * * * - A cada 6 horas
```

---

## 💾 Localização de Arquivos

| Item | Local |
|------|-------|
| Script de backup | `/opt/ledger-backup/ledger-backup.sh` |
| Backups locais | `/var/backups/ledger/` |
| Logs | `/var/log/ledger-backup.log` |
| Lock file | `/tmp/ledger-backup.lock` |
| Backups S3 | `s3://hvt-ledger-backups/postgres-backups/` |

---

**Última atualização**: Maio 2025  
**Versão**: 1.0  
**Autor**: SRE Team
