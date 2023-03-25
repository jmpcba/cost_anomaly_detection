variable "threshold_type" {
  description = "especify if the alert with trigger based on a total amount or a percentage"
  type        = string

  validation {
    condition     = contains(["AMOUNT", "PERCENT"], var.threshold_type)
    error_message = "threshold_type must be AMOUNT or PERCENT"
  }
}
variable "cost_threshold" {
  description = "Defines the value to trigger an alert"
  type        = number
}

variable "alert_type" {
  description = "type of alert, email or slack message"
  type        = string
  default     = "SLACK"
  validation {
    condition     = contains(["EMAIL", "SLACK"], var.alert_type)
    error_message = "alert_type must be EMAIL or SLACK"
  }
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "subscription_email" {
  description = "This is the email address that gets notified when an anomaly is detected."
  type        = string
  default     = ""
}

variable "slack_channel_id" {
  description = "right click on the channel name, select copy channel URL, and use the letters and number after the last /"
  type        = string
  default     = ""
}

variable "slack_workspace_id" {
  description = "ID of your slack slack_workspace_id"
  type        = string
  default     = ""
}

variable "enable_slack_integration" {
  description = "If false, the module will create an SNS topic without an slack channel integration. Use it when another subscriber to the SNS topic is preffered"
  type        = bool
  default     = true
}