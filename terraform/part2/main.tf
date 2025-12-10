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

# --- Networking ---

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "flask-express-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "flask-express-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "flask-express-public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "flask-express-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Security Groups ---

resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow SSH and 5000 from Frontend"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id] # Allow from Frontend SG
  }
  
  # Also allow from public for debugging if needed, but prompt says "Allow communication between the two instances".
  # I will stick to SG referencing for security best practice.
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Key Pair ---

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

# --- Instances ---

# Backend Instance
resource "aws_instance" "backend" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              EOF

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "../../backend"
    destination = "/home/ubuntu/backend"
  }

  # Run these commands on the backend server
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "cd /home/ubuntu/backend",
      "pip3 install -r requirements.txt",
      "nohup python3 app.py > output.log 2>&1 &"
    ]
  }
  
  tags = {
    Name = "Flask-Backend"
  }
}

# Frontend Instance
resource "aws_instance" "frontend" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nodejs npm
              EOF

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "../../frontend"
    destination = "/home/ubuntu/frontend"
  }

  # Run these commands on the frontend server
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait", # Wait for user_data to finish
      "cd /home/ubuntu/frontend",
      "npm install",
      "export BACKEND_URL=http://${aws_instance.backend.private_ip}:5000/submit",
      "nohup node server.js > output.log 2>&1 &"
    ]
  }
  
  tags = {
    Name = "Express-Frontend"
  }
}
