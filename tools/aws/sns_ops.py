# assumes credentials are in ~/.aws/credentials
import boto3
import argparse
import sqs_ops
from robot.api import logger

def log(message):
    if __name__ == '__main__':
        logger.console(message)
    else:
        logger.info(message)
        
def list_topics(params={}):
    sns_client = boto3.client('sns', region_name='us-west-2')
    response = sns_client.list_topics()
    logger.console('Response of listing topics ' + str(response))
    return response

def find_arn(params):
    topic_arns = []
    if params['topic'] != False:
        response = list_topics()   
        for topic in response['Topics']:
            if topic['TopicArn'].find(params['topic']) > -1:
                topic_arns.append(topic['TopicArn'])
    return topic_arns

def delete_subscription(params):
    response = 'not completed'
    topic_arns = find_arn(params)
    sqs_params = {'name':params['sqs_queue_name']}
    sqs_queue = sqs_ops.get_attributes(sqs_params)
    sns_client = boto3.client('sns', region_name='us-west-2')
    subscription_response = sns_client.list_subscriptions()
    subscription_arns = []
    if len(subscription_response['Subscriptions'])==0:
        response = 'no subscriptions present'
    for subscription in subscription_response['Subscriptions']:
        if subscription['Endpoint']==sqs_queue['Attributes']['QueueArn'] and subscription['TopicArn']==topic_arns[0]:
            subscription_arns.append(subscription['SubscriptionArn'])
    if len(subscription_arns)>0:
        response = sns_client.unsubscribe(SubscriptionArn=subscription_arns[0])
    else:
        response = 'subscription not found'
    return response

def subscribe_sqs_queue_to_topic(params):
    response = 'not completed'
    topic_arns = find_arn(params)
    sqs_params = {'name':params['sqs_queue_name']}
    queue_exists = sqs_ops.check_queue_exists({'queue_exists':True},params['sqs_queue_name'])
    if len(topic_arns)>0 and queue_exists != False:
        sqs_queue = sqs_ops. get_attributes(sqs_params)
        sns_client = boto3.client('sns', region_name='us-west-2')
        response = sns_client.subscribe(TopicArn=topic_arns[0],Protocol='sqs',Endpoint=sqs_queue['Attributes']['QueueArn'],ReturnSubscriptionArn=True)
    else:
        response = 'queue or topic not found'
    return response

if __name__ == '__main__':
    '''

    parser = argparse.ArgumentParser(description='Perform specified operation on an SQS queue or SNS topic')
    parser.add_argument('-q', dest='sqs_queue_name', required=False, help='undef', default='aws-test-url')
    parser.add_argument('-t', dest='sns_topic', required=False, default='undef', help='SNS topic name')
    parser.add_argument('-f', dest='sns_message_file',required=False, default=None, help='file containing message to publish on SNS')
    parser.add_argument('-m', dest='sns_message_content',required=False, default=None, help='message to publish on SNS if file not specified')
    parser.add_argument('-c', dest='command',required=False, default='add', help='command to perform on SNS topic or SQS queue')
    
    args = parser.parse_args()
    log(args)
    sns_commands = {'list_topics':{'topic_not_required':True},'find_arn':{'queue_not_required':True},'subscribe_sqs_queue_to_topic':{},'delete_subscription':{}}
    if args.command not in sns_commands.keys():
        log(args.command + ' is not a valid command. Use one of the following:')
        for p in sns_commands.keys(): logger.console(p)
    elif ('topic_not_required' not in sns_commands[args.command] and args.sns_topic=='undef') or ('queue_not_required' not in sns_commands[args.command] and args.sqs_queue_name=='undef'):
        response = 'Topic and/or queue name required for command '+args.command
    else:
        params = {'topic':args.sns_topic,'sqs_queue_name':args.sqs_queue_name}
        response = locals()[args.command](params)
    log(response)
    '''
