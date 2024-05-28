resource "aws_iam_role" "glue_service_role" {
  name = "${var.prefix}-glue-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "glue_policy" {
  name        = "${var.prefix}-glue-s3-access-policy"
  description = "Policy for Glue job to access S3 buckets SILVER and GOLD"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.silver_bucket_name}",
        "arn:aws:s3:::${var.silver_bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::${var.gold_bucket_name}",
        "arn:aws:s3:::${var.gold_bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:BatchGetCustomEntityTypes"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "glue_attach_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

# Upload the script to S3
resource "aws_s3_object" "glue_script" {
  bucket = var.silver_bucket_name
  key    = "scripts/PII_redaction.py"
  source = "${path.module}/scripts/PII_redaction.py"
  etag   = filemd5("${path.module}/scripts/PII_redaction.py")
}

resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "/aws-glue/${var.prefix}-cleaning-job"
  retention_in_days = 30
}

resource "aws_glue_job" "glue_etl_job" {
  name     = "${var.prefix}-cleaning-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.silver_bucket_name}/scripts/PII_redaction.py"
    python_version  = "3"
  }

  default_arguments = merge(
    {
      "--job-language"                     = "python"
      "--TempDir"                          = "s3://${var.silver_bucket_name}/temporary/"
      "--enable-metrics"                   = ""
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-continuous-log-filter"     = "true"
      "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_log_group.name
    },
    var.default_arguments
  )

  max_retries       = 0
  timeout           = var.timeout
  glue_version      = var.glue_version
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type


}
