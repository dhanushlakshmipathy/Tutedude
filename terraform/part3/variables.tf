variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for ECS Cluster"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "ecs-key"
}

variable "ami_id" {
  description = "ECS Optimized AMI for us-east-1 (Amazon Linux 2)"
  default     = "ami-062f7200baf2fa504" # Check for latest ECS optimized AMI
}
