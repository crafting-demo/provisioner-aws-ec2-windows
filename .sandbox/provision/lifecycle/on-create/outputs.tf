output "public_dns" {
  value = aws_instance.vm.public_dns
}

output "public_ip" {
  value = aws_instance.vm.public_ip
}

output "volume_id" {
  value = aws_ebs_volume.data_volume.id
}

output "password" {
  value = rsadecrypt(aws_instance.vm.password_data, file(var.keypair_file))
}