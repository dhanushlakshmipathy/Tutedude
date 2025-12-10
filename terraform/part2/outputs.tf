output "frontend_public_ip" {
  description = "Public IP of the Frontend Instance"
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the Backend Instance"
  value       = aws_instance.backend.private_ip
}

output "backend_public_ip" {
  description = "Public IP of the Backend Instance (for debugging/SSH)"
  value       = aws_instance.backend.public_ip
}

output "frontend_url" {
  description = "URL for Express Frontend"
  value       = "http://${aws_instance.frontend.public_ip}:3000"
}

output "private_key_pem" {
  description = "Private key to SSH into the instances"
  value       = tls_private_key.example.private_key_pem
  sensitive   = true
}
