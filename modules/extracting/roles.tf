resource "aws_iam_role" "textract_role" {
  name               = "${var.prefix}-textract-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "textract.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "textract_policy" {
  name        = "${var.prefix}-textract-policy"
  description = "Policy for Textract to send notifications to SNS and write to S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${var.silver_bucket_name}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${var.bronze_bucket_name}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "textract_attachment" {
  role       = aws_iam_role.textract_role.name
  policy_arn = aws_iam_policy.textract_policy.arn
}
