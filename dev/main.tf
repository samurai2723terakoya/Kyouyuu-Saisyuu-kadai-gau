terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "my-project"
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = var.acm_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "my-project"
    }
  }
}

# --- 追加：開発環境用Secrets Managerからシークレット情報を取得 ---
data "aws_secretsmanager_secret" "dev_secrets" {
  name = "nagoyameshi-dev-secrets"
}

data "aws_secretsmanager_secret_version" "dev_secrets_latest" {
  secret_id = data.aws_secretsmanager_secret.dev_secrets.id
}

locals {
  secrets = jsondecode(data.aws_secretsmanager_secret_version.dev_secrets_latest.secret_string)
}
