##############################################################
#
#  File name: common_library.py
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################


import string
import json
import random
import csv
import sys
import uuid, os
from datetime import datetime, timedelta
import boto3, re
from robot.api import logger

def generateGuid():
    return str(uuid.uuid1())

def generateRandomMacAddress():
    """
    Method Name:  generateRandomMacAddress
    Description:  Generate random mac address that starts with 44:44
    return:  mac addresss
    """
    mac = ("44:44:%02x:%02x:%02x:%02x" % (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255), random.randint(0, 255),))
    return mac.upper()

def convertJsonToDictionary(json_data):
    """
    Method Name :  convert_json_to_dictiory
    Parameters  :  jsondata
    Description :  Take json data and return dictiory
    return      :  dictiory
    """
    return json.loads(json_data)

def deleteAllSubscriptions():
    '''
    logger.info("inside deletAllSubscriptions")
    sns_client = boto3.client('sns', region_name='us-west-2')
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'arn_list.json'),
              "r") as aws_json_file:
        aws_subscriptions = json.load(aws_json_file)
        Subscriptions = aws_subscriptions["Subscriptions"]
        for subscription in Subscriptions:
            SubscriptionArn = subscription['SubscriptionArn']
            logger.info(SubscriptionArn)
            if "psm" in SubscriptionArn or "om" in SubscriptionArn or "cms" in SubscriptionArn:
                    logger.info("deleting subscription")
                    unsubscribeResponse = sns_client.unsubscribe(SubscriptionArn=SubscriptionArn)

        return True
    '''

    print ("This code is commented out and can be used in future if boto3 does not return list of subscriptions")
    #Sequence to run it is:
    # execute "aws sns list-subscriptions >> arn_list.json" under bepe2e_test/common on beptest.bepe2e.viasat.io server
    # Call deleteAllSubscriptions in any robot file

def trim(input):
    return input.strip()