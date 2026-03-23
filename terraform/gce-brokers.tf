data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "broker_us" {
  count = var.brokers_per_region

  name         = "${var.deployment_prefix}-broker-us-${count.index}"
  machine_type = var.broker_instance_type
  zone         = local.regions.us.zone

  labels = merge(local.common_labels, {
    role   = "broker"
    region = "us"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30
      type  = "pd-ssd"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["us"].id
    access_config {}
  }

  service_account {
    email  = google_service_account.broker.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["${var.deployment_prefix}-broker"]
}

resource "google_compute_instance" "broker_eu" {
  count = var.brokers_per_region

  name         = "${var.deployment_prefix}-broker-eu-${count.index}"
  machine_type = var.broker_instance_type
  zone         = local.regions.eu.zone

  labels = merge(local.common_labels, {
    role   = "broker"
    region = "eu"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30
      type  = "pd-ssd"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["eu"].id
    access_config {}
  }

  service_account {
    email  = google_service_account.broker.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["${var.deployment_prefix}-broker"]
}

resource "google_compute_instance" "broker_kr" {
  count = var.brokers_per_region

  name         = "${var.deployment_prefix}-broker-kr-${count.index}"
  machine_type = var.broker_instance_type
  zone         = local.regions.kr.zone

  labels = merge(local.common_labels, {
    role   = "broker"
    region = "kr"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30
      type  = "pd-ssd"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["kr"].id
    access_config {}
  }

  service_account {
    email  = google_service_account.broker.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["${var.deployment_prefix}-broker"]
}
