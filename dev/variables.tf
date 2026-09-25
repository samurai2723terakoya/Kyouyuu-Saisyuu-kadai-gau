variable "aws_region" {
  type        = string
  description = "Main AWS region for production infrastructure"
}

variable "acm_region" {
  type        = string
  description = "ACM region for CloudFront certificates only"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "domain_name" {
  type        = string
  description = "Primary domain name for production"
}

variable "hosted_zone_name" {
  type        = string
  description = "Route53 hosted zone name"
}

variable "my_ip" {
  type        = string
  description = "Your global IP address with CIDR for SSH access"
}

variable "github_owner" {
  type        = string
  description = "GitHub owner name"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch name for production deployment"
}

variable "github_oauth_token" {
  type        = string
  description = "GitHub OAuth token"
  sensitive   = true
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for production VPC"
}

variable "public_subnet_a_cidr" {
  type        = string
  description = "CIDR block for public subnet in ap-northeast-1a"
}

variable "public_subnet_c_cidr" {
  type        = string
  description = "CIDR block for public subnet in ap-northeast-1c"
}

variable "private_subnet_a_cidr" {
  type        = string
  description = "CIDR block for private subnet in ap-northeast-1a"
}

variable "private_subnet_c_cidr" {
  type        = string
  description = "CIDR block for private subnet in ap-northeast-1c"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "bastion_key_name" {
  type        = string
  description = "AWS key pair name for bastion EC2"
}

variable "bastion_instance_type" {
  type        = string
  description = "Instance type for bastion EC2"
}

variable "app_key" {
  type        = string
  description = "Laravel application key"
  sensitive   = true
}

variable "app_env" {
  type        = string
  description = "Laravel application environment"
}

variable "app_debug" {
  type        = string
  description = "Laravel debug mode"
}

variable "app_url" {
  type        = string
  description = "Laravel application URL"
}

variable "alb_domain_name" {
  type        = string
  description = "Domain name used for ALB origin access from CloudFront"
}