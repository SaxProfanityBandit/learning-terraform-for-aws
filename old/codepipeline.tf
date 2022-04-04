resource "aws_codecommit_repository" "FlaskAssignment" {
  repository_name = "FlaskAssignment"
  description     = "This is a repo for the current school assignment.de"
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy-role.name
}

resource "aws_codedeploy_app" "flask-dev" {
  name = "flask-dev"
}

resource "aws_sns_topic" "flask-warnings" {
  name = "flask-warnings"
}

resource "aws_codedeploy_deployment_group" "FlaskDevGroup" {
  app_name              = aws_codedeploy_app.flask-dev.name
  deployment_group_name = "FlaskDevGroup"
  service_role_arn      = aws_iam_role.codedeploy-role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "CodeDeploy"
    }

    ec2_tag_filter {
      key   = "Enviroment"
      type  = "KEY_AND_VALUE"
      value = "Development"
    }
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "flask-trigger"
    trigger_target_arn = aws_sns_topic.flask-warnings.arn
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }
}

resource "aws_codebuild_project" "flask_project" {
  name          = "flask_project"
  description   = "flask_project"
  build_timeout = "30"
  service_role  = aws_iam_role.codedeploy-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = "0.12.16"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec_terraform_plan.yml"
  }

  tags = {
    Terraform = "true"
  }
}

resource "aws_codepipeline" "flask-pipeline" {
  name     = "flask-pipeline"
  role_arn = aws_iam_role.codedeploy-role.arn

  artifact_store {
    location = aws_s3_bucket.flask-artifacts.bucket
    type     = "S3"

    encryption_key {
      id   = CodeDeployKey
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        FullRepositoryId = "FlaskAssignment"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "test"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ActionMode     = "REPLACE_ON_FAILURE"
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = "MyStack"
        TemplatePath   = "build_output::sam-templated.yaml"
      }
    }
  }
}
