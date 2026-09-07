resource "aws_iam_role" "wordpress" {
  name = "wordpress-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy" "read_database_secret" {
  name = "read-wordpress-database-secret"
  role = aws_iam_role.wordpress.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_db_instance.app.master_user_secret[0].secret_arn
    }]
  })

}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.wordpress.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server" {
  role       = aws_iam_role.wordpress.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "wordpress" {
  name = "wordpress-ec2"
  role = aws_iam_role.wordpress.name
}