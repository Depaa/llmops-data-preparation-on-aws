resource "aws_sqs_queue" "jobs_queue" {
  name = "${var.prefix}-jobs-queue"
}

resource "aws_sns_topic" "jobs_notification" {
  name = "${var.prefix}-jobs-notification"
}

resource "aws_sqs_queue_policy" "jobs_queue_policy" {
  queue_url = aws_sqs_queue.jobs_queue.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.jobs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.jobs_notification.arn}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_sns_topic_subscription" "jobs_sqs_target" {
  protocol  = "sqs"
  topic_arn = aws_sns_topic.jobs_notification.arn
  endpoint  = aws_sqs_queue.jobs_queue.arn
}

// SSM parameters for the jobs queue
resource "aws_ssm_parameter" "jobs_queue_name" {
  name  = "/${var.prefix}/extracting/jobs-queue-name"
  type  = "String"
  value = aws_sqs_queue.jobs_queue.name
}
resource "aws_ssm_parameter" "jobs_queue_url" {
  name  = "/${var.prefix}/extracting/jobs-queue-id"
  type  = "String"
  value = aws_sqs_queue.jobs_queue.id
}
