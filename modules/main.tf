terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
data "aws_caller_identity" "current" {}

# ─── Zip the Lambda source ───────────────────────────────────────────────────

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda_${var.environment}.zip"
}

# ─── IAM Role for Lambda ──────────────────────────────────────────────────────

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-${var.environment}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ─── Lambda Function ──────────────────────────────────────────────────────────

resource "aws_lambda_function" "main" {
  function_name    = "${var.function_name}-${var.environment}"
  description      = "Serves static HTML — ${var.environment} environment"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_role.arn

  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout       = var.lambda_timeout
  memory_size      = var.lambda_memory
  # Inject environment name into the runtime
  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = local.merged_tags

}

# ─── Merge base tags with environment tag ────────────────────────────────────

locals {
  merged_tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_lambda_function_url" "main" {
  function_name      = aws_lambda_function.main.function_name
  authorization_type = "NONE"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_basic_execution" {
  name        = "${var.function_name}-${var.environment}-lambda-basic-execution"
  description = "Policy for Lambda basic execution (CloudWatch logs)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}