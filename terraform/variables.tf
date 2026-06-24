# ---------------------------------------------------------------------------
# Projeto
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS onde a infraestrutura será criada"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome curto do projeto — usado em prefixos de recursos e tags"
  type        = string
  default     = "horus-tech"
}

variable "environment" {
  description = "Nome do ambiente (lab, dev, prod)"
  type        = string
  default     = "lab"
}

# ---------------------------------------------------------------------------
# Rede
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas (ALB e NAT Gateway), uma por AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (EC2), uma por AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Lista de AZs a usar — deve ter o mesmo tamanho das listas de CIDRs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ---------------------------------------------------------------------------
# Compute / ASG
# ---------------------------------------------------------------------------

variable "instance_type" {
  description = "Tipo de instância EC2 do Auto Scaling Group"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Número mínimo de instâncias no ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Número máximo de instâncias no ASG durante picos"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Capacidade desejada inicial do ASG"
  type        = number
  default     = 2
}

variable "cpu_target_value" {
  description = "Percentual de CPU alvo para a política de Target Tracking Scaling"
  type        = number
  default     = 70
}

variable "logo_url" {
  description = "URL da imagem do logo exibida na página PHP. Prefira um bucket S3 próprio ao Imgur."
  type        = string
  default     = "https://i.imgur.com/JDLjQCb.png"
}
