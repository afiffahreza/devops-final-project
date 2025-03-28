provider "aws" {
  region = "us-east-2"
}

variable "GH_DEPLOY_KEY" {
  type = string
}

variable "GH_REPO_URL" {
  type = string
}

resource "aws_security_group" "pipeline_sg" {
  name        = "open-ports"
  description = "Open ports"

  ingress {
    description = "HTTP app on 8080"
    from_port   = 3000
    to_port     = 3000
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

resource "aws_instance" "pipeline" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.pipeline_sg.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    GH_DEPLOY_KEY = var.GH_DEPLOY_KEY,
    GH_REPO_URL   = var.GH_REPO_URL
  })
}

resource "aws_instance" "prod" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.micro"
}

resource "aws_s3_bucket" "logbucket" {
  bucket        = "17636-devsecops-g2loggingbucket"
  force_destroy = true
}
