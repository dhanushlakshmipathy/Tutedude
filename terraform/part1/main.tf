terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Generate a new SSH key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

# Security Group: Acts like a firewall to control traffic
resource "aws_security_group" "app_sg" {
  name        = "flask-express-sg"
  description = "Allow SSH, HTTP, Flask, and Express"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.app_sg.name]

  # User Data to install system dependencies
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip nodejs npm
              EOF

  # Connection for provisioners
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  # Upload Backend
  provisioner "file" {
    source      = "../../backend"
    destination = "/home/ubuntu/backend"
  }

  # Upload Frontend
  provisioner "file" {
    source      = "../../frontend"
    destination = "/home/ubuntu/frontend"
  }

  # This block runs commands on the instance after it's created.
  # We use it to install dependencies and start the applications.
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait", # Wait for the instance to be fully ready
      
      # Go to the backend folder, install Python libraries, and start the app in the background
      "cd /home/ubuntu/backend",
      "pip3 install -r requirements.txt",
      "nohup python3 app.py > output.log 2>&1 &",
      
      # Go to the frontend folder, install Node packages, and start the app
      "cd /home/ubuntu/frontend",
      "npm install",
      "nohup node server.js > output.log 2>&1 &",
      
      "echo 'Deployment complete'"
    ]
  }
}
