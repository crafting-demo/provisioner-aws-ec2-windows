output "public_dns" {
  value = length(aws_instance.vm) > 0 ? aws_instance.vm[0].public_dns : null
}

output "public_ip" {
  value = length(aws_instance.vm) > 0 ? aws_instance.vm[0].public_ip : null
}

output "password" {
  value     = length(aws_instance.vm) > 0 ? rsadecrypt(aws_instance.vm[0].password_data, file(var.keypair_file)) : null
  sensitive = true
}

output "volume_id" {
  value = aws_ebs_volume.data_volume.id
}
