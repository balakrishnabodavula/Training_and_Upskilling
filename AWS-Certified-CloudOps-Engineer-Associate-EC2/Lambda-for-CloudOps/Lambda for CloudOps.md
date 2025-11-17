Lambda for CloudOps
Lab 1: Basic Lambda Function
Create Lambda Function
# Create Lambda function
aws lambda create-function \
  --function-name cloudops-automation \
  --runtime python3.9 \
  --role arn:aws:iam::123456789012:role/lambda-execution-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip \
  --description "CloudOps automation function"

# Invoke function
aws lambda invoke \
  --function-name cloudops-automation \
  --payload '{"action":"stop_instances","tag":"Environment=Dev"}' \
  response.json

# Update function code
aws lambda update-function-code \
  --function-name cloudops-automation \
  --zip-file fileb://updated-function.zip
Lambda Function Code
# lambda_function.py
import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    action = event.get('action', 'list_instances')
    tag_filter = event.get('tag', 'Environment=Dev')
    
    if action == 'stop_instances':
        # Stop instances with specific tag
        response = ec2.describe_instances(
            Filters=[
                {'Name': f'tag:{tag_filter.split("=")[0]}', 'Values': [tag_filter.split("=")[1]]},
                {'Name': 'instance-state-name', 'Values': ['running']}
            ]
        )
        
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            ec2.stop_instances(InstanceIds=instance_ids)
            return {
                'statusCode': 200,
                'body': json.dumps(f'Stopped instances: {instance_ids}')
            }
    
    elif action == 'start_instances':
        # Start instances with specific tag
        response = ec2.describe_instances(
            Filters=[
                {'Name': f'tag:{tag_filter.split("=")[0]}', 'Values': [tag_filter.split("=")[1]]},
                {'Name': 'instance-state-name', 'Values': ['stopped']}
            ]
        )
        
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            ec2.start_instances(InstanceIds=instance_ids)
            return {
                'statusCode': 200,
                'body': json.dumps(f'Started instances: {instance_ids}')
            }
    
    return {
        'statusCode': 200,
        'body': json.dumps('No action performed')
    }
Terraform Lambda Configuration
# lambda.tf
resource "aws_lambda_function" "cloudops_automation" {
  filename         = "function.zip"
  function_name    = "cloudops-automation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  
  environment {
    variables = {
      ENVIRONMENT = "production"
    }
  }
  
  tags = {
    Name = "CloudOps Automation"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "cloudops-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "cloudops-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
Lab 2: Scheduled Lambda Functions
Create EventBridge Rule
# Create EventBridge rule for daily execution
aws events put-rule \
  --name daily-instance-stop \
  --schedule-expression "cron(0 18 * * ? *)" \
  --description "Stop development instances daily at 6 PM"

# Add Lambda target
aws events put-targets \
  --rule daily-instance-stop \
  --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:123456789012:function:cloudops-automation"

# Add permission for EventBridge to invoke Lambda
aws lambda add-permission \
  --function-name cloudops-automation \
  --statement-id allow-eventbridge \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:us-east-1:123456789012:rule/daily-instance-stop
Terraform Scheduled Lambda
# scheduled-lambda.tf
resource "aws_cloudwatch_event_rule" "daily_stop" {
  name                = "daily-instance-stop"
  description         = "Stop development instances daily"
  schedule_expression = "cron(0 18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_stop.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.cloudops_automation.arn
  
  input = jsonencode({
    action = "stop_instances"
    tag    = "Environment=Dev"
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudops_automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_stop.arn
}
Lab 3: Lambda with SNS Integration
SNS-triggered Lambda
# sns_lambda.py
import json
import boto3

def lambda_handler(event, context):
    sns = boto3.client('sns')
    ec2 = boto3.client('ec2')
    
    # Parse SNS message
    for record in event['Records']:
        message = json.loads(record['Sns']['Message'])
        
        if message['AlarmName'] == 'High-CPU-Usage':
            # Get instance ID from alarm
            instance_id = message['Trigger']['Dimensions'][0]['value']
            
            # Stop the instance
            ec2.stop_instances(InstanceIds=[instance_id])
            
            # Send notification
            sns.publish(
                TopicArn='arn:aws:sns:us-east-1:123456789012:cloudops-alerts',
                Message=f'Instance {instance_id} stopped due to high CPU usage',
                Subject='CloudOps Alert: Instance Stopped'
            )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Alert processed successfully')
    }
Terraform SNS Integration
# sns-lambda.tf
resource "aws_sns_topic" "cloudops_alerts" {
  name = "cloudops-alerts"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.cloudops_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_processor.arn
}

resource "aws_lambda_function" "sns_processor" {
  filename      = "sns_function.zip"
  function_name = "cloudops-sns-processor"
  role         = aws_iam_role.lambda_role.arn
  handler      = "sns_lambda.lambda_handler"
  runtime      = "python3.9"
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudops_alerts.arn
}
Lab 4: Lambda Layers
Create Lambda Layer
# Create layer directory structure
mkdir -p layer/python/lib/python3.9/site-packages

# Install dependencies
pip install requests -t layer/python/lib/python3.9/site-packages/

# Create layer zip
cd layer && zip -r ../cloudops-layer.zip .

# Publish layer
aws lambda publish-layer-version \
  --layer-name cloudops-common-layer \
  --description "Common utilities for CloudOps functions" \
  --zip-file fileb://cloudops-layer.zip \
  --compatible-runtimes python3.9
Terraform Layer Configuration
# lambda-layer.tf
resource "aws_lambda_layer_version" "cloudops_layer" {
  filename   = "cloudops-layer.zip"
  layer_name = "cloudops-common-layer"
  
  compatible_runtimes = ["python3.9"]
  description         = "Common utilities for CloudOps functions"
}

resource "aws_lambda_function" "function_with_layer" {
  filename      = "function.zip"
  function_name = "cloudops-with-layer"
  role         = aws_iam_role.lambda_role.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.9"
  
  layers = [aws_lambda_layer_version.cloudops_layer.arn]
}
Lab 5: Lambda Error Handling
Error Handling Function
# error_handling.py
import json
import boto3
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        ec2 = boto3.client('ec2')
        
        # Validate input
        if 'instance_id' not in event:
            raise ValueError("Missing required parameter: instance_id")
        
        instance_id = event['instance_id']
        action = event.get('action', 'describe')
        
        if action == 'stop':
            response = ec2.stop_instances(InstanceIds=[instance_id])
            logger.info(f"Successfully stopped instance: {instance_id}")
            
        elif action == 'start':
            response = ec2.start_instances(InstanceIds=[instance_id])
            logger.info(f"Successfully started instance: {instance_id}")
            
        else:
            response = ec2.describe_instances(InstanceIds=[instance_id])
            
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Action {action} completed successfully',
                'instance_id': instance_id
            })
        }
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        logger.error(f"AWS API Error: {error_code} - {error_message}")
        
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': error_code,
                'message': error_message
            })
        }
        
    except ValueError as e:
        logger.error(f"Validation Error: {str(e)}")
        
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'ValidationError',
                'message': str(e)
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected Error: {str(e)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'InternalError',
                'message': 'An unexpected error occurred'
            })
        }
Lab 6: Lambda Monitoring
CloudWatch Metrics and Alarms
# Create custom metric
aws cloudwatch put-metric-data \
  --namespace "CloudOps/Lambda" \
  --metric-data MetricName=ProcessedInstances,Value=5,Unit=Count

# Create alarm for Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name "Lambda-High-Errors" \
  --alarm-description "High error rate in Lambda function" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=cloudops-automation \
  --evaluation-periods 2
Terraform Monitoring
# lambda-monitoring.tf
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "Lambda-High-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High error rate in Lambda function"
  
  dimensions = {
    FunctionName = aws_lambda_function.cloudops_automation.function_name
  }
  
  alarm_actions = [aws_sns_topic.cloudops_alerts.arn]
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.cloudops_automation.function_name}"
  retention_in_days = 14
}
Best Practices
Use environment variables for configuration
Implement proper error handling
Set appropriate timeouts
Use Lambda layers for common code
Monitor function performance
Implement least privilege IAM policies
Use dead letter queues for failed executions
Troubleshooting
# View function logs
aws logs describe-log-streams \
  --log-group-name /aws/lambda/cloudops-automation

# Get function configuration
aws lambda get-function-configuration \
  --function-name cloudops-automation

# List function versions
aws lambda list-versions-by-function \
  --function-name cloudops-automation
Cleanup
# Delete function
aws lambda delete-function \
  --function-name cloudops-automation

# Delete layer
aws lambda delete-layer-version \
  --layer-name cloudops-common-layer \
  --version-number 1