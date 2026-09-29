resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_admin" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_admin" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket_prefix = "${var.project_name}-${var.environment}-pipeline-artifacts-"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-pipeline-artifacts"
  }
}

resource "aws_codebuild_project" "app" {
  name          = "${var.project_name}-${var.environment}-build"
  build_timeout = 20
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.laravel.repository_url
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "laravel"
    }

    environment_variable {
      name  = "MIGRATION_TASK_DEFINITION"
      value = aws_ecs_task_definition.migration.family
    }

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = aws_ecs_cluster.dev.name
    }

    environment_variable {
      name  = "SUBNET_ID_1"
      value = aws_subnet.private_a.id
    }

    environment_variable {
      name  = "SUBNET_ID_2"
      value = aws_subnet.private_c.id
    }

    environment_variable {
      name  = "SECURITY_GROUP_ID"
      value = aws_security_group.ecs.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-build"
  }
}

resource "aws_codepipeline" "app" {
  name     = "${var.project_name}-${var.environment}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = var.github_branch
        OAuthToken           = local.secrets["github_oauth_token"] # ★ var.github_oauth_token から書き換え
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build_App"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy_ECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.dev.name
        ServiceName = aws_ecs_service.app.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pipeline"
  }
}