/*
* Start Extracting Job Lambda and permissions
* Lambda gets triggered by S3
*/
module "start_extracting_job_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.prefix}-start-extracting-job"
  description   = "Starts textract job"
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  source_path = [
    {
      path             = "${path.cwd}/src/functions/start-extracting-job",
      npm_requirements = true,
      commands = [
        "npm install --production",
        ":zip"
      ],
    }
  ]
  environment_variables = tomap({
    BRONZE_BUCKET_NAME     = var.bronze_bucket_name
    SILVER_BUCKET_NAME     = var.silver_bucket_name
    GOLD_BUCKET_NAME       = var.gold_bucket_name
    NOTIFICATION_TOPIC_ARN = aws_sns_topic.jobs_notification.arn
    NOTIFICATION_ROLE_ARN  = aws_iam_role.textract_role.arn
  })

  logging_log_format            = "JSON"
  logging_system_log_level      = "INFO"
  logging_application_log_level = var.is_debug_on == true ? "DEBUG" : "INFO"
  timeout                       = 28
  memory_size                   = 512

  attach_policy_statements = true
  policy_statements = {
    textract = {
      effect = "Allow",
      actions = [
        "textract:StartDocumentTextDetection",
        # "textract:StartDocumentAnalysis"
      ],
      resources = [
        "*"
      ]
    },
    s3 = {
      effect = "Allow",
      actions = [
        "s3:GetObject"
      ],
      resources = [
        "arn:aws:s3:::${var.bronze_bucket_name}/*"
      ]
    },
    s3_silver = {
      effect = "Allow",
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ],
      resources = [
        "arn:aws:s3:::${var.silver_bucket_name}/*"
      ]
    }
  }
}

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.start_extracting_job_lambda_function.lambda_function_arn
  principal     = "s3.amazonaws.com"

  source_arn = "arn:aws:s3:::${var.bronze_bucket_name}"
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = var.bronze_bucket_name

  lambda_function {
    lambda_function_arn = module.start_extracting_job_lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
    filter_suffix       = ".pdf"
  }
}

/*
* Process Extracting Job Lambda and permissions
* Lambda gets triggered by SQS
*/
module "process_extracting_job_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.prefix}-process-extracting-job"
  description   = "Process textract job"
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  source_path = [
    {
      path             = "${path.cwd}/src/functions/process-extracting-job",
      npm_requirements = true,
      commands = [
        "npm install --production",
        ":zip"
      ],
    }
  ]

  environment_variables = tomap({
    BRONZE_BUCKET_NAME     = var.bronze_bucket_name
    SILVER_BUCKET_NAME     = var.silver_bucket_name
    GOLD_BUCKET_NAME       = var.gold_bucket_name
    NOTIFICATION_TOPIC_ARN = aws_sns_topic.jobs_notification.arn
    NOTIFICATION_ROLE_ARN  = aws_iam_role.textract_role.arn
    METADATA_DATABASE_NAME = var.metadata_database_name
  })

  logging_log_format            = "JSON"
  logging_system_log_level      = "INFO"
  logging_application_log_level = var.is_debug_on == true ? "DEBUG" : "INFO"
  timeout                       = 28
  memory_size                   = 512

  attach_policy = true
  policy        = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"

  attach_policy_statements = true
  policy_statements = {
    textract = {
      effect = "Allow",
      actions = [
        "textract:GetDocumentTextDetection",
        # "textract:GetDocumentAnalysis"
      ],
      resources = [
        "*"
      ]
    },
    s3 = {
      effect = "Allow",
      actions = [
        "s3:PutObject"
      ],
      resources = [
        "arn:aws:s3:::${var.silver_bucket_name}/*"
      ]
    },
    sqs = {
      effect = "Allow",
      actions = [
        "sqs:ReceiveMessage"
      ],
      resources = [
        aws_sqs_queue.jobs_queue.arn
      ]
    },
    dynamodb = {
      effect = "Allow",
      actions = [
        "dynamodb:PutItem"
      ],
      resources = [
        "${var.metadata_database_arn}",
        "${var.metadata_database_arn}/*"
      ]
    }
  }
}

resource "aws_lambda_permission" "sqs_trigger_permission" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = module.process_extracting_job_lambda_function.lambda_function_arn
  principal     = "sqs.amazonaws.com"

  source_arn = aws_sqs_queue.jobs_queue.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger_mapping" {
  event_source_arn = aws_sqs_queue.jobs_queue.arn
  function_name    = module.process_extracting_job_lambda_function.lambda_function_arn
  batch_size       = 1
}
