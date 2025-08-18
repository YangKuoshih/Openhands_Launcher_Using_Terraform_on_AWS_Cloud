# Lambda function to start EC2
resource "aws_lambda_function" "start_ec2" {
  filename         = "start_ec2.zip"
  function_name    = "${local.config.project.id}-start-ec2"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      INSTANCE_ID = aws_instance.openhands.id
    }
  }

  tags = local.common_tags

  depends_on = [data.archive_file.start_lambda_zip]
}

# Lambda function to stop EC2
resource "aws_lambda_function" "stop_ec2" {
  filename         = "stop_ec2.zip"
  function_name    = "${local.config.project.id}-stop-ec2"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      INSTANCE_ID = aws_instance.openhands.id
    }
  }

  tags = local.common_tags

  depends_on = [data.archive_file.stop_lambda_zip]
}

# Lambda code for starting EC2
resource "local_file" "start_lambda_code" {
  content = <<EOF
import boto3
import os

def handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']
    
    try:
        response = ec2.start_instances(InstanceIds=[instance_id])
        return {
            'statusCode': 200,
            'body': f'Started instance {instance_id}'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error starting instance: {str(e)}'
        }
EOF
  filename = "${path.module}/start_lambda.py"
}

# Lambda code for stopping EC2
resource "local_file" "stop_lambda_code" {
  content = <<EOF
import boto3
import os

def handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']
    
    try:
        response = ec2.stop_instances(InstanceIds=[instance_id])
        return {
            'statusCode': 200,
            'body': f'Stopped instance {instance_id}'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error stopping instance: {str(e)}'
        }
EOF
  filename = "${path.module}/stop_lambda.py"
}

# Create ZIP files for Lambda functions
data "archive_file" "start_lambda_zip" {
  type        = "zip"
  source_file = local_file.start_lambda_code.filename
  output_path = "${path.module}/start_ec2.zip"
  depends_on  = [local_file.start_lambda_code]
}

data "archive_file" "stop_lambda_zip" {
  type        = "zip"
  source_file = local_file.stop_lambda_code.filename
  output_path = "${path.module}/stop_ec2.zip"
  depends_on  = [local_file.stop_lambda_code]
}