resource "google_storage_bucket" "cloud_topics" {
  name                        = "${var.deployment_prefix}-cloud-topics-${var.gcp_project}"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = local.common_labels
}

resource "google_storage_bucket_iam_member" "broker_storage_admin" {
  bucket = google_storage_bucket.cloud_topics.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.broker.email}"
}
