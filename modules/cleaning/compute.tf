/*
* Start Extracting Job Lambda and permissions
* Lambda gets triggered by S3
*/
module "start_cleaning_job_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.prefix}-start-cleaning-job"
  description   = "Starts PII cleaning ETL job"
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  source_path = [
    {
      path             = "${path.cwd}/src/functions/start-cleaning-job",
      npm_requirements = true,
      commands = [
        "npm install --production",
        ":zip"
      ],
    }
  ]
  environment_variables = tomap({
    BRONZE_BUCKET_NAME         = var.bronze_bucket_name
    SILVER_BUCKET_NAME         = var.silver_bucket_name
    GOLD_BUCKET_NAME           = var.gold_bucket_name
    PII_REDACTION_ETL_JOB_NAME = aws_glue_job.glue_etl_job.name
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
      ],
      resources = [
        "*"
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
    },
    glue_jon = {
      effect = "Allow",
      actions = [
        "glue:StartJobRun"
      ],
      resources = [
        aws_glue_job.glue_etl_job.arn
      ]
    }
  }
}

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.start_cleaning_job_lambda_function.lambda_function_arn
  principal     = "s3.amazonaws.com"

  source_arn = "arn:aws:s3:::${var.silver_bucket_name}"
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = var.silver_bucket_name

  lambda_function {
    lambda_function_arn = module.start_cleaning_job_lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }
}
