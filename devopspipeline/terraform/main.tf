provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "pipeline_sg" {
  name        = "open-ports"
  description = "Open ports"

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "Debug SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "pipeline_ec2_role" {
  name = "pipeline-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access" {
  name        = "S3-Access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "arn:aws:s3:::17636-devsecops-g2loggingbucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_to_pipeline" {
  role       = aws_iam_role.pipeline_ec2_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_instance_profile" "pipeline_profile" {
  name = "pipeline-instance-profile"
  role = aws_iam_role.pipeline_ec2_role.name
}

resource "aws_instance" "pipeline" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.pipeline_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.pipeline_profile.name

  user_data = templatefile("${path.module}/user_data.sh", {
    GH_DEPLOY_KEY = var.GH_DEPLOY_KEY,
    GH_REPO_URL   = var.GH_REPO_URL
  })
}

# Polling webhook
# resource "aws_eip_association" "jenkins_ip_assoc" {
#   instance_id   = aws_instance.pipeline.id
#   allocation_id = var.AWS_EIP
# }

resource "aws_instance" "prod" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.micro"
}

resource "aws_s3_bucket" "logbucket" {
  bucket        = "17636-devsecops-g2loggingbucket"
  force_destroy = true
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_key" {
  key_name   = var.KEY_PAIR_NAME
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = var.KEY_PAIR_FILE
}
