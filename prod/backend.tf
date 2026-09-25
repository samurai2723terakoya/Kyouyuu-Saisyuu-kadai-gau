terraform {
  backend "s3" {
    bucket = "nagoyameshi-tfstate-gau-2026"
    key    = "prod/terraform.tfstate"
    region = "ap-northeast-1"
  }
}