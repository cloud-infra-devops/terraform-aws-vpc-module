# ─── CLOUDWATCH ALARMS FOR VPC ──────────────────────────────────────────────
# AWS does not publish VPC-level metrics to CloudWatch natively.
# The alarms below cover the observable VPC-adjacent metrics:
#   • NAT Gateway: ErrorPortAllocation, PacketsDropCount, BytesOutToDestination
#   • VPC Flow Logs delivery errors (when flow logs are enabled)
#   • Internet Gateway: no native CW metrics — covered via NAT GW egress

# ── NAT Gateway alarms (one set per NAT GW) ─────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "nat_error_port_allocation" {
  count               = local.nat_count
  alarm_name          = "${var.name}-nat-${count.index + 1}-ErrorPortAllocation"
  alarm_description   = "NAT Gateway port allocation errors — indicates SNAT exhaustion"
  namespace           = "AWS/NATGateway"
  metric_name         = "ErrorPortAllocation"
  dimensions          = { NatGatewayId = aws_nat_gateway.this[count.index].id }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}-ErrorPortAllocation" })
}

resource "aws_cloudwatch_metric_alarm" "nat_packets_drop" {
  count               = local.nat_count
  alarm_name          = "${var.name}-nat-${count.index + 1}-PacketsDropCount"
  alarm_description   = "NAT Gateway dropped packets"
  namespace           = "AWS/NATGateway"
  metric_name         = "PacketsDropCount"
  dimensions          = { NatGatewayId = aws_nat_gateway.this[count.index].id }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 100
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}-PacketsDropCount" })
}

resource "aws_cloudwatch_metric_alarm" "nat_connection_attempt_count" {
  count               = local.nat_count
  alarm_name          = "${var.name}-nat-${count.index + 1}-ConnectionAttemptCount-High"
  alarm_description   = "Unusually high NAT Gateway connection attempts"
  namespace           = "AWS/NATGateway"
  metric_name         = "ConnectionAttemptCount"
  dimensions          = { NatGatewayId = aws_nat_gateway.this[count.index].id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 3
  threshold           = 100000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}-ConnectionAttemptCount-High" })
}

resource "aws_cloudwatch_metric_alarm" "nat_connection_established_count" {
  count               = local.nat_count
  alarm_name          = "${var.name}-nat-${count.index + 1}-ConnectionEstablishedCount-Low"
  alarm_description   = "NAT Gateway established connections dropped to zero — possible outage"
  namespace           = "AWS/NATGateway"
  metric_name         = "ConnectionEstablishedCount"
  dimensions          = { NatGatewayId = aws_nat_gateway.this[count.index].id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}-ConnectionEstablishedCount-Low" })
}

resource "aws_cloudwatch_metric_alarm" "nat_bytes_out_to_destination" {
  count               = local.nat_count
  alarm_name          = "${var.name}-nat-${count.index + 1}-BytesOutToDestination-High"
  alarm_description   = "High outbound bytes through NAT Gateway — possible data exfiltration or runaway process"
  namespace           = "AWS/NATGateway"
  metric_name         = "BytesOutToDestination"
  dimensions          = { NatGatewayId = aws_nat_gateway.this[count.index].id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 3
  threshold           = 10737418240 # 10 GB per 5-min window
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}-BytesOutToDestination-High" })
}

resource "aws_cloudwatch_metric_alarm" "nat_bytes_in_from_destination" {
  count               = local.nat_count
  alarm_name          = "${var.name}-nat-${count.index + 1}-BytesInFromDestination-High"
  alarm_description   = "High inbound bytes through NAT Gateway"
  namespace           = "AWS/NATGateway"
  metric_name         = "BytesInFromDestination"
  dimensions          = { NatGatewayId = aws_nat_gateway.this[count.index].id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 3
  threshold           = 10737418240 # 10 GB per 5-min window
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}-BytesInFromDestination-High" })
}

# ── VPC Flow Logs delivery error alarm ──────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "flow_log_delivery_error" {
  count               = var.enable_flow_logs ? 1 : 0
  alarm_name          = "${var.name}-FlowLog-DeliveryError"
  alarm_description   = "VPC Flow Log records failed to deliver to CloudWatch Logs"
  namespace           = "AWS/Logs"
  metric_name         = "DeliveryErrors"
  dimensions          = { LogGroupName = aws_cloudwatch_log_group.flow_logs[0].name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-FlowLog-DeliveryError" })
}

resource "aws_cloudwatch_metric_alarm" "flow_log_throttle" {
  count               = var.enable_flow_logs ? 1 : 0
  alarm_name          = "${var.name}-FlowLog-ThrottledEvents"
  alarm_description   = "VPC Flow Log events are being throttled"
  namespace           = "AWS/Logs"
  metric_name         = "ThrottledEvents"
  dimensions          = { LogGroupName = aws_cloudwatch_log_group.flow_logs[0].name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions
  tags                = merge(local.common_tags, { Name = "${var.name}-FlowLog-ThrottledEvents" })
}
