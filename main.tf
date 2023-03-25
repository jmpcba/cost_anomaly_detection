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
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
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
