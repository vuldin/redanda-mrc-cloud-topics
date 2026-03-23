# Broker public IPs
output "broker_public_ips_us" {
  description = "Public IPs of US brokers"
  value       = google_compute_instance.broker_us[*].network_interface[0].access_config[0].nat_ip
}

output "broker_public_ips_eu" {
  description = "Public IPs of EU brokers"
  value       = google_compute_instance.broker_eu[*].network_interface[0].access_config[0].nat_ip
}

output "broker_public_ips_kr" {
  description = "Public IPs of KR brokers"
  value       = google_compute_instance.broker_kr[*].network_interface[0].access_config[0].nat_ip
}

# Broker private IPs
output "broker_private_ips_us" {
  description = "Private IPs of US brokers"
  value       = google_compute_instance.broker_us[*].network_interface[0].network_ip
}

output "broker_private_ips_eu" {
  description = "Private IPs of EU brokers"
  value       = google_compute_instance.broker_eu[*].network_interface[0].network_ip
}

output "broker_private_ips_kr" {
  description = "Private IPs of KR brokers"
  value       = google_compute_instance.broker_kr[*].network_interface[0].network_ip
}

# Client IPs
output "client_ip_us" {
  description = "Public IP of US client"
  value       = google_compute_instance.client_us.network_interface[0].access_config[0].nat_ip
}

output "client_ip_eu" {
  description = "Public IP of EU client"
  value       = google_compute_instance.client_eu.network_interface[0].access_config[0].nat_ip
}

output "client_ip_kr" {
  description = "Public IP of KR client"
  value       = google_compute_instance.client_kr.network_interface[0].access_config[0].nat_ip
}

# Monitor
output "monitor_ip" {
  description = "Public IP of monitoring instance"
  value       = google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}:9090"
}

# GCS
output "gcs_bucket_name" {
  description = "GCS bucket for Cloud Topics"
  value       = google_storage_bucket.cloud_topics.name
}

# SSH commands
output "ssh_commands" {
  description = "SSH commands for all instances"
  value = {
    broker_us = [for inst in google_compute_instance.broker_us : "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${inst.network_interface[0].access_config[0].nat_ip}"]
    broker_eu = [for inst in google_compute_instance.broker_eu : "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${inst.network_interface[0].access_config[0].nat_ip}"]
    broker_kr = [for inst in google_compute_instance.broker_kr : "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${inst.network_interface[0].access_config[0].nat_ip}"]
    client_us = "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${google_compute_instance.client_us.network_interface[0].access_config[0].nat_ip}"
    client_eu = "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${google_compute_instance.client_eu.network_interface[0].access_config[0].nat_ip}"
    client_kr = "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${google_compute_instance.client_kr.network_interface[0].access_config[0].nat_ip}"
    monitor   = "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}"
  }
}

# Seed servers
output "seed_servers" {
  description = "Seed server addresses for Redpanda cluster bootstrap"
  value = concat(
    [for inst in google_compute_instance.broker_us : "${inst.network_interface[0].network_ip}:33145"],
    [for inst in google_compute_instance.broker_eu : "${inst.network_interface[0].network_ip}:33145"],
    [for inst in google_compute_instance.broker_kr : "${inst.network_interface[0].network_ip}:33145"]
  )
}

# Inventory file
output "inventory_file" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}
