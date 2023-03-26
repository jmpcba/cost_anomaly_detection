module "cost_anomaly_detector" {
  source             = "../"
  cost_threshold     = 1
  threshold_type     = "PERCENT"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  tags = {
    key = "value"
  }
}