# Escola Tech - Hospedagem Institucional Escalável na AWS

![Logo da empresa Horus tech](docs/images/horustech.png)
<div align="center">

<!-- TCC -->
[![TCC](https://img.shields.io/badge/TCC-Projeto%20Final-F5A623?style=for-the-badge&logo=academia&logoColor=white)]()
[![Escola%20Tech](https://img.shields.io/badge/Cliente-Escola%20Tech-6B4FFF?style=for-the-badge&logo=bookstack&logoColor=white)]()
![Horus%20Tech](https://img.shields.io/badge/Horus%20Tech-Solucao%20em%20Nuvem-1a2235?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PGNpcmNsZSBjeD0iMTIiIGN5PSI4IiByPSI0IiBmaWxsPSIjZjVhNjIzIi8+PHBhdGggZD0iTTIgMjBhMTAgMTAgMCAwIDEgMjAgMCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNmI0ZmZmIiBzdHJva2Utd2lkdGg9IjIiLz48L3N2Zz4=&logoColor=F5A623)
[![AWS](https://img.shields.io/badge/Amazon%20AWS-Cloud%20Provider-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![IaC](https://img.shields.io/badge/IaC-Infrastructure%20as%20Code-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)]()
[![License](https://img.shields.io/badge/Licenca-MIT-3DDC84?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE)
</div>


Projeto desenvolvido como parte do Trabalho de Conclusão de Curso (TCC), com o objetivo de propor uma arquitetura de hospedagem web escalável, resiliente e segura para a empresa fictícia Escola Tech, uma plataforma de cursos online.

A solução foi projetada para atender períodos de tráfego constante e picos súbitos de acessos durante campanhas de marketing, especialmente no lançamento de matrículas.

---
![Frontend escola tech](docs/images/frontend-escolatech.png)
## Contexto do Projeto

A Escola Tech possui uma plataforma de cursos online e está lançando uma nova página de matrículas. O ambiente anterior utilizava apenas um servidor local, o que gerava riscos de indisponibilidade quando muitos alunos tentavam acessar o site simultaneamente.

Para resolver esse problema, foi proposta uma infraestrutura em nuvem na AWS capaz de:

- Manter o site disponível mesmo em caso de falha de servidores;
- Distribuir requisições entre múltiplas instâncias;
- Criar e remover servidores automaticamente conforme a demanda;
- Reduzir custos durante períodos de pouco acesso;
- Garantir segurança no acesso aos recursos da aplicação.

---

## Objetivo

Implementar uma arquitetura de hospedagem institucional utilizando serviços da AWS, com foco em:

- Alta disponibilidade
- Escalabilidade automática
- Balanceamento de carga
- Segurança de rede
- Otimização de custos
- Monitoramento da integridade da aplicação

---


[➔ Acesse a arquitura do projeto completo](docs/architecture.md)

[➔ Dúvidas sobre o projeto? - Acesse o resumo](docs/why-this-architecture.md)

---
### Autoria do projeto de TCC 


| Nome | Papel |
|---|---|
| Haroldo | Lider Técnico |
| Marcelo | Arquiteto |
| Caroline | Desenvolvedora |
| Denise | Desenvolvedora |
| Jessica | Desenvolvedora |
| Mirele | Scrum Master |

- **Curso:** AWS ReStart
- **Instituição:** Escola da Nuvem
- **Ano:** 2026