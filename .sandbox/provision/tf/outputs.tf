output "public_dns" {
  value = aws_instance.vm.public_dns
}

output "public_ip" {
  value = aws_instance.vm.public_ip
}

output "password" {
  value = rsadecrypt(aws_instance.vm.password_data, file(var.keypair_file))
}