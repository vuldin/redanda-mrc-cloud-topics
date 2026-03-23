locals {
  peering_pairs = {
    us_to_eu = { source = "us", target = "eu" }
    eu_to_us = { source = "eu", target = "us" }
    us_to_kr = { source = "us", target = "kr" }
    kr_to_us = { source = "kr", target = "us" }
    eu_to_kr = { source = "eu", target = "kr" }
    kr_to_eu = { source = "kr", target = "eu" }
  }
}

resource "google_compute_network_peering" "mesh" {
  for_each = local.peering_pairs

  name                 = "${var.deployment_prefix}-peer-${each.value.source}-to-${each.value.target}"
  network              = google_compute_network.vpc[each.value.source].self_link
  peer_network         = google_compute_network.vpc[each.value.target].self_link
  export_custom_routes = true
  import_custom_routes = true
}
