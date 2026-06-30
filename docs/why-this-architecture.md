# Por que a AWS é melhor que um servidor próprio?


## O problema que você já viveu

Imagine que é dia de matrícula. Você divulgou nas redes sociais, mandou e-mail para os alunos, fez stories. As 9h da manhã, 500 pessoas tentam acessar o site ao mesmo tempo.

O site cai.

Os alunos tentam de novo. O site continua fora. Alguns desistem e vão para o concorrente. Outros ligam para a secretaria, que fica sobrecarregada de chamadas. A Escola Tech perde matrículas, e pior, perde credibilidade.

Isso acontecia porque **o site rodava em um servidor fisico, dentro de algum lugar**, com capacidade limitada e sem nenhuma proteção contra sobrecarga.

---

## O que é um servidor físico (o jeito antigo)

Pense em um servidor físico como uma geladeira. Ela tem um tamanho fixo. Se você comprar mais comida do que cabe, não tem como expandir na hora, você teria que comprar outra geladeira, esperar chegar, instalar, ligar tudo.

No mundo dos servidores, isso significa:

- Você compra um servidor caro (R$ 15.000 ou mais)
- Ele fica num quarto, consumindo energia 24 horas por dia
- Se muita gente acessa o site ao mesmo tempo, ele não aguenta
- Se o servidor estraga ou a energia cai, o site sai do ar
- Alguem precisa estar disponível para resolver problemas fisicos

**Resumo: você paga o preço máximo o tempo todo, mesmo quando ninguém esta acessando o site.**

---

## O que a Horus Tech fez diferente

A Horus Tech migrou a Escola Tech para a **AWS (Amazon Web Services)**,  a mesma infraestrutura que empresas como Netflix, iFood e Nubank usam para atender milhões de pessoas.

Em vez de um servidor físico, o site da Escola Tech agora roda em **servidores virtuais na nuvem**, espalhados em dois datacenters da Amazon nos Estados Unidos.

Parece complicado, mas a ideia e simples:

---

## As tres grandes mudancas

### 1. O site agora escala sozinho

Antes: 1 servidor. Capacidade fixa. Se muita gente acessa, cai.

Agora: o sistema monitora automaticamente quantas pessoas estão acessando. Se o número subir muito, ele cria novos servidores em minutos, sozinho, sem ninguem precisar fazer nada. Quando o acesso cai (de madrugada, por exemplo), ele desliga os servidores extras para economizar dinheiro.

**Analogia:** e como um restaurante que tem 10 mesas normalmente, mas quando chega um grupo grande, magicamente aparecem mais mesas, e quando o grupo vai embora, as mesas desaparecem e você nao paga por elas.

Isso se chama **Auto Scaling** (escalonamento automatico).

---

### 2. Se um datacenter cair, o outro assume

A AWS possui vários datacenters físicos em cada região do mundo. A Escola Tech agora roda em **dois datacenters ao mesmo tempo**, chamados de Zonas de Disponibilidade A e B.

Se um deles apresentar algum problema (queda de energia, falha de hardware ou qualquer outro incidente), o outro continua atendendo normalmente. Os alunos nem percebem que algo aconteceu.

**Analogia:** é como ter dois geradores de energia em vez de apenas um. Se um falhar, o outro entra em funcionamento automaticamente.

Isso se chama Multi-AZ (múltiplas zonas de disponibilidade).

---

### 3. O tráfego é distribuído de forma inteligente

Antes, todo mundo chegava no mesmo servidor. Agora, existe um **balanceador de carga**, pense nele como um recepcionista eficiente que, quando chegam 1.000 pessoas ao mesmo tempo, distribui cada uma para um servidor diferente, evitando que um so servidor fique sobrecarregado.

Se algum servidor começar a apresentar problemas, o balanceador deixa de enviar novas requisições para ele automaticamente, até que volte a funcionar corretamente.

Isso se chama **Application Load Balancer (ALB)**.

---

## Como isso afeta o dia a dia da Escola Tech

| Situacao | Antes (servidor proprio) | Agora (AWS) |
|---|---|---|
| Dia de matrícula com 1.000 acessos | Site cai | Sistema cria servidores extras automaticamente |
| Madrugada com 5 acessos | Servidor ligado, pagando | Sistema reduz para o minimo e economiza |
| Datacenter com problema | Site fora até alguem consertar | Outro datacenter assume em segundos |
| Servidor com defeito físico | Precisa de técnico presencial | AWS substitui automaticamente |
| Campanha de marketing viraliza | Caos | Sistema cresce junto com o trafego |

---

## Quanto custa comparado ao servidor próprio

Você pode estar pensando: "mas a nuvem não é cara?"

Veja a comparação real:

**Servidor físico (custo real):**
- Hardware inicial: R$ 15.000+
- Manutenção anual: R$ 3.000+
- Energia elétrica: R$ 400/mes
- Tecnico de TI para emergências: variável
- Se o servidor estraga em pleno dia de matrícula: prejuizo potencialmente muito alto.

**AWS (o que a Escola Tech paga agora):**
- Investimento inicial: R$ 0
- Custo mensal estimado: R$ 997/mês (tudo incluido)
- Escala automaticamente — paga so pelo que usa
- Suporte e atualizacoes de segurança: inclusos

**Em um ano:**
- Servidor proório: R$ 15.000 + R$ 4.800 (energia) + R$ 3.000 (manutenção) = **R$ 22.800+**
- AWS: R$ 997 x 12 = **R$ 11.964**

A AWS custa **menos da metade** e ainda é mais segura, mais rapida e não cai.

---

## E a segurança dos dados dos alunos?

Três camadas protegem os dados dos alunos:

**Firewall inteligente:** antes de qualquer pedido chegar ao site, ele passa por um sistema que identifica e bloqueia ataques automaticamente, como alguém tentando roubar senhas ou invadir o sistema.

**Criptografia:** todos os dados dos alunos ficam criptografados, como se fossem guardados em um cofre. Mesmo que alguém conseguisse acesso fisico ao servidor da Amazon (algo praticamente impossivel), não conseguiria ler nada.

**Sem senha no codigo:** as senhas do banco de dados nunca ficam escritas em nenhum arquivo do sistema. Elas ficam guardadas em um serviço especial que libera o acesso apenas para quem tem permissão.

---

## O que é o Terraform (e por que importa)

Toda essa infraestrutura foi criada usando **Terraform**, uma ferramenta que permite descrever a infraestrutura como um texto, da mesma forma que um arquiteto escreve uma planta baixa antes de construir uma casa.

Isso significa que:

- Se precisar recriar tudo em outro lugar, basta rodar um comando
- Toda mudança fica registrada no histórico (como um Google Docs com histórico de versões)
- Nenhuma configuração fica perdida na cabeça de uma única pessoa

---

## O que vem a seguir (evolução planejada)

A arquitetura atual resolve o problema central. No futuro, a Horus Tech planeja adicionar:

- **Chatbot com IA** para responder duvidas dos alunos automaticamente (Amazon Lex + Bedrock)
- **Recomendação de cursos** personalizada para cada aluno (Amazon Personalize)
- **Leitura automatica de documentos** de matrícula sem intervenção humana (Amazon Textract)

Esses serviços serão adicionados sobre a mesma infraestrutura, sem precisar recomeçar do zero.

---

## Resumo em uma frase

> A Escola Tech trocou um servidor físico que cabia 1 copo de água por uma torneira automatica que se abre tanto quanto necessario, e voçê so paga pela água que usa.


