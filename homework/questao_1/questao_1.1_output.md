
---
# OUTPUT CLAUDE  SONNET
Como Engenheiro DevOps Sênior, meu objetivo aqui é garantir que este container seja **seguro, leve, rápido para buildar (aproveitando o cache de camadas) e siga as melhores práticas de produção**.

Para atingir isso, vamos utilizar uma estratégia de **Multi-stage Build**. Isso nos permite instalar as ferramentas de compilação em um estágio temporário e copiar apenas o necessário para a imagem final, reduzindo drasticamente a superfície de ataque e o tamanho da imagem.

Aqui está o `Dockerfile` otimizado para produção e comentado linha a linha:

---
# OUTPUT GEMINI PRO
Como Engenheiro DevOps, focar em segurança, performance e confiabilidade é essencial, especialmente quando preparamos uma imagem para ser orquestrada em ambientes de alta disponibilidade.

Para a sua API "Lift", desenvolvi um Dockerfile focado em diretrizes de produção. O código adota práticas rigorosas, como o uso de usuários não-root (fundamental para a segurança), otimização de cache de camadas do Docker (para builds mais rápidos nas pipelines de CI/CD) e configuração correta do ambiente Python para coleta de logs.

Aqui está o seu Dockerfile comentado linha a linha:

