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
