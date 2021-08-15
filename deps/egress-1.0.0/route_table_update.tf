resource "aws_sns_topic" "autoscaling_notification" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress_autoscaling"

  tags = merge(var.standard_tags_no_name, { Name: "${var.app_name}-${data.aws_region.current.name}-egress_autoscaling"})
}

data "archive_file" "autoscaling_notification_handler" {
  type = "zip"
  source_file = "${path.module}/autoscaling_notification.py"
  output_path = "${path.module}/autoscaling_notification.zip"
}

resource "aws_lambda_function" "autoscaling_notification_handler" {
  function_name = "egress_autoscaling_notification"
  filename = data.archive_file.autoscaling_notification_handler.output_path
  handler = "autoscaling_notification.lambda_handler"
  role = aws_iam_role.autoscaling_notification_handler.arn
  reserved_concurrent_executions = 1
  source_code_hash = data.archive_file.autoscaling_notification_handler.output_base64sha256
  runtime = "python3.8"
  timeout = 30

  environment {
    variables = {
      VPC_ID = var.vpc_id
      AUTOSCALING_GROUP_NAME = aws_autoscaling_group.ecs_instances.name
    }
  }

  lifecycle {
    ignore_changes = [
      last_modified
    ]
  }
}

resource "aws_cloudwatch_event_target" "autoscaling_notification_handler_lambda" {
  target_id = "egress-autoscaling-notification-handler-lambda"
  rule = aws_cloudwatch_event_rule.autoscaling_notification_handler_lambda.name
  arn = aws_lambda_function.autoscaling_notification_handler.arn
}

resource "aws_cloudwatch_event_rule" "autoscaling_notification_handler_lambda" {
  name = "egress-autoscaling-notification-handler-lambda"
  description = "fires every minute"
  schedule_expression = "rate(1 minute)"

  tags = merge(var.standard_tags_no_name, { Name: "egress-autoscaling-notification-handler-lambda"})
}

resource "aws_lambda_permission" "autoscaling_notification_handler" {
  depends_on = [aws_lambda_function.autoscaling_notification_handler]

  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autoscaling_notification_handler.function_name
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.autoscaling_notification.arn
}

resource "aws_lambda_permission" "autoscaling_notification_cloudwatch_permission" {
  depends_on = [aws_lambda_function.autoscaling_notification_handler]

  statement_id = "AllowExecutionFromCloudwatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autoscaling_notification_handler.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.autoscaling_notification_handler_lambda.arn
}

resource "aws_sns_topic_subscription" "autoscaling_notification_handler" {
  depends_on = [aws_lambda_permission.autoscaling_notification_handler]

  topic_arn = aws_sns_topic.autoscaling_notification.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.autoscaling_notification_handler.arn
}

data "aws_iam_policy_document" "autoscaling_notification_handler_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "autoscaling_notification_handler" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress_autoscaling-notification-handler"
  description = "For autoscaling notification handling Lambda"
  assume_role_policy = data.aws_iam_policy_document.autoscaling_notification_handler_assume_role.json
  inline_policy {}
  managed_policy_arns = [aws_iam_policy.autoscaling_notification_handler.arn]

  tags = merge(var.standard_tags_no_name, { Name: "egress-autoscaling-notification-handler"})
}


resource "aws_iam_policy" "autoscaling_notification_handler" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress_autoscaling-notification-handler"
  policy = data.aws_iam_policy_document.autoscaling_notification_handler_policy.json
}

data "aws_iam_policy_document" "autoscaling_notification_handler_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:CompleteLifecycleAction",
      "ec2:DescribeInstances",
      "ec2:DescribeSubnets",
      "ec2:DescribeRouteTables",
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
    ]
    resources = ["*"]
  }
}

resource "aws_autoscaling_lifecycle_hook" "cluster_asg_lifecycle_hook_launching" {
  autoscaling_group_name = aws_autoscaling_group.ecs_instances.name
  name = "egress_launching"
  default_result = "CONTINUE"
  heartbeat_timeout = 60
  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_target_arn = aws_sns_topic.autoscaling_notification.arn
  role_arn = aws_iam_role.lifecycle.arn
//  notification_metadata =
}


resource "aws_autoscaling_lifecycle_hook" "cluster_asg_lifecycle_hook_terminating" {
  autoscaling_group_name = aws_autoscaling_group.ecs_instances.name
  name = "egress_terminating"
  default_result = "CONTINUE"
  heartbeat_timeout = 60
  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = aws_sns_topic.autoscaling_notification.arn
  role_arn = aws_iam_role.lifecycle.arn
  //  notification_metadata =
}

resource "aws_iam_role" "lifecycle" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress-lifecycle"
  assume_role_policy = data.aws_iam_policy_document.lifecycle.json
}

data "aws_iam_policy_document" "lifecycle" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lifecycle_policy" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress-lifecycle-role-policy"
  role = aws_iam_role.lifecycle.id
  policy = data.aws_iam_policy_document.lifecycle_policy.json
}

data "aws_iam_policy_document" "lifecycle_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
      "autoscaling:CompleteLifecycleAction",
    ]
    resources = [
      aws_sns_topic.autoscaling_notification.arn
    ]
  }
}

