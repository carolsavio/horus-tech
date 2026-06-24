variable "project_name" {
  description = "Prefixo de nomes dos recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC (vem do módulo networking)"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas para o ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para as EC2"
  type        = list(string)
}

variable "ami_id" {
  description = "ID da AMI a usar nas instâncias EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_target_value" {
  description = "Percentual de CPU alvo para Target Tracking Scaling"
  type        = number
  default     = 70
}

variable "logo_url" {
  description = "URL do logo exibido na página PHP"
  type        = string
}

variable "userdata_path" {
  description = "Caminho para o script de user_data (templatefile)"
  type        = string
}
