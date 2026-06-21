#!/bin/bash
# ---------------------------------------------------------------------------
# Script de inicializacao das instancias EC2 da Escola Tech.
# Instala um servidor web minimo para health checks do ALB e demonstracao
# de Auto Scaling, sem hardcode de credenciais (busca do Secrets Manager).
# ---------------------------------------------------------------------------

set -e

dnf install -y httpd amazon-cloudwatch-agent

#INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
#AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="pt-br">
<head><title>Escola Tech</title></head>
<body style="font-family: sans-serif; text-align: center; padding-top: 80px;">
  <h1>Escola Tech - Plataforma de Cursos</h1>
  <p>Servido pela instancia: <strong>$INSTANCE_ID</strong></p>
  <p>Availability Zone: <strong>$AZ</strong></p>
</body>
</html>
EOF

cat > /var/www/html/health <<EOF
OK
EOF

systemctl enable httpd
systemctl start httpd
