# ROLE
Você é um Engenheiro de SRE Sênior especialista em automação, AWS e bancos de dados PostgreSQL. 

# TASK
- Escreva um script em Bash para realizar o backup diário de um banco de dados PostgreSQL (Ledger). 
- Executar o script via cron diária em uma instância EC2 rodando Ubuntu 22.04 LTS. 
- Host: ledger-db.internal.hvt.io
- Porta: 5432
- Banco: ledger_prod
- Usuário de backup: backup_user
- Senha: O script não deve expor a senha (use AWS Secrets Manager e IAM Role na instância).
- Diretório de trabalho: /var/backups/ledger
- Utilizar 'pg_dump' para o dump, compactar usando 'gzip'
- Realizar o upload para o bucket S3 'hvt-ledger-backups'
- Retenção de 30 dias no bucket S3
- Remover automaticamente os arquivos com mais de 30 dias
- Registrar o início, sucesso e falha de cada etapa no arquivo /var/log/ledger-backup.log acompanhado do timestamp.
- Implementar tratativa ede erros, checagem de 'exit code' em cada comando (pg_dump, gzip, aws s3). 
- Se qualquer etapa falhar, registre o erro no log e encerrar imediatamente com um 'exit code' diferente de zero (ex: exit 1).

# FORMAT 
- O código do script Bash para exeutar no ubuntu 24.04 LTS
- Documentar com comentários direto em cada bloco de código.
- Inserir uma breve explicação no início do script 
- Descrever resumidamente tratamento de erros e segurança 
- Descrever a tratatira de erros para garantir o redirecionamento correto da saida.
