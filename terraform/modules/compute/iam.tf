# ---------------------------------------------------------------------------
# IAM Role para as instâncias EC2.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Acesso via Systems Manager Session Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Policy inline com escopo mínimo: lê apenas o ASG e as instâncias deste projeto
resource "aws_iam_role_policy" "asg_describe" {
  name = "${var.project_name}-asg-describe"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeThisASGOnly"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeScalingActivities"
        ]
        # Autoscaling describe-* não suporta ARN de recurso individual na AWS
        # obrigatório usar "*", mas limitamos as Actions ao mínimo necessário.
        Resource = "*"
      },
      {
        Sid    = "DescribeEC2Instances"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
