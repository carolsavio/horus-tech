# ---------------------------------------------------------------------------
# SG-ALB: único ponto que aceita tráfego direto da internet.
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Aceita HTTP e HTTPS da internet para o Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP da internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS da internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Forward traffic to EC2 instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-alb"
  }
}

# ---------------------------------------------------------------------------
# SG-EC2: aceita HTTP APENAS do SG-ALB.
#
# Mudança em relação ao original:
#   - Removida a regra SSH (porta 22) aberta para 0.0.0.0/0.
#   - Acesso administrativo agora via Systems Manager Session Manager,
#     que não exige nenhuma porta aberta, autenticação via IAM.
# ---------------------------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Outbound internet via NAT for package updates and AWS API"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP apenas do Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound internet via NAT for package updates and AWS API"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ec2"
  }
}
