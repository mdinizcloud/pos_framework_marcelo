# R-I-S-E (Role, Input, Steps, Expectation)
O modelo escolhido seria o RISE, porquê a IA  precisa seguir uma linha de raciocínio lógico e investigativo exatamente como um  SRE faz. 

Permite encadear o raciocínio Chain of Thought, forçando analisar as métricas antes de concluir a causa raiz, isso me fornece mais segurança e mais confiança no plano de ação

# T-A-G
**Vantagem:** Modelo totalmente orientado a resultado. 
O "Goal" seria o direcionamento decisivo aplicado de forma explicita: 
Ele iria fazer o modelo focar obsessivamente na tomada de decisão rápida.
    
**Desvantagem:** Acredito que ele seria superior aos outros modelos (menos o R-I-S-E) por focar no resultado, mas nesse contexto talvez pecaria na falta de direcionamento.

O modelo pode não seguir os passos lógicos na avaliação dos componentes do incidente e triagem das métricas (analisar métricas $\rightarrow$ analisar logs $\rightarrow$ isolar causa $\rightarrow$ decidir), podendo gerar uma resposta muito direta sem analisar mais elementos.

 ---
# R-T-F

**Vantagem:**  Tem vantagem da velocidade e simplicidade nesse contexto. 
Sendo  o framework mais rápido de escrever, iria definir o papel como SRE, jogaria os logs  nas Task e pediria no Format um postmortem.
    
**Desvantagem:**  Nesse contexto complexo é muito direto, sem explicar diretamente os steps para a IA seguir, provavelmente ela pode ignorar pontos importantes  e sugerir algo de forma rasa e sem aprofundamento.



