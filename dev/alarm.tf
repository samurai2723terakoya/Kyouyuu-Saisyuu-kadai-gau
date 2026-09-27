# --- 1. SNSトピック（名前固定：nagoyameshi-dev-sns-topic） ---
resource "aws_sns_topic" "alerts" {
  name = "nagoyameshi-dev-sns-topic"
}

# ★ 通知を受け取るメールアドレス
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "4444.goalkeeper@gmail.com" # 自身のメールアドレス
}

# --- 2. CloudWatch Logs エラーログ監視設定 ---
resource "aws_cloudwatch_log_metric_filter" "ecs_error" {
  name           = "nagoyameshi-dev-ecs-error-filter"
  pattern        = "?ERROR ?Exception ?error ?Exception"
  log_group_name = aws_cloudwatch_log_group.ecs.name    # /ecs/nagoyameshi-dev を自動参照

  metric_transformation {
    name      = "DevECSErrorCount"
    namespace = "CustomLogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_error_alarm" {
  alarm_name          = "nagoyameshi-dev-ecs-log-error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.ecs_error.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.ecs_error.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# --- 3. 標準インフラアラーム設定 ---

# ECS CPU 監視
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "nagoyameshi-dev-ecs-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 90 # 検証環境は少し高めの90%
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.dev.name
    ServiceName = aws_ecs_service.app.name
  }
}

# ALB 5xx エラー監視
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "nagoyameshi-dev-alb-http-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5 # 検証環境は5回以上で通知
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.dev.arn_suffix
  }
}

# RDS 容量不足監視
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "nagoyameshi-dev-rds-low-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2GB
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.identifier
  }
}
