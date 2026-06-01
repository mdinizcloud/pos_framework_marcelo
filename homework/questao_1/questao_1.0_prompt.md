# ROLE
Atue como um Engenheiro DevOps Sênior especialista em Docker, Kubernetes.

# TASK
Crie um Dockerfile de produção para uma API Python/Flask chamada "Lift", baseando-se nos seguintes requisitos do projeto:

- Porta: 8080
- Dependências: Flask==3.0.0, gunicorn==21.2.0, requests==2.31.0, python-dotenv==1.0.0, psycopg2-binary==2.9.9 (declaradas em `requirements.txt`).
- Variáveis de Ambiente necessárias: `DATABASE_URL` e `API_KEY`.
- Comando de inicialização: `gunicorn --bind 0.0.0.0:8080 --workers 4 app:app`
- Estrutura de arquivos: O diretório raiz contém `app.py`, `requirements.txt`e pastas `lib/` e `tests/`.
    
# FORMAT
- Forneça o código do `Dockerfile` comentado linha a linha explicando o porquê de cada boa prática adotada.
