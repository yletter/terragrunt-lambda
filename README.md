# lambda-static-html — Multi-Environment Setup

Two independent environments (**stage** and **prod**) managed via Terragrunt's DRY pattern. A single shared `root.hcl` holds common config; each environment folder supplies only its own overrides.

---

## Project structure

```
.
├── lambda/
│   └── index.js                          # Lambda handler (reads ENVIRONMENT env var)
│
├── terraform/                            # Reusable Terraform module
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── terragrunt/
    ├── root.hcl                          # Shared: region, remote state, common tags
    ├── stage/
    │   └── lambda/
    │       └── terragrunt.hcl            # Stage overrides (128 MB, 10s timeout)
    └── prod/
        └── lambda/
            └── terragrunt.hcl            # Prod overrides  (256 MB, 30s timeout)
```

---

## Environment differences

| Setting          | stage               | prod                |
|------------------|---------------------|---------------------|
| Function name    | `static-html-lambda-stage` | `static-html-lambda-prod` |
| Memory           | 128 MB              | 256 MB              |
| Timeout          | 10 s                | 30 s                |
| `ENVIRONMENT` var| `stage`             | `prod`              |
| Page accent color| Blue (`#00b4d8`)    | Red (`#e94560`)     |
| Extra tags       | —                   | `Critical = true`   |

All resources are automatically tagged with `Environment = stage|prod` inside the Terraform module via `locals.merged_tags`.

---

## Prerequisites

| Tool       | Version  |
|------------|----------|
| Terraform  | ≥ 1.3    |
| Terragrunt | ≥ 0.50   |
| AWS CLI    | any      |

```bash
aws configure    # or export AWS_PROFILE / AWS_ACCESS_KEY_ID
```

---

## Deploy a single environment

```bash
# Stage
cd terragrunt/stage/lambda
terragrunt init
terragrunt plan
terragrunt apply

# Prod
cd terragrunt/prod/lambda
terragrunt init
terragrunt plan
terragrunt apply
```

## Deploy all environments at once (from terragrunt root)

```bash
cd terragrunt
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

> `run-all` walks every child directory that contains a `terragrunt.hcl` and applies them in dependency order.

---

## Outputs (per environment)

```
Outputs:
environment   = "stage"
function_name = "static-html-lambda-stage"
function_url  = "https://<id>.lambda-url.us-east-1.on.aws/"
function_arn  = "arn:aws:lambda:us-east-1:123456789:function:static-html-lambda-stage"
```

---

## Remote State

Uncomment the `remote_state` block in `terragrunt/root.hcl` and fill in your S3 bucket + DynamoDB table. Terragrunt will automatically namespace state by environment:

```
s3://my-bucket/stage/static-html-lambda/terraform.tfstate
s3://my-bucket/prod/static-html-lambda/terraform.tfstate
```

---

## Tear down

```bash
# Single env
cd terragrunt/stage/lambda && terragrunt destroy

# All envs
cd terragrunt && terragrunt run-all destroy
```
