resource "google_compute_network" "vpc" {
  for_each = local.regions

  name                    = "${var.deployment_prefix}-vpc-${each.key}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  for_each = local.regions

  name          = "${var.deployment_prefix}-subnet-${each.key}"
  ip_cidr_range = each.value.subnet_cidr
  region        = each.value.region
  network       = google_compute_network.vpc[each.key].id
}
