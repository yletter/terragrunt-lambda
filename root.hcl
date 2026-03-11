# terragrunt/root.hcl
#
# Shared configuration inherited by all child terragrunt.hcl files.
# Children load this via: find_in_parent_folders("root.hcl")

locals {
  # Derive the environment name from the directory two levels up from the child
  # e.g.  terragrunt/stage/lambda  →  "stage"
  #        terragrunt/prod/lambda   →  "prod"
  env_path    = split("/", path_relative_to_include())
  environment = local.env_path[1]   # "stage" or "prod"

  aws_region    = "us-east-1"
  function_name = "static-html-lambda"

  common_tags = {
    Project   = "lambda-static-html"
    ManagedBy = "terragrunt"
    # Environment tag is merged inside the Terraform module automatically
  }
}

# ─── Remote State (S3 + DynamoDB locking) ────────────────────────────────────
# Fill in your bucket / table names and uncomment to enable.
#
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terragrunt-to-terralith-tfstate-2025-03-03-1006"
    key            = "${local.environment}/${local.function_name}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# ─── Provider generation (optional convenience) ──────────────────────────────
generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
    }
  EOF
}
