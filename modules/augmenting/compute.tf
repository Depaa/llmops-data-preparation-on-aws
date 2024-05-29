/*
* Start Augmenting Job Lambda and permissions
* Lambda gets triggered by S3 gold bucket
*/
module "start_augmenting_job_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.prefix}-start-augmenting-job"
  description   = "Starts augmenting job"
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  source_path = [
    {
      path             = "${path.cwd}/src/functions/start-augmenting-job",
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
    METADATA_DATABASE_NAME = var.metadata_database_name
  })

  logging_log_format            = "JSON"
  logging_system_log_level      = "INFO"
  logging_application_log_level = var.is_debug_on == true ? "DEBUG" : "INFO"
  timeout                       = 28
  memory_size                   = 512

  attach_policy_statements = true
  policy_statements = {
    comprehend = {
      effect = "Allow",
      actions = [
        "comprehend:ClassifyDocument",
      ],
      resources = [
        "*"
      ]
    },
    s3_gold = {
      effect = "Allow",
      actions = [
        "s3:GetObject",
      ],
      resources = [
        "arn:aws:s3:::${var.gold_bucket_name}/*"
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

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.start_augmenting_job_lambda_function.lambda_function_arn
  principal     = "s3.amazonaws.com"

  source_arn = "arn:aws:s3:::${var.gold_bucket_name}"
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = var.gold_bucket_name

  lambda_function {
    lambda_function_arn = module.start_augmenting_job_lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}
