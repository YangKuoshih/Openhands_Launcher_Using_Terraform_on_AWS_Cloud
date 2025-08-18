# EventBridge rule to start EC2 at 8 AM EST
resource "aws_cloudwatch_event_rule" "start_ec2" {
  name                = "${local.config.project.id}-start-ec2"
  description         = "Start EC2 instance at 8 AM EST"
  schedule_expression = local.config.schedule.start_time

  tags = local.common_tags
}

# EventBridge rule to stop EC2 at 10 PM EST
resource "aws_cloudwatch_event_rule" "stop_ec2" {
  name                = "${local.config.project.id}-stop-ec2"
  description         = "Stop EC2 instance at 10 PM EST"
  schedule_expression = local.config.schedule.stop_time

  tags = local.common_tags
}

# EventBridge target for start rule
resource "aws_cloudwatch_event_target" "start_ec2" {
  rule      = aws_cloudwatch_event_rule.start_ec2.name
  target_id = "StartEC2Target"
  arn       = aws_lambda_function.start_ec2.arn
}

# EventBridge target for stop rule
resource "aws_cloudwatch_event_target" "stop_ec2" {
  rule      = aws_cloudwatch_event_rule.stop_ec2.name
  target_id = "StopEC2Target"
  arn       = aws_lambda_function.stop_ec2.arn
}

# Lambda permissions for EventBridge
resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_ec2.arn
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2.arn
}