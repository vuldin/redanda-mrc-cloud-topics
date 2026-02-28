output "broker_us_public_ips" {
  description = "Public IPs of US brokers"
  value       = aws_instance.broker_us[*].public_ip
}

output "broker_eu_public_ips" {
  description = "Public IPs of EU brokers"
  value       = aws_instance.broker_eu[*].public_ip
}

output "broker_ap_public_ips" {
  description = "Public IPs of AP brokers"
  value       = aws_instance.broker_ap[*].public_ip
}

output "client_us_public_ip" {
  description = "Public IP of US client"
  value       = aws_instance.client_us.public_ip
}

output "client_eu_public_ip" {
  description = "Public IP of EU client"
  value       = aws_instance.client_eu.public_ip
}

output "client_ap_public_ip" {
  description = "Public IP of AP client"
  value       = aws_instance.client_ap.public_ip
}

output "monitor_public_ip" {
  description = "Public IP of monitoring instance"
  value       = aws_instance.monitor.public_ip
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${aws_instance.monitor.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${aws_instance.monitor.public_ip}:9090"
}

output "mrap_alias" {
  description = "S3 Multi-Region Access Point alias"
  value       = aws_s3control_multi_region_access_point.mrap.alias
}

output "mrap_endpoint" {
  description = "S3 MRAP endpoint"
  value       = "${aws_s3control_multi_region_access_point.mrap.alias}.accesspoint.s3-global.amazonaws.com"
}

output "ssh_commands" {
  description = "SSH commands for all instances"
  value = {
    broker_us = [for ip in aws_instance.broker_us[*].public_ip : "ssh -i <key> ${var.ssh_user}@${ip}"]
    broker_eu = [for ip in aws_instance.broker_eu[*].public_ip : "ssh -i <key> ${var.ssh_user}@${ip}"]
    broker_ap = [for ip in aws_instance.broker_ap[*].public_ip : "ssh -i <key> ${var.ssh_user}@${ip}"]
    monitor   = "ssh -i <key> ${var.ssh_user}@${aws_instance.monitor.public_ip}"
  }
}

output "seed_servers" {
  description = "Seed server IPs (one from each region)"
  value = [
    aws_instance.broker_us[0].private_ip,
    aws_instance.broker_eu[0].private_ip,
    aws_instance.broker_ap[0].private_ip,
  ]
}

output "inventory_file" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}
