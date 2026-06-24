output "load_balancer_dns" {
  description = "DNS do Load Balancer — acesse este endereço no navegador para testar"
  value       = module.compute.alb_dns_name
}

output "alb_url" {
  description = "URL completa da aplicação"
  value       = "http://${module.compute.alb_dns_name}"
}

output "asg_name" {
  description = "Nome do Auto Scaling Group para monitorar no console"
  value       = module.compute.asg_name
}

output "next_steps" {
  description = "Próximos passos após o apply"
  value       = <<-EOT
    1. Acesse a aplicação:
       http://${module.compute.alb_dns_name}

    2. Rode o teste de carga (aguarde ~2 min para as instâncias subirem):
       ab -t 180 -c 200 -k http://${module.compute.alb_dns_name}/

    3. Acompanhe o Auto Scaling em tempo real:
       aws autoscaling describe-auto-scaling-groups \
         --auto-scaling-group-names ${module.compute.asg_name} \
         --query "AutoScalingGroups[0].Instances[].[InstanceId,AvailabilityZone,HealthStatus]" \
         --output table
  EOT
}
