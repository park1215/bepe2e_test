# assumes credentials are in ~/.aws/credentials
import boto3
import argparse
import policies
import sns_ops
import json, random
from robot.api import logger


def log(message):
    if __name__ == '__main__':
        logger.console(message)
    else:
        logger.info(message)

def list(params={}): 
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    response = sqs_client.list_queues()
    return response

def create(params):
    name = params['name']
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    log('Creating queue '+name)
    response = sqs_client.create_queue(QueueName=name)
    return response

def delete(params):
    name = params['name']
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    log('Deleting queue '+name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.delete_queue(QueueUrl=sqs_url)   
    return response

def get_attributes(params):
    name = params['name']
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.get_queue_attributes(QueueUrl=sqs_url,AttributeNames=['All'])   
    return response

def purge(params):
    name = params['name']
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    log('Purging queue '+name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.purge_queue(QueueUrl=sqs_url) 
    return response

def read(params):
    name = params['name']
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    log('Receiving from queue '+name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url,MaxNumberOfMessages=5,WaitTimeSeconds=20)
    return response

def read_and_delete(params):
    name = params['name']
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    log('Receiving from queue '+name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url,AttributeNames=['All'],MaxNumberOfMessages=5,WaitTimeSeconds=20)
    for message in response['Messages']:
        sqs_client.delete_message(QueueUrl=sqs_url,ReceiptHandle=message['ReceiptHandle'])
    return response

def add_sns_read_policy(params):
    name = params['name']
    # there may be multiple topic ARNs that reference the same topic name, but assume not, just use the first for now
    # if no topic specified (=False), that's okay
    topics = []
    if params['topic'] != False:
        topics = sns_ops.find_arn(params)
    else:
        topics.append(False)

    sqs_client = boto3.client('sqs', region_name='us-west-2')
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    queue_attributes = sqs_client.get_queue_attributes(QueueUrl=sqs_url,AttributeNames=['QueueArn'])
    sqs_policy = policies.sqs_create_sns_policy(queue_attributes['Attributes']['QueueArn'],topics[0])
    policy_response = sqs_client.set_queue_attributes(QueueUrl=sqs_url,Attributes={'Policy':json.dumps(sqs_policy)})
    return policy_response

def check_queue_exists(cmd_attrs,name):
    # for most operations it is essential that the queue already exists (eg 'delete') or essential that it does not exist (eg 'create')
    response = True
    if 'queue_exists' in cmd_attrs.keys():
        sqs_client = boto3.client('sqs', region_name='us-west-2')
        try:
            sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
            response = True if cmd_attrs['queue_exists']==True else False
        except:
            response = True if cmd_attrs['queue_exists']==False else False            
    return response

if __name__ == '__main__':
    response = 'command not attempted'

    # this needs to move to a common location for callers
    sqs_commands = {'create':{'queue_exists':False},'read':{'queue_exists':True},'list':{'name_not_required':True},'delete':{'queue_exists':True},'purge':{'queue_exists':True}, \
                    'read_and_delete':{'queue_exists':True},'get_attributes':{'queue_exists':True},'add_sns_read_policy':{'queue_exists':True}}

    parser = argparse.ArgumentParser(description='Perform specified operation on an SQS queue')
    parser.add_argument('-n', dest='sqs_queue_name', required=False, default='undef', help='SQS queue name')
    parser.add_argument('-c', dest='command',required=False, default='list', help='command to perform on SQS queue')
    parser.add_argument('-t', dest='sns_topic',required=False, default=False, help='topic to name in read policy, if not present all topics permitted')
    
    args = parser.parse_args()
    log('inputs = '+ str(args))

    if args.command not in sqs_commands.keys():
        log(args.command + ' is not a valid command. Use one of the following:')
        for p in sqs_commands.keys(): logger.console(p)
    elif 'name_not_required' not in sqs_commands[args.command] and args.sqs_queue_name=='undef':
        response = 'Queue name required for command '+args.command
    else:
        if check_queue_exists(sqs_commands[args.command],args.sqs_queue_name):
            params = {'name':args.sqs_queue_name,'topic':args.sns_topic}
            response = locals()[args.command](params)
        else:
            response = 'Queue already exists' if sqs_commands[args.command]['queue_exists']==False else 'Queue does not exist'
    log(response)


