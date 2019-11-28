import boto3
import uuid
from robot.api import logger
from boto3.dynamodb.conditions import Key, Attr
dynamodb = boto3.resource('dynamodb')

def addPaymentTransaction(id,account,amount):
    # amount is amount * 1000
    logger.console("id = "+str(id)+", account = "+str(account)+", amount = "+str(amount))
    table = dynamodb.Table('payment_transactions')
    table.put_item(
       Item={
            'account_number': account,
            'payment_transaction_id': id,
            'amount': amount,
        }
    )
    
def searchPaymentTransactionsByAccount(account):    
    table = dynamodb.Table('payment_transactions')
    response = table.scan(
        FilterExpression=Attr('account_number').eq(account)
    )
    items = response['Items']
    return items


def addRefund(id,account,amount):
    # amount is amount * 1000
    logger.console("id = "+str(id)+", account = "+str(account)+", amount = "+str(amount))
    table = dynamodb.Table('refunds')
    refund_id = str(uuid.uuid1())
    table.put_item(
       Item={
            'refund_id': refund_id,
            'account_number': account,
            'payment_transaction_id': id,
            'amount': amount,
        }
    )
def searchRefundByAccount(account):    
    table = dynamodb.Table('refunds')
    response = table.scan(
        FilterExpression=Attr('account_number').eq(account)
    )
    items = response['Items']
    return items

def searchRefundByPaymentTransactionId(id):    
    table = dynamodb.Table('refunds')
    response = table.scan(
        FilterExpression=Attr('payment_transaction_id').eq(id)
    )
    items = response['Items']
    return items
