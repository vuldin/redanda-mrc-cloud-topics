# --- S3 Buckets (one per region) ---

resource "aws_s3_bucket" "us" {
  provider      = aws.us
  bucket        = "${var.deployment_prefix}-cloud-topics-us-east-1"
  force_destroy = true

  tags = { Name = "${var.deployment_prefix}-bucket-us", Region = "us-east-1" }
}

resource "aws_s3_bucket_versioning" "us" {
  provider = aws.us
  bucket   = aws_s3_bucket.us.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "eu" {
  provider      = aws.eu
  bucket        = "${var.deployment_prefix}-cloud-topics-eu-west-1"
  force_destroy = true

  tags = { Name = "${var.deployment_prefix}-bucket-eu", Region = "eu-west-1" }
}

resource "aws_s3_bucket_versioning" "eu" {
  provider = aws.eu
  bucket   = aws_s3_bucket.eu.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "ap" {
  provider      = aws.ap
  bucket        = "${var.deployment_prefix}-cloud-topics-ap-southeast-1"
  force_destroy = true

  tags = { Name = "${var.deployment_prefix}-bucket-ap", Region = "ap-southeast-1" }
}

resource "aws_s3_bucket_versioning" "ap" {
  provider = aws.ap
  bucket   = aws_s3_bucket.ap.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- S3 Multi-Region Access Point ---

resource "aws_s3control_multi_region_access_point" "mrap" {
  provider = aws.us

  details {
    name = "${var.deployment_prefix}-cloud-topics-mrap"

    region {
      bucket = aws_s3_bucket.us.id
    }
    region {
      bucket = aws_s3_bucket.eu.id
    }
    region {
      bucket = aws_s3_bucket.ap.id
    }
  }
}

# --- Cross-Region Replication ---

# IAM role for S3 replication
resource "aws_iam_role" "s3_replication" {
  name = "${var.deployment_prefix}-s3-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  name = "${var.deployment_prefix}-s3-replication"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.us.arn,
          aws_s3_bucket.eu.arn,
          aws_s3_bucket.ap.arn,
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.us.arn}/*",
          "${aws_s3_bucket.eu.arn}/*",
          "${aws_s3_bucket.ap.arn}/*",
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.us.arn}/*",
          "${aws_s3_bucket.eu.arn}/*",
          "${aws_s3_bucket.ap.arn}/*",
        ]
      },
    ]
  })
}

# CRR: US -> EU
resource "aws_s3_bucket_replication_configuration" "us_to_others" {
  provider = aws.us
  bucket   = aws_s3_bucket.us.id
  role     = aws_iam_role.s3_replication.arn

  depends_on = [
    aws_s3_bucket_versioning.us,
    aws_s3_bucket_versioning.eu,
    aws_s3_bucket_versioning.ap,
  ]

  rule {
    id     = "replicate-to-eu"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.eu.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  rule {
    id       = "replicate-to-ap"
    status   = "Enabled"
    priority = 1

    destination {
      bucket        = aws_s3_bucket.ap.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# CRR: EU -> US, AP
resource "aws_s3_bucket_replication_configuration" "eu_to_others" {
  provider = aws.eu
  bucket   = aws_s3_bucket.eu.id
  role     = aws_iam_role.s3_replication.arn

  depends_on = [
    aws_s3_bucket_versioning.us,
    aws_s3_bucket_versioning.eu,
    aws_s3_bucket_versioning.ap,
  ]

  rule {
    id     = "replicate-to-us"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.us.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  rule {
    id       = "replicate-to-ap"
    status   = "Enabled"
    priority = 1

    destination {
      bucket        = aws_s3_bucket.ap.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# CRR: AP -> US, EU
resource "aws_s3_bucket_replication_configuration" "ap_to_others" {
  provider = aws.ap
  bucket   = aws_s3_bucket.ap.id
  role     = aws_iam_role.s3_replication.arn

  depends_on = [
    aws_s3_bucket_versioning.us,
    aws_s3_bucket_versioning.eu,
    aws_s3_bucket_versioning.ap,
  ]

  rule {
    id     = "replicate-to-us"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.us.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  rule {
    id       = "replicate-to-eu"
    status   = "Enabled"
    priority = 1

    destination {
      bucket        = aws_s3_bucket.eu.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}
