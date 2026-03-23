[redpanda]
%{ for i, inst in broker_us_instances ~}
${inst.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${inst.network_interface[0].network_ip} rack=us-east4 cloud_storage_region=us-east4 broker_id=${i} broker_ip=${inst.network_interface[0].access_config[0].nat_ip}
%{ endfor ~}
%{ for i, inst in broker_eu_instances ~}
${inst.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${inst.network_interface[0].network_ip} rack=europe-west1 cloud_storage_region=europe-west1 broker_id=${i + brokers_per_region} broker_ip=${inst.network_interface[0].access_config[0].nat_ip}
%{ endfor ~}
%{ for i, inst in broker_kr_instances ~}
${inst.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${inst.network_interface[0].network_ip} rack=asia-northeast3 cloud_storage_region=asia-northeast3 broker_id=${i + brokers_per_region * 2} broker_ip=${inst.network_interface[0].access_config[0].nat_ip}
%{ endfor ~}

[monitor]
${monitor.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${monitor.network_interface[0].network_ip}

[client]
${client_us.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_us.network_interface[0].network_ip}
${client_eu.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_eu.network_interface[0].network_ip}
${client_kr.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_kr.network_interface[0].network_ip}

[client_us]
${client_us.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_us.network_interface[0].network_ip}

[client_eu]
${client_eu.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_eu.network_interface[0].network_ip}

[client_kr]
${client_kr.network_interface[0].access_config[0].nat_ip} ansible_user=${ssh_user} ansible_become=True private_ip=${client_kr.network_interface[0].network_ip}

[redpanda:vars]
gcs_bucket_name=${gcs_bucket_name}
