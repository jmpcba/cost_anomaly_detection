resource "aws_sns_topic" "cost_anomaly_topic" {
  name = "CostAnomalyUpdates"
  tags = var.tags
}

data "aws_iam_policy_document" "sns_topic_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "AWSAnomalyDetectionSNSPublishingPermissions"

    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.cost_anomaly_topic.arn,
    ]
  }

  statement {
    sid = "__default_statement_ID"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.cost_anomaly_topic.arn,
    ]
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.cost_anomaly_topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy_document.json
}

resource "aws_ce_anomaly_monitor" "anomaly_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  tags              = var.tags
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription" {
  name = "RealtimeAnomalySubscription"
  threshold_expression {
    dimension {
      key           = local.threshold_expression_key
      values        = [var.cost_threshold]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.anomaly_monitor.arn,
  ]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly_topic.arn
  }

  depends_on = [
    aws_sns_topic_policy.sns_topic_policy,
  ]
  tags = var.tags
}


resource "awscc_chatbot_slack_channel_configuration" "chatbot_slack_channel" {
  count              = var.enable_slack_integration ? 1 : 0
  configuration_name = "cost-anomaly-alerts"
  iam_role_arn       = aws_iam_role.cost_anomaly_chatbot_role[0].arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  guardrail_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess", ]
  sns_topic_arns     = [aws_sns_topic.cost_anomaly_topic.arn, ]
}

resource "aws_iam_role" "cost_anomaly_chatbot_role" {
  count = var.enable_slack_integration ? 1 : 0
  name  = "cost-anomaly-chatbot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "slack_chatbot_policy" {
  count = var.enable_slack_integration ? 1 : 0
  name  = "AWS-Chatbot-NotificationsOnly-Policy"
  role  = aws_iam_role.cost_anomaly_chatbot_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}