import datetime
from robot.api import logger

# allow queue to receive from all topics or just the one specified
def sqs_create_sns_policy(queue_arn,topic_arn=False):
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