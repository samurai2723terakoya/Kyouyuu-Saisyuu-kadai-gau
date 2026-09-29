resource "aws_db_subnet_group" "dev" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier        = "${var.project_name}-${var.environment}-mysql"
  allocated_storage = var.db_allocated_storage # ★ レビューシート対応：変数化
  storage_type      = var.db_storage_type      # ★ レビューシート対応：変数化
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class # ★ レビューシート対応：変数化

  backup_retention_period = 7

  db_name  = var.db_name
  username = var.db_username
  # ★ var.db_password から書き換え
  password = local.secrets["db_password"]
  # パスワード書き換え
  db_subnet_group_name   = aws_db_subnet_group.dev.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = var.db_multi_az # ★ レビューシート対応：変数化
  skip_final_snapshot    = true
  publicly_accessible    = false

  # ★ ここを追加：メンテナンス時間を待たずに、今すぐ設定を反映する
  apply_immediately = true
  # gp3変更用一時追加項目
  tags = {
    Name = "${var.project_name}-${var.environment}-mysql"
  }
}

resource "aws_ecs_cluster" "dev" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "/ecs/${var.project_name}-${var.environment}"
  }
}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu    # ★ レビューシート対応：変数化
  memory                   = var.ecs_task_memory # ★ レビューシート対応：変数化
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "laravel"
      image     = "${aws_ecr_repository.laravel.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "APP_NAME"
          value = "Laravel"
        },
        {
          name  = "APP_ENV"
          value = var.app_env
        },
        {
          name  = "APP_KEY"
          value = local.secrets["app_key"] # ★ var.app_key から書き換え
        },
        {
          name  = "APP_DEBUG"
          value = var.app_debug
        },
        {
          name  = "APP_URL"
          value = var.app_url
        },
        {
          name  = "DB_CONNECTION"
          value = "mysql"
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.mysql.address
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_DATABASE"
          value = var.db_name
        },
        {
          name  = "DB_USERNAME"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = local.secrets["db_password"] # ★ var.db_password から書き換え
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-task"
  }
}

resource "aws_ecs_task_definition" "migration" {
  family                   = "${var.project_name}-${var.environment}-migration-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu    # ★ レビューシート対応：変数化
  memory                   = var.ecs_task_memory # ★ レビューシート対応：変数化
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "laravel"
      image     = "${aws_ecr_repository.laravel.repository_url}:latest"
      essential = true

      command = ["sh", "-c", "cd /var/www/html/laravel-nagoyameshi && php artisan migrate --force"]

      environment = [
        {
          name  = "APP_NAME"
          value = "Laravel"
        },
        {
          name  = "APP_ENV"
          value = var.app_env
        },
        {
          name  = "APP_KEY"
          value = local.secrets["app_key"] # ★ var.app_key から書き換え
        },
        {
          name  = "APP_DEBUG"
          value = var.app_debug
        },
        {
          name  = "APP_URL"
          value = var.app_url
        },
        {
          name  = "DB_CONNECTION"
          value = "mysql"
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.mysql.address
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_DATABASE"
          value = var.db_name
        },
        {
          name  = "DB_USERNAME"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = local.secrets["db_password"] # ★ var.db_password から書き換え
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs-migration"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-migration-task"
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.dev.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_c.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "laravel"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.https]

  tags = {
    Name = "${var.project_name}-${var.environment}-service"
  }

  # ★ ここから追加：開発環境でもタスク定義の勝手な巻き戻しを無視する
  lifecycle {
    ignore_changes = [task_definition]
  }
  # 
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.dev.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}