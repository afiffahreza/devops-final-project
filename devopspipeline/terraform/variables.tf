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

variable "KEY_PAIR_NAME" {
  description = "Key pair name for EC2 instances"
  type        = string
}

variable "KEY_PAIR_FILE" {
  description = "Path to the private key file for EC2 instances"
  type        = string
}
