# terragrunt/stage/lambda/terragrunt.hcl

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true   # gives access to include.root.locals.*
}

terraform {
  source = "${get_repo_root()}//modules"
}

inputs = {
  environment   = include.root.locals.environment
  aws_region    = include.root.locals.aws_region
  function_name = include.root.locals.function_name

  # Stage: public URL, lower resources, shorter timeout
  auth_type      = "NONE"
  lambda_timeout = 10
  lambda_memory  = 128

  tags = merge(include.root.locals.common_tags, {
    CostCenter = "engineering"
    Owner      = "platform-team"
  })
}
