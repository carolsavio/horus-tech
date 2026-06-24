# ---------------------------------------------------------------------------
# Horus Tech — Infraestrutura Escola Tech
# Arquivo raiz: orquestra os módulos. Nenhum recurso AWS é criado aqui.
# ---------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  ami_id               = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  cpu_target_value     = var.cpu_target_value
  logo_url             = var.logo_url
  userdata_path        = "${path.module}/userdata_corrigido.sh"
}
