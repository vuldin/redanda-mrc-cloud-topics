[redpanda]
%{ for i, ip in broker_us_public_ips ~}
${ip} ansible_user=${ssh_user} ansible_become=True private_ip=${broker_us_private_ips[i]} rack=us-east-1 cloud_storage_region=us-east-1 envoy_endpoint=${envoy_us_ip}:9000 broker_id=${i}
%{ endfor ~}
%{ for i, ip in broker_eu_public_ips ~}
${ip} ansible_user=${ssh_user} ansible_become=True private_ip=${broker_eu_private_ips[i]} rack=eu-west-1 cloud_storage_region=eu-west-1 envoy_endpoint=${envoy_eu_ip}:9000 broker_id=${i + length(broker_us_public_ips)}
%{ endfor ~}
%{ for i, ip in broker_ap_public_ips ~}
${ip} ansible_user=${ssh_user} ansible_become=True private_ip=${broker_ap_private_ips[i]} rack=ap-southeast-1 cloud_storage_region=ap-southeast-1 envoy_endpoint=${envoy_ap_ip}:9000 broker_id=${i + length(broker_us_public_ips) + length(broker_eu_public_ips)}
%{ endfor ~}

[envoy]
${broker_us_public_ips[0]} ansible_user=${ssh_user} ansible_become=True private_ip=${envoy_us_ip} envoy_region=us-east-1 mrap_alias=${mrap_alias}
${broker_eu_public_ips[0]} ansible_user=${ssh_user} ansible_become=True private_ip=${envoy_eu_ip} envoy_region=eu-west-1 mrap_alias=${mrap_alias}
${broker_ap_public_ips[0]} ansible_user=${ssh_user} ansible_become=True private_ip=${envoy_ap_ip} envoy_region=ap-southeast-1 mrap_alias=${mrap_alias}

[monitor]
${monitor_public_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${monitor_private_ip}

[client]
${client_us_public_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_us_private_ip} rack=us-east-1 broker_ip=${broker_us_private_ips[0]}
${client_eu_public_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_eu_private_ip} rack=eu-west-1 broker_ip=${broker_eu_private_ips[0]}
${client_ap_public_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_ap_private_ip} rack=ap-southeast-1 broker_ip=${broker_ap_private_ips[0]}
