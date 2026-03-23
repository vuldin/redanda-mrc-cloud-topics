# SSH access
resource "google_compute_firewall" "allow_ssh" {
  for_each = local.regions

  name    = "${var.deployment_prefix}-allow-ssh-${each.key}"
  network = google_compute_network.vpc[each.key].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
}

# Internal cluster traffic between peered VPCs
resource "google_compute_firewall" "allow_internal" {
  for_each = local.regions

  name    = "${var.deployment_prefix}-allow-internal-${each.key}"
  network = google_compute_network.vpc[each.key].name

  allow {
    protocol = "tcp"
    ports    = ["33145", "9092", "9644", "8082", "8081", "9100"]
  }

  source_ranges = ["10.0.0.0/8"]
}

# External Kafka API access
resource "google_compute_firewall" "allow_kafka_external" {
  for_each = local.regions

  name    = "${var.deployment_prefix}-allow-kafka-ext-${each.key}"
  network = google_compute_network.vpc[each.key].name

  allow {
    protocol = "tcp"
    ports    = ["9092"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.deployment_prefix}-broker"]
}

# External Admin API access
resource "google_compute_firewall" "allow_admin_external" {
  for_each = local.regions

  name    = "${var.deployment_prefix}-allow-admin-ext-${each.key}"
  network = google_compute_network.vpc[each.key].name

  allow {
    protocol = "tcp"
    ports    = ["9644"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.deployment_prefix}-broker"]
}

# Monitoring access (US network only)
resource "google_compute_firewall" "allow_prometheus" {
  name    = "${var.deployment_prefix}-allow-prometheus"
  network = google_compute_network.vpc["us"].name

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.deployment_prefix}-monitor"]
}

resource "google_compute_firewall" "allow_grafana" {
  name    = "${var.deployment_prefix}-allow-grafana"
  network = google_compute_network.vpc["us"].name

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.deployment_prefix}-monitor"]
}
