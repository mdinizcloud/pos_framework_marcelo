# BEFORE
Tenho um manifesto de Deployment legível do Kubernetes (criado há 3 anos) que não segue os padrões modernos de resiliência, segurança e governança da nossa empresa. O manifesto atual é este:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chronos-api
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: chronos-api
  template:
    metadata:
      labels:
        app: chronos-api
    spec:
      containers:
      - name: api
        image: chronos-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_PASSWORD
          value: "P@ssw0rd2023!"
        - name: JWT_SECRET
          value: "hvt-jwt-prod-secret"
```

# AFTER
O objetivo é obter um manifesto modernizado, pronto para rodar em um cluster de produção corporativo com Alta Disponibilidade, segurança, gerenciamento eficiente de recursos computacionais e sem dados sensíveis expostos diretamente no código.

# BRIDGE

1. Alta Disponibilidade: Incremente o número de réplicas

2. Imagem Versionada: Substitua a tag 'latest' por uma tag imutável baseada em versionamento

3. Separação de Secrets: Remova as variáveis de ambiente 'DB_PASSWORD' e 'JWT_SECRET' 

4. Gere também o manifesto de um objeto 'Kind: Secret' 
    
5. Gere gerenciamento de recursos, adicione blocos de gerencia de recursos 'requests' e 'limits' de CPU e Memória apropriados para uma API web de produção.
    
6. Health Probes: Implemente 'livenessProbe' e 'readinessProbe' apontando para as portas do containers, defina thresholds de tempo moderado.
    
7. Adicione um 'securityContext' tanto ao nível do Pod quanto do Container para garantir que a aplicação rode como usuário não-root (runAsNonRoot: true, runAsUser: 10001) e com privilégios restritos
    
Gere um artefato com o código YAML limpos, comentados e estruturados com as boas práticas de produção explicadas.          

Gere um artefato Markdown uma tabela listando as melhorias implantadas, explique qual seu propósito,  detalhe o ganhos em implantar e os riscos em não implantar 


---
