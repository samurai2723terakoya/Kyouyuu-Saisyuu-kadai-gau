# --- 1. SNSトピック（名前固定：nagoyameshi-prod-sns-topic） ---
resource "aws_sns_topic" "alerts" {
  name = "nagoyameshi-prod-sns-topic"
}

# ★ 通知を受け取るメールアドレス
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "4444.goalkeeper@gmail.com" # 自身のメールアドレス
}

# --- 2. CloudWatch Logs エラーログ監視設定 ---
# ログから「ERROR」や「Exception」というキーワードを数えるフィルター
resource "aws_cloudwatch_log_metric_filter" "ecs_error" {
  name           = "nagoyameshi-prod-ecs-error-filter"
  pattern        = "?ERROR ?Exception ?error ?Exception" # Laravelのエラーキーワードを検知
  log_group_name = aws_cloudwatch_log_group.ecs.name     # /ecs/nagoyameshi-prod を自動参照

  metric_transformation {
    name      = "ProdECSErrorCount"
    namespace = "CustomLogMetrics"
    value     = "1"
  }
}

# 上記のログフィルターが1回でもカウントしたらSNS通知するアラーム
resource "aws_cloudwatch_metric_alarm" "log_error_alarm" {
  alarm_name          = "nagoyameshi-prod-ecs-log-error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.ecs_error.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.ecs_error.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1 # 1回でもエラーログが出たらアラーム
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# --- 3. 標準インフラアラーム設定 ---

# ECS CPU 監視
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "nagoyameshi-prod-ecs-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.prod.name
    ServiceName = aws_ecs_service.app.name
  }
}

# ALB 5xx エラー監視
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "nagoyameshi-prod-alb-http-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.prod.arn_suffix
  }
}

# RDS 容量不足監視
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "nagoyameshi-prod-rds-low-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5GB
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.identifier
  }
}
