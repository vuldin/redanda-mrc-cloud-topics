# --- Generate Ansible Inventory ---

locals {
  # First broker in each region is the Envoy host
  envoy_us_ip = aws_instance.broker_us[0].private_ip
  envoy_eu_ip = aws_instance.broker_eu[0].private_ip
  envoy_ap_ip = aws_instance.broker_ap[0].private_ip

  # MRAP alias for Envoy config
  mrap_alias = aws_s3control_multi_region_access_point.mrap.alias
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../artifacts/hosts_mrc.ini"

  content = templatefile("${path.module}/inventory.ini.tpl", {
    ssh_user   = var.ssh_user
    mrap_alias = local.mrap_alias

    broker_us_public_ips  = aws_instance.broker_us[*].public_ip
    broker_us_private_ips = aws_instance.broker_us[*].private_ip
    broker_eu_public_ips  = aws_instance.broker_eu[*].public_ip
    broker_eu_private_ips = aws_instance.broker_eu[*].private_ip
    broker_ap_public_ips  = aws_instance.broker_ap[*].public_ip
    broker_ap_private_ips = aws_instance.broker_ap[*].private_ip

    envoy_us_ip = local.envoy_us_ip
    envoy_eu_ip = local.envoy_eu_ip
    envoy_ap_ip = local.envoy_ap_ip

    client_us_public_ip  = aws_instance.client_us.public_ip
    client_us_private_ip = aws_instance.client_us.private_ip
    client_eu_public_ip  = aws_instance.client_eu.public_ip
    client_eu_private_ip = aws_instance.client_eu.private_ip
    client_ap_public_ip  = aws_instance.client_ap.public_ip
    client_ap_private_ip = aws_instance.client_ap.private_ip

    monitor_public_ip  = aws_instance.monitor.public_ip
    monitor_private_ip = aws_instance.monitor.private_ip
  })
}

resource "local_file" "envoy_vars" {
  filename = "${path.module}/../artifacts/envoy_vars.yml"

  content = yamlencode({
    mrap_alias = local.mrap_alias
  })
}
