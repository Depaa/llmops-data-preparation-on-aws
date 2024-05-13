resource "aws_sqs_queue" "jobs_queue" {
  name = "${var.prefix}-jobs-queue"
}

resource "aws_sns_topic" "jobs_notification" {
  name = "${var.prefix}-jobs-notification"
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
