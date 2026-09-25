terraform {
  backend "s3" {
    bucket = "nagoyameshi-tfstate-gau-2026"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-1"
  }
}