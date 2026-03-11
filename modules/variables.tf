variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (stage | prod)"
  type        = string

  validation {
    condition     = contains(["stage", "prod"], var.environment)
    error_message = "environment must be 'stage' or 'prod'."
  }
}

variable "function_name" {
  description = "Base name of the Lambda function (environment suffix is appended automatically)"
  type        = string
  default     = "static-html-lambda"
}

variable "auth_type" {
  description = "Lambda Function URL auth type. NONE = public, AWS_IAM = private."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "AWS_IAM"], var.auth_type)
    error_message = "auth_type must be either NONE or AWS_IAM."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 128
}

variable "tags" {
  description = "Base tags applied to all resources (Environment tag is added automatically)"
  type        = map(string)
  default     = {}
}
