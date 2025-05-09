provider "aws" {
  region = "us-east-2"
}

# VARIABLES

variable "GH_DEPLOY_KEY" {
  type = string
  sensitive = true
}

variable "GH_REPO_URL" {
  type = string
}

variable "AWS_EIP" {
  type = string
}

# SECURITY GROUPS

resource "aws_security_group" "pipeline_sg" {
  name        = "pipeline-open-ports"
  description = "DevSecOps Pipeline Open ports"

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
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
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

resource "aws_security_group" "prod_sg" {
  name        = "prod-open-ports"
  description = "DevSecOps Prod Open ports"

  ingress {
    description = "SSH from DevSecOps Pipeline"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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

# IAM ROLES

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

# SSH KEYPAIR

resource "aws_key_pair" "pipeline_key" {
  key_name   = "pipeline-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaBXajEfKn43wVSHKUwB2xOgptZEBc3+t6f9rLGisLwtZk4jNxa23EpDYMWCs5BxiJ+Ue01d9p4gGwW9JJ8FCjPiO2s37Bk7TuWSW2WkHATSqnlOHe/Kny/vd5OaDYXQzbvhrUNO05m/Fprmw0HYKCTzPc4/e/IqrmzO9GsI5LNyVixFm3UZGYgnPopa9eKkuOhGUFA/xv+TX3TzGrEEzLGZXbHMAEsXOM6ukbJqQcfwZzBwmjJ0tuf4DXPtVXTm2ziDLTV3ARvJJdUSgwvJdZHKmZKVV4DAsbnM8x6nDW9KXUCHJdk5aYqUztqoIPDg4ypHKZtxJGlVh9MqzbDYeVoAE22jPXNKiYpCuFtrF5Q2gMj+8xws8eJvIEr87CkijPa5/0xbDy4Rmvs/DAmYLfgGmIq84lcXmbYTYvVnLgOJ00ZfjaHE0cTaWBBbZUDtTlawCbcJ6a0RhhlEZxQhQ3JfvMyN7qWgTeLwBizUptV5L1QFNriqdY6Ka9/OECOSWNaP8cY2zg1zfmcUqUZssNNBa/qLsrZolbxinf0x1A+46We8sKoym7QzK5SxLiidG2JuTuj+NWo8hgpGTrP1f2MPCDoatA2wEPjaML4zxmgHZACS7ODWBatBk7cqmRailzVyf2/bxt9Xj0QP8t5S1xfkdWykyHOlywpjjqyYNa+Q== afiffahreza@Afifs-Mac-mini.local"
}

# MAIN RESOURCES

resource "aws_instance" "pipeline" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.large"
  vpc_security_group_ids      = [aws_security_group.pipeline_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.pipeline_profile.name

  root_block_device {
    volume_size = 30
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    GH_DEPLOY_KEY = var.GH_DEPLOY_KEY,
    GH_REPO_URL   = var.GH_REPO_URL
    PROD_IP       = aws_instance.prod.private_ip
  })
}

# Polling webhook
# resource "aws_eip_association" "jenkins_ip_assoc" {
#   instance_id   = aws_instance.pipeline.id
#   allocation_id = var.AWS_EIP
# }

resource "aws_instance" "prod" {
  ami                     = "ami-0efc43a4067fe9a3e"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.prod_sg.id]
  key_name                = aws_key_pair.pipeline_key.key_name

  user_data = templatefile("${path.module}/user_data_prod.sh", {
    GH_DEPLOY_KEY = var.GH_DEPLOY_KEY,
    GH_REPO_URL   = var.GH_REPO_URL
  })
}

resource "aws_s3_bucket" "logbucket" {
  bucket        = "17636-devsecops-g2loggingbucket"
  force_destroy = true
}
