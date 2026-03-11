# terragrunt/prod/lambda/terragrunt.hcl

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true   # gives access to include.root.locals.*
}

terraform {
  source = "${get_repo_root()}//modules"
}

inputs = {
  environment   = include.root.locals.environment   # auto-derived as "prod"
  aws_region    = include.root.locals.aws_region
  function_name = include.root.locals.function_name

  # Prod: public URL, higher resources, longer timeout
  auth_type      = "NONE"
  lambda_timeout = 30
  lambda_memory  = 256

  tags = merge(include.root.locals.common_tags, {
    CostCenter = "engineering"
    Owner      = "platform-team"
    Critical   = "true"
  })
}
