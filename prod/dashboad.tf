resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "nagoyameshi-prod-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # --- 行1: CloudFront & WAF セキュリティ・パフォーマンス ---
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "Region", "Global", "DistributionId", aws_cloudfront_distribution.prod.id],
            ["AWS/CloudFront", "TotalErrorRate", "Region", "Global", "DistributionId", aws_cloudfront_distribution.prod.id],
            ["AWS/CloudFront", "CacheHitRate", "Region", "Global", "DistributionId", aws_cloudfront_distribution.prod.id, { "stat" = "Average" }]
          ]
          period  = 300
          stat    = "Sum"
          region  = "us-east-1" # CloudFrontメトリクスはus-east-1固定
          title   = "CloudFront Traffic & Cache Performance"
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/WAFv2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.cloudfront.name, "Region", "Global", "Rule", "ALL"],
            ["AWS/WAFv2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.cloudfront.name, "Region", "Global", "Rule", "ALL"],
            ["AWS/WAFv2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.cloudfront.name, "Region", "Global", "Rule", "${var.project_name}-${var.environment}-allow-japan-only"]
          ]
          period  = 300
          stat    = "Sum"
          region  = "us-east-1" # グローバルWAF(CloudFront用)はus-east-1固定
          title   = "AWS WAFv2 Blocked vs Allowed Requests"
          view    = "timeSeries"
          stacked = false
        }
      },

      # --- 行2: ECS & ALB コンピューティング・トラフィック ---
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.app.name, "ClusterName", aws_ecs_cluster.prod.name],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", aws_ecs_service.app.name, "ClusterName", aws_ecs_cluster.prod.name]
          ]
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "ECS Service CPU & Memory Utilization"
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.prod.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.prod.arn_suffix, { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.app.arn_suffix, "LoadBalancer", aws_lb.prod.arn_suffix, { "stat" = "Average" }]
          ]
          period  = 60
          stat    = "Sum"
          region  = var.aws_region
          title   = "ALB Traffic & Target Health"
          view    = "timeSeries"
          stacked = false
        }
      },

      # --- 行3: RDS データベースパフォーマンス ---
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mysql.identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.mysql.identifier, { "stat" = "Average" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.mysql.identifier, { "stat" = "Average", "yAxis" = "right" }]
          ]
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "RDS (MySQL) Performance"
          view    = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}
