output "aws_lambda_function_url" {
  description = "Public URL to invoke the Lambda function"
  value       = aws_lambda_function_url.main.function_url
}

output "function_name" {
  description = "Lambda function name (includes environment suffix)"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.main.arn
}

output "environment" {
  description = "Deployed environment"
  value       = var.environment
}
