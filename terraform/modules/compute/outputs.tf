output "alb_dns_name" {
  description = "DNS público do Load Balancer"
  value       = aws_lb.main.dns_name
}

output "asg_name" {
  description = "Nome do Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "sg_alb_id" {
  description = "ID do Security Group do ALB"
  value       = aws_security_group.alb.id
}

output "sg_ec2_id" {
  description = "ID do Security Group das EC2"
  value       = aws_security_group.ec2.id
}
