import boto3
from boto3.dynamodb.conditions import Key, Attr
dynamodb = boto3.resource('dynamodb')

table = dynamodb.create_table(
    TableName='payment_transactions',
    KeySchema=[
        {
            'AttributeName': 'payment_transaction_id',
            'KeyType': 'HASH'
        },
        {
            'AttributeName': 'account_number',
            'KeyType': 'RANGE'
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'payment_transaction_id',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'account_number',
            'AttributeType': 'S'
        },
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    }
)

table = dynamodb.create_table(
    TableName='refunds',
    KeySchema=[
        {
            'AttributeName': 'refund_id',
            'KeyType': 'HASH'
        },
        {
            'AttributeName': 'payment_transaction_id',
            'KeyType': 'RANGE'
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'refund_id',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'payment_transaction_id',
            'AttributeType': 'S'
        }
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    }
)

ddb=boto3.Session(region_name='us-west-2').client('dynamodb')
ddb.update_table(
    AttributeDefinitions=[{'AttributeName': 'account_number', 'AttributeType': 'S'}, {'AttributeName': 'payment_transaction_id', 'AttributeType': 'S'}, {'AttributeName': '5999', 'AttributeType': 'N'}], 
    TableName='payment_transactions', 
    GlobalSecondaryIndexUpdates=[{'Create': {'IndexName': 'acctindex', 'KeySchema': [{'AttributeName': 'payment_transaction_id', 'KeyType': 'HASH'},{'AttributeName': 'account_number', 'KeyType': 'RANGE'}],
    'Projection': {'ProjectionType': 'ALL'}, 'ProvisionedThroughput': {'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}}}]
)

ddb.update_table(
    AttributeDefinitions=[{'AttributeName': 'refund_id', 'AttributeType': 'S'},{'AttributeName': 'account_number', 'AttributeType': 'S'}, {'AttributeName': 'payment_transaction_id', 'AttributeType': 'S'}], 
    TableName='refunds', 
    GlobalSecondaryIndexUpdates=[{'Create': {'IndexName': 'ptxidindex', 'KeySchema': [{'AttributeName': 'refund_id', 'KeyType': 'HASH'},{'AttributeName': 'payment_transaction_id', 'KeyType': 'RANGE'}],
    'Projection': {'ProjectionType': 'ALL'}, 'ProvisionedThroughput': {'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}}},{'Create': {'IndexName': 'acctindex', 'KeySchema': [{'AttributeName': 'refund_id', 'KeyType': 'HASH'},{'AttributeName': 'account_number', 'KeyType': 'RANGE'}],
    'Projection': {'ProjectionType': 'ALL'}, 'ProvisionedThroughput': {'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}}}]
)
