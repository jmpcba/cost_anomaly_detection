locals {
  threshold_expression_key = var.threshold_type == "AMOUNT" ? "ANOMALY_TOTAL_IMPACT_ABSOLUTE" : "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
  subscriber_type          = var.alert_type == "SLACK" ? "SNS" : "EMAIL"
  subscriber_address       = var.alert_type == "SLACK" ? aws_sns_topic.cost_anomaly_topic.arn : var.subscription_email
}