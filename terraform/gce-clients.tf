resource "google_compute_instance" "client_us" {
  name         = "${var.deployment_prefix}-client-us"
  machine_type = var.client_instance_type
  zone         = local.regions.us.zone

  labels = merge(local.common_labels, {
    role   = "client"
    region = "us"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
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

  tags = ["${var.deployment_prefix}-client"]
}

resource "google_compute_instance" "client_eu" {
  name         = "${var.deployment_prefix}-client-eu"
  machine_type = var.client_instance_type
  zone         = local.regions.eu.zone

  labels = merge(local.common_labels, {
    role   = "client"
    region = "eu"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["eu"].id
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["${var.deployment_prefix}-client"]
}

resource "google_compute_instance" "client_kr" {
  name         = "${var.deployment_prefix}-client-kr"
  machine_type = var.client_instance_type
  zone         = local.regions.kr.zone

  labels = merge(local.common_labels, {
    role   = "client"
    region = "kr"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["kr"].id
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["${var.deployment_prefix}-client"]
}
