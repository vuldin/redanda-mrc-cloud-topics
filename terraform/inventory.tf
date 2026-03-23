resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.ini.tpl", {
    broker_us_instances  = google_compute_instance.broker_us
    broker_eu_instances  = google_compute_instance.broker_eu
    broker_kr_instances  = google_compute_instance.broker_kr
    client_us            = google_compute_instance.client_us
    client_eu            = google_compute_instance.client_eu
    client_kr            = google_compute_instance.client_kr
    monitor              = google_compute_instance.monitor
    ssh_user             = var.ssh_user
    gcs_bucket_name      = google_storage_bucket.cloud_topics.name
    brokers_per_region   = var.brokers_per_region
  })
  filename = "${path.module}/../artifacts/hosts_mrc.ini"
}

resource "local_file" "gcs_vars" {
  content  = yamlencode({
    gcs_bucket_name = google_storage_bucket.cloud_topics.name
  })
  filename = "${path.module}/../artifacts/gcs_vars.yml"
}
