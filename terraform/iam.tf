resource "google_service_account" "broker" {
  account_id   = "${var.deployment_prefix}-broker-sa"
  display_name = "${var.deployment_prefix} Redpanda Broker Service Account"
}
