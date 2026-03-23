resource "google_compute_instance" "monitor" {
  name         = "${var.deployment_prefix}-monitor"
  machine_type = var.monitor_instance_type
  zone         = local.regions.us.zone

  labels = merge(local.common_labels, {
    role   = "monitor"
    region = "us"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 50
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["us"].id
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["${var.deployment_prefix}-monitor"]
}
