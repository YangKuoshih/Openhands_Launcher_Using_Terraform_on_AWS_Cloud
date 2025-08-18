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
