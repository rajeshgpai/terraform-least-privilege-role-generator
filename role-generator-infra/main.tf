provider "aws" {
    region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "trail" {
  name                          = "tf-role-generator-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  s3_key_prefix                 = ""
  include_global_service_events = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail_log_role.arn
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket_prefix = "tf-role-generator-trail-"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
    bucket = aws_s3_bucket.trail_bucket.id
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.trail_bucket.id}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.trail_bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "trail_logs" {
    name = "tf-role-generator"
}

resource "aws_iam_role" "trail_log_role" {
    name = "tf-role-generator-trail-logger-role"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY    
}

resource "aws_iam_role_policy" "trail_log_policy" {
    name = "tf-role-generator-trail-logger-policy"
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream"
            ],
            "Resource": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.trail_logs.name}:*",
            "Effect": "Allow"
        }
    ]
}
POLICY
    role = aws_iam_role.trail_log_role.id
}