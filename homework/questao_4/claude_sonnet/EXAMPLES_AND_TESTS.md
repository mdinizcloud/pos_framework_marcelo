# Exemplos de Output e Casos de Teste

## 📋 Saída Esperada - Execução com Sucesso

### Execução Manual via Terminal

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
[2025-05-26 02:00:00] [INFO] Host: ledger-db.internal.hvt.io:5432
[2025-05-26 02:00:00] [INFO] Banco: ledger_prod
[2025-05-26 02:00:00] [INFO] Bucket S3: s3://hvt-ledger-backups/postgres-backups
[2025-05-26 02:00:00] [INFO] Retenção: 30 dias
[2025-05-26 02:00:00] [INFO] Lock file criado: /tmp/ledger-backup.lock
[2025-05-26 02:00:01] [INFO] Validando pré-requisitos do sistema...
[2025-05-26 02:00:01] [INFO] ✓ Todos os pré-requisitos validados com sucesso
[2025-05-26 02:00:02] [INFO] Validando diretórios...
[2025-05-26 02:00:02] [INFO] ✓ Diretórios validados com sucesso
[2025-05-26 02:00:02] [INFO] Recuperando credenciais do AWS Secrets Manager...
[2025-05-26 02:00:03] [INFO] ✓ Credenciais recuperadas com sucesso
[2025-05-26 02:00:03] [INFO] Testando conexão com banco de dados: ledger-db.internal.hvt.io:5432/ledger_prod...
[2025-05-26 02:00:03] [INFO] ✓ Conexão com banco de dados validada
[2025-05-26 02:00:04] [INFO] Iniciando dump do banco de dados PostgreSQL...
[2025-05-26 02:05:30] [INFO] ✓ Dump PostgreSQL concluído com sucesso (2456789012 bytes)
[2025-05-26 02:05:31] [INFO] Compactando arquivo de backup com gzip...
[2025-05-26 02:06:15] [INFO] ✓ Compressão gzip concluída (345678901 bytes)
[2025-05-26 02:06:16] [INFO] Iniciando upload para S3: s3://hvt-ledger-backups/postgres-backups/ledger_20250526_020004.sql.gz...
[2025-05-26 02:06:45] [INFO] ✓ Upload S3 concluído com sucesso
[2025-05-26 02:06:46] [INFO] Limpando backups locais com mais de 30 dias...
[2025-05-26 02:06:47] [INFO] ✓ Limpeza local concluída (0 arquivos removidos)
[2025-05-26 02:06:47] [INFO] Limpando backups no S3 com mais de 30 dias...
[2025-05-26 02:06:47] [INFO] Data limite de retenção: 2025-04-26
[2025-05-26 02:06:49] [INFO] ✓ Limpeza S3 concluída (2 arquivos removidos)
[2025-05-26 02:06:49] [INFO] ✓ Todas as etapas completadas com sucesso!
[2025-05-26 02:06:50] [INFO] ========== BACKUP CONCLUÍDO COM SUCESSO ==========
[2025-05-26 02:06:50] [INFO] Lock file removido

# Exit code: 0 (sucesso)
```

### Log Arquivo Completo

**Localização**: `/var/log/ledger-backup.log`

```
[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
[2025-05-26 02:00:00] [INFO] Host: ledger-db.internal.hvt.io:5432
[2025-05-26 02:00:00] [INFO] Banco: ledger_prod
[2025-05-26 02:00:00] [INFO] Bucket S3: s3://hvt-ledger-backups/postgres-backups
[2025-05-26 02:00:00] [INFO] Retenção: 30 dias
[2025-05-26 02:00:00] [INFO] Lock file criado: /tmp/ledger-backup.lock
[2025-05-26 02:00:01] [INFO] Validando pré-requisitos do sistema...
[2025-05-26 02:00:01] [INFO] ✓ Todos os pré-requisitos validados com sucesso
[2025-05-26 02:00:02] [INFO] Validando diretórios...
[2025-05-26 02:00:02] [INFO] ✓ Diretórios validados com sucesso
[2025-05-26 02:00:02] [INFO] Recuperando credenciais do AWS Secrets Manager...
[2025-05-26 02:00:03] [INFO] ✓ Credenciais recuperadas com sucesso
[2025-05-26 02:00:03] [INFO] Testando conexão com banco de dados: ledger-db.internal.hvt.io:5432/ledger_prod...
[2025-05-26 02:00:03] [INFO] ✓ Conexão com banco de dados validada
[2025-05-26 02:00:04] [INFO] Iniciando dump do banco de dados PostgreSQL...
[2025-05-26 02:05:30] [INFO] ✓ Dump PostgreSQL concluído com sucesso (2456789012 bytes)
[2025-05-26 02:05:31] [INFO] Compactando arquivo de backup com gzip...
[2025-05-26 02:06:15] [INFO] ✓ Compressão gzip concluída (345678901 bytes)
[2025-05-26 02:06:16] [INFO] Iniciando upload para S3: s3://hvt-ledger-backups/postgres-backups/ledger_20250526_020004.sql.gz...
[2025-05-26 02:06:45] [INFO] ✓ Upload S3 concluído com sucesso
[2025-05-26 02:06:46] [INFO] Limpando backups locais com mais de 30 dias...
[2025-05-26 02:06:47] [INFO] ✓ Limpeza local concluída (0 arquivos removidos)
[2025-05-26 02:06:47] [INFO] Limpando backups no S3 com mais de 30 dias...
[2025-05-26 02:06:47] [INFO] Data limite de retenção: 2025-04-26
[2025-05-26 02:06:49] [INFO] ✓ Limpeza S3 concluída (2 arquivos removidos)
[2025-05-26 02:06:49] [INFO] ✓ Todas as etapas completadas com sucesso!
[2025-05-26 02:06:50] [INFO] ========== BACKUP CONCLUÍDO COM SUCESSO ==========
[2025-05-26 02:06:50] [INFO] Lock file removido

[2025-05-27 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
[2025-05-27 02:00:00] [INFO] Host: ledger-db.internal.hvt.io:5432
[2025-05-27 02:00:00] [INFO] Banco: ledger_prod
[2025-05-27 02:00:00] [INFO] Bucket S3: s3://hvt-ledger-backups/postgres-backups
[2025-05-27 02:00:00] [INFO] Retenção: 30 dias
[2025-05-27 02:00:00] [INFO] Lock file criado: /tmp/ledger-backup.lock
...
```

---

## ❌ Saída Esperada - Falhas Comuns

### Caso 1: pg_dump não instalado

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
[2025-05-26 02:00:00] [INFO] Host: ledger-db.internal.hvt.io:5432
[2025-05-26 02:00:00] [INFO] Banco: ledger_prod
[2025-05-26 02:00:00] [INFO] Lock file criado: /tmp/ledger-backup.lock
[2025-05-26 02:00:01] [INFO] Validando pré-requisitos do sistema...
[2025-05-26 02:00:01] [ERROR] Ferramenta obrigatória não encontrada: pg_dump

# Exit code: 1 (erro)

# Solução:
sudo apt-get install -y postgresql-client
```

---

### Caso 2: Credenciais não encontradas no Secrets Manager

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
...
[2025-05-26 02:00:02] [INFO] Recuperando credenciais do AWS Secrets Manager...
[2025-05-26 02:00:03] [ERROR] Falha ao recuperar credenciais do Secrets Manager (ledger-db-backup-credentials)

# Exit code: 1 (erro)

# Solução:
aws secretsmanager create-secret \
  --name ledger-db-backup-credentials \
  --secret-string '{"password":"sua_senha"}' \
  --region us-east-1
```

---

### Caso 3: Sem conectividade com PostgreSQL

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
...
[2025-05-26 02:00:03] [INFO] Testando conexão com banco de dados: ledger-db.internal.hvt.io:5432/ledger_prod...
[2025-05-26 02:00:04] [ERROR] Não foi possível conectar ao banco de dados ledger-db.internal.hvt.io:5432

# Exit code: 1 (erro)

# Solução:
# 1. Verificar conectividade
nc -zv ledger-db.internal.hvt.io 5432

# 2. Verificar Security Group da EC2
# 3. Verificar status do PostgreSQL
ssh seu-banco
sudo systemctl status postgresql
```

---

### Caso 4: Banco de dados vazio ou corrompido

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
...
[2025-05-26 02:00:05] [INFO] Iniciando dump do banco de dados PostgreSQL...
[2025-05-26 02:00:10] [ERROR] Arquivo de dump vazio ou inválido (tamanho: 0 bytes)

# Exit code: 1 (erro)

# Verificação:
# 1. Conectar direto no banco
PGPASSWORD=sua_senha psql -h ledger-db.internal.hvt.io -U backup_user -d ledger_prod -c "\dt"

# 2. Verificar tabelas existem
# 3. Testar pg_dump manualmente
PGPASSWORD=sua_senha pg_dump -h ledger-db.internal.hvt.io -U backup_user -d ledger_prod --no-password -F c -f /tmp/test.dump
```

---

### Caso 5: Upload S3 falha (sem permissões)

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
...
[2025-05-26 02:06:16] [INFO] Iniciando upload para S3: s3://hvt-ledger-backups/postgres-backups/ledger_20250526_020004.sql.gz...
[2025-05-26 02:06:25] [ERROR] Upload S3 falhou com exit code 254

# Exit code: 1 (erro)

# Solução:
# 1. Verificar que bucket existe
aws s3 ls s3://hvt-ledger-backups

# 2. Testar upload manualmente
echo "test" > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://hvt-ledger-backups/test.txt

# 3. Verificar IAM Role tem s3:PutObject
```

---

### Caso 6: Espaço em disco insuficiente

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
...
[2025-05-26 02:06:15] [ERROR] Arquivo compactado vazio ou inválido (tamanho: 0 bytes)

# Exit code: 1 (erro)

# Verificar espaço:
df -h /var/backups/ledger

# Solução: Liberar espaço ou aumentar volume
```

---

### Caso 7: Script já em execução (lock file)

```bash
$ sudo /opt/ledger-backup/ledger-backup.sh

[2025-05-26 02:00:00] [INFO] ========== INICIANDO BACKUP DO BANCO DE DADOS ==========
[2025-05-26 02:00:00] [ERROR] Backup já está em execução (lock file: /tmp/ledger-backup.lock). Abortando para evitar concorrência.

# Exit code: 1 (erro)

# Solução:
# Verificar se há outro processo rodando
ps aux | grep ledger-backup

# Se realmente há um travado, remover lock
sudo rm /tmp/ledger-backup.lock
```

---

## 📊 Estrutura de Diretórios Esperada

### Backups Locais

```bash
$ ls -lh /var/backups/ledger/

total 1.2G
-rw-r--r-- 1 root root 345M May 26 02:06 ledger_20250526_020004.sql.gz
-rw-r--r-- 1 root root 342M May 25 02:05 ledger_20250525_020005.sql.gz
-rw-r--r-- 1 root root 348M May 24 02:04 ledger_20250524_020003.sql.gz
-rw-r--r-- 1 root root 350M May 23 02:03 ledger_20250523_020002.sql.gz
-rw-r--r-- 1 root root 346M May 22 02:02 ledger_20250522_020001.sql.gz
```

### S3 Backups

```bash
$ aws s3 ls s3://hvt-ledger-backups/postgres-backups/ --region us-east-1

                           PRE postgres-backups/
2025-05-26 02:06:45  362988901 ledger_20250526_020004.sql.gz
2025-05-25 02:05:32  358901234 ledger_20250525_020005.sql.gz
2025-05-24 02:04:18  365123456 ledger_20250524_020003.sql.gz
2025-05-23 02:03:45  351234567 ledger_20250523_020002.sql.gz
2025-05-22 02:02:12  342345678 ledger_20250522_020001.sql.gz
```

---

## 🧪 Casos de Teste

### Teste 1: Backup Completo (Happy Path)

```bash
# Setup
sudo /opt/ledger-backup/ledger-backup.sh

# Verificações
✓ Log mostra "BACKUP CONCLUÍDO COM SUCESSO"
✓ Arquivo criado em /var/backups/ledger/
✓ Arquivo enviado para S3
✓ Exit code = 0
✓ Lock file foi removido
```

### Teste 2: Recuperação de Credenciais

```bash
# Verificar se PGPASSWORD é limpado
# (não deve aparecer em ps aux)

ps aux | grep backup | grep PGPASSWORD
# Resultado esperado: vazio (nenhuma correspondência)

# Verificar se secret foi recuperado corretamente
aws secretsmanager get-secret-value \
  --secret-id ledger-db-backup-credentials \
  --region us-east-1 | jq .SecretString
```

### Teste 3: Retenção de 30 Dias

```bash
# Simular arquivo com mais de 30 dias
touch -t 202504260200 /var/backups/ledger/ledger_20250426_020000.sql.gz

# Executar script
sudo /opt/ledger-backup/ledger-backup.sh

# Verificar se foi removido
ls -l /var/backups/ledger/ | grep ledger_20250426
# Resultado esperado: vazio (arquivo foi removido)
```

### Teste 4: Lock File (Evitar Concorrência)

```bash
# Terminal 1: Iniciar backup
sudo /opt/ledger-backup/ledger-backup.sh &

# Terminal 2: Tentar iniciar outro backup enquanto roda
sudo /opt/ledger-backup/ledger-backup.sh
# Resultado esperado: erro "Backup já está em execução"

# Esperar terminal 1 terminar
# Lock file será removido automaticamente
```

### Teste 5: Recuperação de Erro

```bash
# Simular erro no meio da execução
sudo /opt/ledger-backup/ledger-backup.sh

# Interromper com Ctrl+C
^C

# Verificar:
# - Log mostra erro
# - Lock file foi removido (trap catch)
# - Diretórios deixados limpos
```

---

## 📈 Tamanho de Arquivos Esperado

### Banco PostgreSQL (Exemplo)

| Tamanho Banco | Dump SQL | Compactado (gzip -9) | Taxa Compressão |
|---------------|----------|----------------------|-----------------|
| 10 GB | 10 GB | 1-2 GB | 80-90% |
| 50 GB | 50 GB | 5-10 GB | 80-90% |
| 100 GB | 100 GB | 10-20 GB | 80-90% |
| 500 GB | 500 GB | 50-100 GB | 80-90% |
| 1 TB | 1 TB | 100-200 GB | 80-90% |

---

## ⏱️ Tempo de Execução Esperado

| Tamanho Banco | pg_dump | gzip -9 | S3 Upload | Total |
|---------------|---------|---------|-----------|-------|
| 10 GB | 2-5 min | 2-3 min | 1-3 min | 5-11 min |
| 50 GB | 5-10 min | 5-8 min | 3-10 min | 13-28 min |
| 100 GB | 10-20 min | 10-15 min | 5-15 min | 25-50 min |
| 500 GB | 30-60 min | 30-50 min | 20-60 min | 80-170 min |
| 1 TB | 60-120 min | 60-90 min | 40-120 min | 160-330 min |

---

## 🔍 Validação de Integridade

### Verificar Compressão

```bash
# Verificar se arquivo .gz é válido
gzip -t /var/backups/ledger/ledger_20250526_020004.sql.gz
echo $?  # 0 = válido, >0 = corrompido
```

### Verificar PostgreSQL Dump

```bash
# Listar conteúdo do dump
pg_restore -l /var/backups/ledger/ledger_20250526_020004.sql.gz | head -20
```

### Restaurar Backup (Teste)

```bash
# CUIDADO: Só em ambiente de teste!

# 1. Copiar dump do S3
aws s3 cp s3://hvt-ledger-backups/postgres-backups/ledger_20250526_020004.sql.gz /tmp/

# 2. Restaurar em banco de teste
pg_restore -h seu-banco-teste \
           -U postgres \
           -d ledger_test_restore \
           -v \
           /tmp/ledger_20250526_020004.sql.gz

# 3. Verificar
psql -h seu-banco-teste -U postgres -d ledger_test_restore -c "SELECT COUNT(*) FROM sua_tabela;"
```

---

**Documento versão 1.0 - Maio 2025**
