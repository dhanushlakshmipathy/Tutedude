output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "flask_url" {
  description = "URL for Flask Backend"
  value       = "http://${aws_instance.app_server.public_ip}:5000"
}

output "express_url" {
  description = "URL for Express Frontend"
  value       = "http://${aws_instance.app_server.public_ip}:3000"
}

output "private_key_pem" {
  description = "Private key to SSH into the instance"
  value       = tls_private_key.example.private_key_pem
  sensitive   = true
}
