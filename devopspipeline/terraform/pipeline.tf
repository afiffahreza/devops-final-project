provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "pipeline" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.small"
}

resource "aws_instance" "prod" {
  ami           = "ami-0efc43a4067fe9a3e"
  instance_type = "t2.micro"
}

resource "aws_s3_bucket" "logbucket" {
  bucket        = "17636-devsecops-g2loggingbucket"
  force_destroy = true
}
