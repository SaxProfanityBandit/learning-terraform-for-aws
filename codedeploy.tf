resource "aws_codedeploy_app" "FlaskDeploy" {
  compute_platform = "ECS"
  name             = "FlaskDeploy"
}

resource "aws_sns_topic" "FlaskAlerts" {
  name = "FlaskAlerts"
}

resource "aws_codedeploy_deployment_group" "FlaskDeployGroup" {
  app_name              = aws_codedeploy_app.FlaskDeploy.name
  deployment_group_name = "FlaskDeployGroup"
  service_role_arn      = aws_iam_role.FlaskDev_Role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "FlaskDev-Instance"
    }

    ec2_tag_filter {
      key   = "Enviroment"
      type  = "KEY_AND_VALUE"
      value = "Development"
    }
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "FlaskDeploymentFail"
    trigger_target_arn = aws_sns_topic.FlaskAlerts.arn
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["FlaskDevAlarm"]
    enabled = true
  }
}