# Proposta de arquitura para a Escola Tech

![Arquitetura do projeto - Draw.io](images/arquitetura-horus-tech.png)

### Componentes principais

| Camada | Servico | Funcao |
|---|---|---|
| DNS | Amazon Route 53 | Roteamento e failover de DNS |
| Borda | AWS WAF + Shield Standard | Firewall de aplicacao web e protecao DDoS |
| CDN | Amazon CloudFront + S3 | Cache global de conteudo estatico |
| Rede | VPC + Subnets + NAT Gateway | Isolamento e segmentacao de rede |
| Balanceamento | Application Load Balancer (ALB) | Distribuicao de trafego entre AZs |
| Compute | Amazon EC2 (t3.micro) | Servidores de aplicacao |
| Elasticidade | Auto Scaling Group (ASG) | Escala automatica por CPU e requisicoes |
| Banco de dados | Amazon RDS PostgreSQL Multi-AZ | Banco relacional com failover automatico |
| Identidade | AWS IAM | Controle de acesso e permissoes |
| Segredos | AWS Secrets Manager | Credenciais sem hardcode no codigo |
| Observabilidade | CloudWatch + SNS | Metricas, alarmes e notificacoes |
| Auditoria | AWS CloudTrail | Log de todas as acoes na conta |
| Backup | AWS Backup + RDS Snapshots | Recuperacao point-in-time |

---
## Seguranca em camadas (Defense in Depth)

```
Internet
   |
   [WAF] ← bloqueia SQL Injection, XSS, bots maliciosos (OWASP Top 10)
   |
   [Shield Standard] ← absorve ataques DDoS volumetricos (gratis)
   |
   [CloudFront] ← oculta o IP real do ALB, termina TLS na borda
   |
   [SG-ALB] ← aceita apenas 80/443 da internet
   |
   [SG-EC2] ← aceita apenas trafego originado do SG-ALB
   |
   [SG-RDS] ← aceita porta 5432 apenas do SG-EC2
   |
   [KMS] ← dados em repouso criptografados AES-256
   |
   [Secrets Manager] ← senha do banco nunca aparece no codigo
   |
   [CloudTrail] ← tudo logado, quem fez, o que, quando, de qual IP
```

**Principio aplicado:** Menor Privilegio - cada camada so conhece a anterior. O banco nunca e acessivel pela internet. As EC2 nunca sao acessiveis diretamente. O acesso administrativo e feito via SSM Session Manager, sem porta 22 exposta.

---

## Auto Scaling - como funciona

O ASG usa **Target Tracking Scaling** com duas politicas simultaneas:

**Por CPU** - quando a CPU media de todas as instancias ultrapassa 70%, o ASG provisiona uma nova instancia automaticamente. Quando cai abaixo de 70%, remove instancias ociosas.

**Por requisicoes** - quando o numero de requisicoes por instancia ultrapassa o alvo configurado, o ASG escala independentemente da CPU. Isso cobre picos de trafego repentinos (como campanhas de marketing) onde a CPU pode ainda nao ter subido.

```
Trafego normal   →  2 instancias rodando (asg_min_size)
Campanha marketing → CPU sobe → ASG cria instancias ate asg_max_size
Madrugada        →  CPU cai → ASG remove instancias ate asg_min_size
```

 ASG leva de 3 a 5 minutos para detectar a carga e provisionar novas instancias. E o comportamento real da AWS - nao uma simulacao.

---

## RDS Multi-AZ - failover automatico

O banco de dados roda em modo **Multi-AZ**: existe uma instancia primaria em `us-east-1a` e uma standby sincronizada em `us-east-1b`. Se a AZ primaria falhar, a AWS promove o standby automaticamente em 60-120 segundos, sem intervencao manual e sem perda de dados.

Para demonstrar o failover no TCC:

```bash
# Forcado via console AWS: RDS > Databases > [seu banco] > Actions > Reboot with failover
# Isso simula exatamente o que aconteceria numa falha real de datacenter
```

---

## Estimativa de custo (us-east-1, em uso normal)

| Servico | Config | USD/mes |
|---|---|---|
| EC2 x2 (baseline ASG) | t3.micro | ~$15 |
| Application Load Balancer | - | ~$20 |
| RDS PostgreSQL Multi-AZ | db.t3.micro | ~$50 |
| NAT Gateway x2 | - | ~$65 |
| CloudWatch + SNS + CloudTrail + S3 | - | ~$10 |
| **Total baseline** | | **~$160/mes** |

> O custo de 6 horas (para gravar o video do TCC) e aproximadamente **US$ 1,20 (~R$ 6,50)**.

---

## Roadmap — Evolucao futura

A arquitetura foi projetada para crescer. As proximas camadas planejadas:

- [ ] **CloudFront + WAF** — CDN global e protecao avancada na borda
- [ ] **ElastiCache Redis** — cache de sessoes para reduzir carga no RDS
- [ ] **Amazon Lex + Bedrock** — chatbot de suporte ao aluno com IA generativa
- [ ] **Amazon Personalize** — recomendacao personalizada de cursos
- [ ] **Amazon Textract** — leitura automatica de documentos de matricula
- [ ] **Savings Plans** — reducao de custo de ate 40% com compromisso de 1 ano
- [ ] **Remote State** — estado do Terraform em S3 + DynamoDB para trabalho em equipe
- [ ] **GitHub Actions** — pipeline CI/CD para deploy automatizado

---