data "aws_caller_identity" "current" {
  provider = aws.us
}

# --- IAM Role for Redpanda Brokers (S3 + MRAP access) ---

resource "aws_iam_role" "redpanda_broker" {
  name = "${var.deployment_prefix}-redpanda-broker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "redpanda_s3" {
  name = "${var.deployment_prefix}-redpanda-s3"
  role = aws_iam_role.redpanda_broker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
        ]
        Resource = [
          aws_s3_bucket.us.arn,
          "${aws_s3_bucket.us.arn}/*",
          aws_s3_bucket.eu.arn,
          "${aws_s3_bucket.eu.arn}/*",
          aws_s3_bucket.ap.arn,
          "${aws_s3_bucket.ap.arn}/*",
        ]
      },
      {
        Sid    = "MRAPAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:GetAccessPoint",
          "s3:GetAccessPointForObjectLambda",
        ]
        Resource = [
          "arn:aws:s3::${data.aws_caller_identity.current.account_id}:accesspoint/*",
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "redpanda_broker" {
  name = "${var.deployment_prefix}-redpanda-broker"
  role = aws_iam_role.redpanda_broker.name
}
