variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "deployer-key"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 (us-east-1)"
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
}
