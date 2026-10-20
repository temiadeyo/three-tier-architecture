##### EC2 IAM ROLE AND POLICY FOR SSM ACCESS #####
resource "aws_iam_role" "ssm_role" {
  name = "wordpress-ec2-role"

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

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role = aws_iam_role.ssm_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


##### EC2 INSTANCE PROFILE #####
resource "aws_iam_instance_profile" "app" {
  name = "wordpress-app-instance-profile"
  role = aws_iam_role.ssm_role.name
}
