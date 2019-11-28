# assumes credentials are in ~/.aws/credentials
import boto3, re
import argparse
#import sns_ops
import json, random
from robot.api import logger

################# Generalized Queue Functions ###########
def createQueueAndSubscribe(name_prefix, topicArn):
    name = name_prefix + str(random.randint(1, 999999))
    create_queue_status, name = createQueue(name)
    if create_queue_status:
        attribute_status, sqs_queue = getQueueAttributes(name)
        if attribute_status:
            policy_status, response = addSnsReadPolicy(name, topicArn)
            if policy_status:
                subscribe_status, response = subscribeSqsQueueToTopic(sqs_queue, topicArn)
                if subscribe_status:
                    subscriptionArn = response['SubscriptionArn']
                    return True, name, subscriptionArn
                else:
                    return False, "Failed while subscribing to topic", None
            else:
                return False, "Failed while adding sns read policies", None
        else:
            return False, "Failed getting queue attributes", None
    else:
        return False, "Failed creating the queue", None

def checkQueueExists(name):
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    # logger.console('################  line # 84 #########################')
    logger.console('queue name is')
    logger.console(name)
    try:
        sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
        logger.console('Queue Exists ' + str(sqs_url))
        respone = True
    except Exception as e:
        # logger.console('################  line # 91 #########################')
        logger.console('Exception while checking queue exists ' + str(e))
        respone = False
    finally:
        # logger.console('################  line # 95 #########################')
        logger.console('Response of check if queue exists ' + str(respone))
        return respone

def createQueue(name):
    try:
        sqs_client = boto3.client('sqs', region_name='us-west-2')
        logger.console('Creating queue ' + name)
        response = sqs_client.create_queue(QueueName=name)
        logger.console('Response of creating queue ' + str(response))
        return True, name
    except Exception as e:
        logger.console('Exception while creating a queue ' + str(e))
        return False, "Failed while creating sqs queue"


def getTotalSubscriptionCount():
    sns_client = boto3.client('sns', region_name='us-west-2')
    response = sns_client.list_subscriptions()
    try:
        totalSubscriptions = len(response['Subscriptions'])
        return True, totalSubscriptions
    except Exception as e:
        return False, e

def listAndDeleteAllSubscriptions():
    sns_client = boto3.client('sns', region_name='us-west-2')
    response = sns_client.list_subscriptions()
    logger.info(response)
    try:
        totalSubscriptions = len(response['Subscriptions'])
        logger.info("total Subscriptions are:" + str(totalSubscriptions))
        for subscription in response['Subscriptions']:
            subscriptionArn = subscription['SubscriptionArn']
            unsubscribeResponse = sns_client.unsubscribe(SubscriptionArn=subscriptionArn)
        return True, response
    except Exception as e:
        return False, e


def deleteSubscription(subscriptionArn):
    sns_client = boto3.client('sns', region_name='us-west-2')
    try:
        unsubscribeResponse = sns_client.unsubscribe(SubscriptionArn=subscriptionArn)
        return True, unsubscribeResponse
    except Exception as e:
        return False, e

def deleteQueue(name):
    try:
        sqs_client = boto3.client('sqs', region_name='us-west-2')
        logger.console('Deleting queue ' + name)
        sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
        response = sqs_client.delete_queue(QueueUrl=sqs_url)
        return True, response
    except Exception as e:
        # logger.console('################  line # 91 #########################')
        logger.console('Exception while checking queue exists ' + str(e))
        return False, str(e)

def getQueueAttributes(name):
    try:
        sqs_client = boto3.client('sqs', region_name='us-west-2')
        sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
        response = sqs_client.get_queue_attributes(QueueUrl=sqs_url, AttributeNames=['All'])
        logger.console('Response of get queue attributes ' + str(response))
        return True, response
    except Exception as e:
        logger.console('Exception while getting a queue attributes' + str(e))
        return False, "Failed while getting sqs queue attributes"

def subscribeSqsQueueToTopic(sqs_queue, topic_arn):
    try:
        sns_client = boto3.client('sns', region_name='us-west-2')
        # logger.console('################  line # 59 #########################')
        response = sns_client.subscribe(TopicArn=topic_arn, Protocol='sqs',
                                        Endpoint=sqs_queue['Attributes']['QueueArn'], ReturnSubscriptionArn=True)
        # logger.console('################  line # 61 #########################')
        logger.console('Response of Subscribing to topic ' + str(response))
        # logger.console('################  line # 63 #########################')
        logger.info("subscription message response")
        logger.info(response)
        return True, response
    except Exception as e:
        logger.console('Exception while subscribing to topic ' + str(e))
        logger.console('################  line # 67 #########################')
        return False, "Failed while subscribing sqs queue to topic"


def read(name):
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Receiving from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, MaxNumberOfMessages=10, WaitTimeSeconds=20)
    logger.console('Response of reading queue ' + str(response))
    return response


############## PSM Queue Functions ##############
def readAndLogAndDeleteMessagePSM(name):
    status, sqs_queue = getQueueAttributes(name)
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    try:
        all_messages = response['Messages']
    except KeyError:
        logger.info('No messages on the queue!')
        all_messages = []
        return True, "No more messages in the queue", '', '', all_messages

    for message in all_messages:
        logger.info('################  line # 125 #########################')
        MessageId = message['MessageId']
        logger.info('MessageId is:')
        logger.info(MessageId)
        body = message['Body']
        data = json.loads(body)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        logger.info('event is:')
        logger.info(event)
        eventPID = event['eventData']['productInstance']['productInstanceId']
        logger.info('################  line # 136 #########################')
        logger.info('########## productInstanceId from event is ###################### ')
        logger.info(eventPID)
        oldState = event['eventData']['oldState']
        newState = event['eventData']['newState']
        logger.info('old and new states are ' + str(oldState) + '   ' + str(newState))
        #sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])

def readAndDeleteMessagePSMForGivenState(name, oldState, newstate, pidMapping, *argv):
    logger.info("input is:")
    logger.info(argv)
    logger.info(oldState)
    logger.info(newstate)
    logger.info("argv="+str(argv))

    status, sqs_queue = getQueueAttributes(name)
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    try:
        all_messages = response['Messages']
    except KeyError:
        logger.info('No messages on the queue!')
        return True, pidMapping, "No more messages in the queue"
    for message in all_messages:
        #logger.info('################  line # 73 #########################')
        #logger.info('################  line # 132 #########################')
        MessageId = message['MessageId']
        logger.info('MessageId is:')
        logger.info(MessageId)
        body = message['Body']
        data = json.loads(body)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        logger.info('event is:')
        logger.info(event)
        eventPID = event['eventData']['productInstance']['productInstanceId']
        logger.info('########## productInstanceId from event is###################### ')
        logger.info(eventPID)
        if eventPID in argv:
            logger.info('found a match of event for given product instance id' + str(eventPID))
            characteristics = event['eventData']['productInstance']['characteristics']

            if event['eventData']['newState'] == newstate and event['eventData']['oldState'] == oldState:
                #logger.info('################  line # 506 #########################')
                pidMapping[eventPID] = [event['eventData']['oldState']]
                #logger.info('################  line # 507 #########################')
                logger.info(pidMapping)
                pidMapping[eventPID].append(event['eventData']['newState'])
                #logger.info('################  line # 511 #########################')
                #logger.info(pidMapping)

                if len(event['eventData']['productInstance']['prices'])>0:
                    spbPrice_Category = event['eventData']['productInstance']['prices'][0]['characteristics'][0]['value']
                    pidMapping[eventPID].append(spbPrice_Category)
                else:
                    logger.info("fulfillment!")
                    pidMapping[eventPID].append(0)
                #logger.info('################  line # 515 #########################')
                #logger.info(pidMapping)
                pidMapping[eventPID].append('')
                pidMapping[eventPID].append('')
                pidMapping[eventPID].append('')
                pidMapping[eventPID].append('')

                productKind = event['eventData']['productInstance']['kind']
                pidMapping[eventPID][5] = productKind
                #logger.info('################  line # 518 #########################')
                for characteristic in characteristics:
                    try:
                        #logger.info("char name in loops is:")
                        #logger.info(characteristic['name'])
                        if characteristic['name'] == 'PSM_PRODUCT_KIND':
                            #logger.info('################  line # 523 #########################')
                            #logger.info("detail char is:")
                            #logger.info(characteristic)
                            #logger.info('################  line # 529 #########################')
                            psmProductKind = characteristic['value']
                            #logger.info('################  line # 531 #########################')
                            #logger.info("psmProductKind is:")
                            #logger.info(psmProductKind)
                            pidMapping[eventPID][3] = psmProductKind
                            #logger.info('################  line # 535 #########################')
                            #logger.info(pidMapping)
                        if characteristic['name'] == 'SPB:billingAccountId':
                            #logger.info('################  line # 539 #########################')
                            spbBillingAccount = characteristic['value']
                            #logger.info("spbBillingAccount is:")
                            #logger.info(spbBillingAccount)
                            pidMapping[eventPID][4] = spbBillingAccount
                            #logger.info('################  line # 544 #########################')
                            #logger.info(pidMapping)
                        if characteristic['name'] == 'SPB:serviceFileLocationId':
                            logger.info('################  line # 367 #########################')
                            serviceFileLocationId = characteristic['value']
                            logger.info("serviceFileLocationId is:")
                            logger.info(serviceFileLocationId)
                            pidMapping[eventPID][6] = serviceFileLocationId
                            logger.info('################  line # 544 #########################')
                            logger.info('after serviceFileLocationId' + str(pidMapping))

                    except Exception as e:
                        #logger.info('################  line # 179 #########################')
                        logger.info('SPB:billingAccountId And/OR PSM_PRODUCT_KIND missing in PSM event') +str(e)
                sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
                #logger.info('################  line # 555 #########################')
                count = len(pidMapping)
                #logger.info("length of pid mapping dict inside python is:")
                #logger.info(count)
                #logger.info('################  line # 558 #########################')
                if count == len(argv):
                        logger.info('RETURNING')
                        return True, pidMapping, event
            else:
                logger.info("contains PID but new state is not" + str(newstate) + "and is: " + str(event['eventData']['newState']))
                sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
        else:
            #logger.info('################  line # 566 #########################')
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])

    #logger.info('################  line # 560 #########################')
    #logger.info('################  line # 562 #########################')
    logger.info('did not find a match for all product instance ids in PSM SNS' + str(argv))
    return False, pidMapping, all_messages



def readAndDeleteMessagePSMForGivenCharacteristics(name, producInstanceId, characteristicsName):
    status, sqs_queue = getQueueAttributes(name)
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    try:
        all_messages = response['Messages']
    except KeyError:
        logger.info('No messages on the queue!')
        return True, False, "No more messages in the queue"
    for message in all_messages:
        MessageId = message['MessageId']
        logger.info('MessageId is:')
        logger.info(MessageId)
        body = message['Body']
        data = json.loads(body)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        logger.info('event is:')
        logger.info(event)
        eventPID = event['eventData']['productInstance']['productInstanceId']
        logger.info('########## productInstanceId from event is###################### ')
        logger.info(eventPID)
        eventType = event['eventHeader']['eventType']
        if eventPID == producInstanceId and eventType == 'ProductInstanceCharacteristicsUpdateEvent':
            logger.info('found a match of event for given product instance id' + str(eventPID))
            updatedCharacteristics = event['eventData']['updatedCharacteristics']
            for updatedCharacteristic in updatedCharacteristics:
                if updatedCharacteristic['name'] == characteristicsName:
                    characteristicsValue = updatedCharacteristic['value']
                    sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
                    return True, characteristicsValue, event

            logger.info('Given characteristics is missing in PSM event')
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            return False, False, event
    logger.info('did not find a match for given prod instance id in PSM SNS' + str(producInstanceId))
    return False, False, all_messages

############## CMS Queue Functions ##############
def readAndDeleteMessageCMSWithState(name, contractInstanceId):
    status, sqs_queue = getQueueAttributes(name)
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    try:
        all_messages = response['Messages']
    except KeyError:
        logger.info('No messages on the queue!')
        all_messages = []
        return True, True, "No more messages in the queue", all_messages

    for message in all_messages:
        MessageId = message['MessageId']
        logger.console('MessageId is:')
        logger.console(MessageId)
        body = message['Body']
        logger.info('################  line # 331 #########################')
        data = json.loads(body)
        logger.info('################  line # 333 #########################')
        eventRaw = data['Message']
        logger.info('################  line # 334 #########################')
        logger.info('eventRaw is:')
        logger.info(eventRaw)
        logger.info("type of eventRaw is")
        logger.info(type(eventRaw))
        #event = eventRaw
        event = eventRaw.replace("'","")
        logger.info("type of event is")
        logger.info(type(event))
        logger.info('event is:')
        logger.info(event)
        #keyContractId, valueContractId, keyIsSigned, valueIsSigned = re.split('" |,|: ', event)
        '''
        MessageId = message['MessageId']
        logger.info('MessageId is:')
        logger.info(MessageId)
        body = message['Body']
        data = json.loads(body)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        '''
        parsedEvent = json.loads(event)
        logger.info('parsedEvent is:')
        logger.info('################  line # 335 #########################')
        logger.info(parsedEvent)
       # event = json.loads(event)
        logger.info('################  line # 336 #########################')
        eventContractId = parsedEvent['eventData']['contractId']
        logger.info('################  line # 337 #########################')
        logger.info("parsed id is")
        logger.info(eventContractId)
        logger.info("input id is")
        logger.info(contractInstanceId)
        if eventContractId == contractInstanceId:
            logger.info('################  line # 338 #########################')
            logger.info('found a match of event for a given contract instance id')
            logger.info(parsedEvent)
            eventState = parsedEvent['eventData']['eventState']
            logger.info('################  line # 399 #########################')
            #parsedIsSigned, rawString3 = re.split('}', valueIsSigned)
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            logger.info('################  line # 403 #########################')
            return True, eventState, parsedEvent
        else:
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
    logger.info('did not find a match for contract instance id in CMS SNS' + str(contractInstanceId))
    return False, False, all_messages


############## SISM Queue Functions ##############
def readAndDeleteMessageSISM(name, productInstanceId):
    status, sqs_queue = getQueueAttributes(name)
    #logger.console('################  line # 110 #########################')
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    #logger.info('################  line # 112 #########################')
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    #logger.console('################  line # 118 #########################')
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    #logger.info('################  line # 121 #########################')
    # logger.console('Response of Reading and deleting from queue ' + str(response))
    # logger.console('productInstanceId is' + str(productInstanceId))
    try:
        all_messages = response['Messages']
        #logger.info('################  line # 125 #########################')
    except KeyError:
        #logger.info('################  line # 127 #########################')
        logger.info('No messages on the queue!')
        all_messages = []
        return True, "No more messages in the queue", all_messages

    for message in all_messages:
        MessageId = message['MessageId']
        logger.info('MessageId is:')
        logger.info(MessageId)
        logger.info(message)
        body = message['Body']
        data = json.loads(body)
        # logger.console('data is:')
        # logger.console(data)
        #logger.console('################  line # 140 #########################')
        eventRaw = data['Message']
        #logger.console('################  line # 213 #########################')
        event = json.loads(eventRaw)
        #logger.console('################  line # 215 #########################')
        # logger.console('event is:')
        # logger.console(event)
        try:
            eventPID = event['eventData']['productInstanceId']
            #logger.console('################  line # 219 #########################')
        except:
            logger.console('Message body is null and does not have eventData')
            logger.console(message)
            #logger.console('################  line # 223 #########################')
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            continue

        # logger.console('################  line # 86 #########################')
        logger.console('########## productInstanceId from event is###################### ')
        logger.console(eventPID)
        #logger.console('################  line # 148 #########################')
        if eventPID == productInstanceId:
            logger.info('found a match of eventfor given product instance id')
            logger.info(event)
            stateType = event['eventHeader']['newState']['stateType']
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            return True, stateType, event
        else:
            #logger.console('################  line # 156 #########################')
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])

    #logger.console('################  line # 159 #########################')
    logger.info('did not find a match for product instance id in PSM SNS' + str(productInstanceId))
    return False, False, all_messages

'''
def readAndDeleteMessageSISM(name, productInstanceId):
    stateType = None
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    # logger.console('Response of Reading and deleting from queue ' + str(response))
    # logger.console('productInstanceId is' + str(productInstanceId))
    for message in response['Messages']:
        # logger.console('################  line # 73 #########################')
        MessageId = message['MessageId']
        logger.console('MessageId is:')
        logger.console(MessageId)
        body = message['Body']
        data = json.loads(body)
        # logger.console('data is:')
        # logger.console(data)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        # logger.console('event is:')
        # logger.console(event)
        eventPID = event['eventData']['productInstanceId']
        # logger.console('################  line # 86 #########################')
        # logger.console('########## productInstanceId from event is###################### ' + str(eventPID))
        if eventPID == productInstanceId:
            logger.info('found a match of eventfor given product instance id')
            logger.info(event)
            stateType = event['eventHeader']['newState']['stateType']
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            return True, stateType, event

    logger.info('did not find a match for product instance id in SSIM SNS' + str(productInstanceId))
    return False, None, None
'''

############## OM Queue Functions ##############
def readAndDeleteMessageOMWithState(name, orderId, expectedEndState):
    status, sqs_queue = getQueueAttributes(name)
    # logger.console('################  line # 110 #########################')
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    # logger.console('################  line # 112 #########################')
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    # logger.console('################  line # 118 #########################')
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    # logger.console('################  line # 121 #########################')
    # logger.console('Response of Reading and deleting from queue ' + str(response))
    # logger.console('productInstanceId is' + str(productInstanceId))
    try:
        all_messages = response['Messages']
        # logger.console('################  line # 125 #########################')
    except KeyError:
        # logger.console('################  line # 127 #########################')
        logger.info('No messages on the queue!')
        all_messages = []
        return True, True, "No more messages in the queue", all_messages

    for message in all_messages:
        # logger.console('################  line # 73 #########################')
        MessageId = message['MessageId']
        logger.console('MessageId is:')
        logger.console(MessageId)
        body = message['Body']
        data = json.loads(body)
        # logger.console('data is:')
        # logger.console(data)
        eventRaw = data['Message']
        logger.info('eventRaw is:')
        logger.info(eventRaw)
        logger.info("type of eventRaw is")
        logger.info(type(eventRaw))
        event = json.loads(eventRaw)
        logger.info('event is:')
        logger.info(event)
        logger.info("type of event is")
        logger.info(type(event))
        eventOrderId = event['eventData']['orderId']
        # logger.console('################  line # 86 #########################')
        # logger.console('########## productInstanceId from event is###################### ' + str(eventPID))
        if eventOrderId == orderId:
            endState = event['eventData']['newState']
            startState = event['eventData']['oldState']
            if endState == expectedEndState:
                logger.console('found a match of eventfor given order id')
                logger.info(event)
                sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
                return True, startState, endState, event
        else:
            # logger.console('################  line # 156 #########################')
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])

    # logger.console('################  line # 159 #########################')
    logger.info('did not find a match for product instance id in PSM SNS' + str(orderId))
    return False, False, False, all_messages

'''
def readAndDeleteMessageOM(name, orderId):
    status, sqs_queue = getQueueAttributes(name)
    #logger.console('################  line # 110 #########################')
    message_count = sqs_queue['Attributes']['ApproximateNumberOfMessages']
    #logger.console('################  line # 112 #########################')
    logger.console("message count is" + str(message_count))
    logger.info("message count is" + str(message_count))
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    #logger.console('################  line # 118 #########################')
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    #logger.console('################  line # 121 #########################')
    # logger.console('Response of Reading and deleting from queue ' + str(response))
    # logger.console('productInstanceId is' + str(productInstanceId))
    try:
        all_messages = response['Messages']
        #logger.console('################  line # 125 #########################')
    except KeyError:
        #logger.console('################  line # 127 #########################')
        logger.info('No messages on the queue!')
        all_messages = []
        return True, True, "No more messages in the queue", all_messages

    for message in all_messages:
        # logger.console('################  line # 73 #########################')
        MessageId = message['MessageId']
        logger.console('MessageId is:')
        logger.console(MessageId)
        body = message['Body']
        data = json.loads(body)
        # logger.console('data is:')
        # logger.console(data)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        #logger.info('event is:')
        #logger.info(event)
        eventOrderId = event['eventData']['orderId']
        # logger.console('################  line # 86 #########################')
        # logger.console('########## productInstanceId from event is###################### ' + str(eventPID))
        if eventOrderId == orderId:
            logger.console('found a match of eventfor given order id')
            logger.info(event)
            startState = event['eventData']['startState']
            endState = event['eventData']['endState']
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            return True, startState, endState, event
        else:
            #logger.console('################  line # 156 #########################')
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])

    #logger.console('################  line # 159 #########################')
    logger.info('did not find a match for product instance id in PSM SNS' + str(orderId))
    return False, False, False, all_messages
'''
'''
def readAndDeleteMessageOM(name, orderId):
    sqs_client = boto3.client('sqs', region_name='us-west-2')
    logger.console('Reading and deleting from queue ' + name)
    sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
    response = sqs_client.receive_message(QueueUrl=sqs_url, AttributeNames=['All'], MaxNumberOfMessages=10,
                                          WaitTimeSeconds=20)
    logger.info('Response of Reading and deleting from queue ' + str(response))

    for message in response['Messages']:
        # logger.console('################  line # 73 #########################')
        MessageId = message['MessageId']
        logger.console('MessageId is:')
        logger.console(MessageId)
        body = message['Body']
        data = json.loads(body)
        # logger.console('data is:')
        # logger.console(data)
        eventRaw = data['Message']
        event = json.loads(eventRaw)
        # logger.console('event is:')
        # logger.console(event)
        eventOrderId = event['orderId']
        # logger.console('################  line # 86 #########################')
        # logger.console('########## productInstanceId from event is###################### ' + str(eventPID))
        if eventOrderId == orderId:
            logger.console('found a match of eventfor given order id')
            logger.info(event)
            startState = event['startState']
            endState = event['endState']
            sqs_client.delete_message(QueueUrl=sqs_url, ReceiptHandle=message['ReceiptHandle'])
            return True, startState, endState, event

    logger.info('did not find a match for order id in OM SNS' + str(orderId))

    return False, None, None, None

'''

##### Topic Functions ############
def list_topics(params={}):
    sns_client = boto3.client('sns', region_name='us-west-2')
    response = sns_client.list_topics()
    logger.console('Response of listing topics ' + str(response))
    return response




######### Policies ################
# allow queue to receive from all topics or just the one specified
def sqsCreateSnsPolicies(queue_arn,topic_arn=False):
    # don't think Sid matters
    sqs_policy =  \
    {  \
      "Version": "2012-10-17", \
      "Id": queue_arn+"/SQSDefaultPolicy",  \
      "Statement": [  \
        {  \
          "Sid": "Sid1538418341381",  \
          "Effect": "Allow",  \
          "Principal": {  \
            "AWS": "*"  \
          },  \
          "Action": "SQS:SendMessage",  \
          "Resource": queue_arn  \
        }  \
      ]  \
    }
    if topic_arn != False:
        sqs_policy['Statement'][0]['Condition'] = {"ArnEquals":{"aws:SourceArn":topic_arn}}
    return sqs_policy


def addSnsReadPolicy(name, topic_arn):
    try:
        sqs_client = boto3.client('sqs', region_name='us-west-2')
        sqs_url = sqs_client.get_queue_url(QueueName=name)['QueueUrl']
        queue_attributes = sqs_client.get_queue_attributes(QueueUrl=sqs_url, AttributeNames=['QueueArn'])
        sqs_policy = sqsCreateSnsPolicies(queue_attributes['Attributes']['QueueArn'], topic_arn)
        policy_response = sqs_client.set_queue_attributes(QueueUrl=sqs_url,
                                                          Attributes={'Policy': json.dumps(sqs_policy)})
        logger.console('Response of read policy ' + str(policy_response))
        return True, policy_response
    except Exception as e:
        logger.console('Exception while adding sns read policy' + str(e))
        return False, None


'''
if __name__ == '__main__':
    #name = "beptest_" + str(random.randint(1, 999999))
    # name = "beptest_508933"
    #topic_arn = "arn:aws:sns:us-west-2:785409038667:pgadekar_test"
    #topic_arn = "arn:aws:sns:us-west-2:156734773799:psm-events-dev"
    #name = "bepe2e-test"
    name = "test"
    topic_arn = "arn:aws:sns:us-west-2:972022464428:rsism-events-dev"
    #createQueue(name)



    #list_topics()

    sqs_queue = getQueueAttributes(name)
    #add_sns_read_policy(name, topic_arn)

    subscribeSqsQueueToTopic(sqs_queue, topic_arn)

    #read(name)
    readAndDeleteMessageSISM(name)

    #deleteQueue(name)
'''
