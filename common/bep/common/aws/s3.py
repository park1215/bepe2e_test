# assumes credentials are in ~/.aws/credentials
import boto3
import argparse
#import sns_ops
import json, random, os
from robot.api import logger
from bep_parameters import *
from bep_common import *
from botocore.exceptions import ClientError

class s3Operations:
    def __init__(self,bucketName,assumedRole=None):
        if assumedRole is not None:
            sts_client = boto3.client('sts')
            assumed_role_object=sts_client.assume_role(
                RoleArn=assumedRole,
                RoleSessionName="AssumeRoleSession1"
            )
            credentials=assumed_role_object['Credentials']
            self.s3=boto3.resource(
                's3',
                aws_access_key_id=credentials['AccessKeyId'],
                aws_secret_access_key=credentials['SecretAccessKey'],
                aws_session_token=credentials['SessionToken'],
            )
        else:
            self.s3=boto3.resource('s3')            
          
        try:
            self.bucket = self.s3.Bucket(bucketName)
            self.bucketName = bucketName
        except Exception as e:
            logger.console("error accessing bucket " + bucketName + ":" + str(e))  

    # Check for existence of key (filename) in bucket   
    def keyExists(self,key):
        objs = list(self.bucket.objects.filter(Delimiter='/', Prefix=key))
        if len(objs) > 0:
            objList = []
            for obj in objs:
                objList.append(obj.key)
                break
            return True,objList
        else:
            return False,0
    
    def listFilesInBucket(self, prefix=None):
        fileList = []
        
        ## List objects within a given prefix or with no prefix
        if prefix is None:
            i = 0
            for obj in self.bucket.objects.all():
                fileList.append(obj.key)

        else:
            for obj in self.bucket.objects.filter(Delimiter='/', Prefix=prefix):
                fileList.append(obj.key)
        
        return fileList
    
    def writeToBucket(self,content,key):
        object = self.s3.Object(self.bucketName, key)
        # following was necessary when testing batch payments before NC sftp was available
        #response = object.put(Body=content,ACL='public-read-write')
        return response['ResponseMetadata']['HTTPStatusCode']
        
    def readFileFromBucket(self,key):
        if self.keyExists(key)[0]:
            try:
                contents = self.s3.Object(self.bucketName,key).get()['Body'].read()
                contents = contents.decode()
                return True, contents
            except Exception as e:
                logger.console('error = '+str(e))
                return False, "error reading "+key+" from "+self.bucketName+" is "+str(e)
        else:
            return False, "file " + key + " does not exist in bucket " + self.bucketName
 
# deprecated
def createS3(bucketName):
    s3Instance = s3Operations(bucketName)
    return s3Instance

def useS3Bucket(bucketName,assumedRole=None):
    s3Instance = s3Operations(bucketName,assumedRole)
    return s3Instance

#### Following functions are used for future orders
def createNewBucket(bucket_name, region='us-west-2'):
    """Create an S3 bucket in a specified region

    If a region is not specified, the bucket is created in the S3 default
    region (us-east-1).

    :param bucket_name: Bucket to create
    :param region: String region to create bucket in, e.g., 'us-west-2'
    :return: True if bucket created, else False
    """
    try:
        if region is None:
            s3_client = boto3.client('s3')
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            s3_client = boto3.client('s3', region_name=region)
            location = {'LocationConstraint': region}
            s3_client.create_bucket(Bucket=bucket_name,
                                    CreateBucketConfiguration=location)
    except ClientError as e:
        logger.error(e)
        return False
    return True

def uploadFile(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
        logger.info(response)

    except ClientError as e:
        logger.error(str(e))
        return False
    return True

def getFiles(bucket):
    """get files from an S3 bucket

    :param bucket: Bucket to upload to
    :param file_name: File to upload
    :return: True if file was uploaded, else False and files   """
    #s3_client = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    files = []

    try:
        bucket = s3_resource.Bucket(bucket)
        for obj in bucket.objects.all():
            logger.info(obj.key)
            files.append(obj.key)
        return True, files

    except ClientError as e:
        logger.error(str(e))
        return False, files

def deleteFile(bucket, fileName):
    """delete file from an S3 bucket

    :param bucket: Bucket to upload to
    :param file_name: File to delete
    :return: True if file was deleted, else False   """
    s3_client = boto3.client('s3')
    #s3_resource = boto3.resource('s3')
    try:
        response = s3_client.delete_object(Bucket=bucket, Key=fileName)
        return True, response

    except ClientError as e:
        logger.error(str(e))
        return False, files


if __name__ == "__main__":
    
    buckets = {"archive":"spb-nonprod-netcracker9p-us-west-2-archive","psmpii":"psm-preprod-pii-exporter-pii-files","irapii":"preprod-ira-spb-pii-exporter-pii-files"}

    if len(sys.argv)!=3 and len(sys.argv)!=4:
        print("provide action (list/read) and bucketname and filename (for read action only)")
    if sys.argv[1]=='list' and len(sys.argv)!=3:
        print("provide bucket name: archive, psmpii,OR irapii")
        exit()
    if sys.argv[1]=='read' and len(sys.argv)!=4:
        print("provide bucket name: archive, psmpii, OR irapii, AND provide filename")                       
    
    if sys.argv[2] not in buckets:
        print("Invalid bucket name: provide one of archive, psmpii,OR irapii")
        exit()

    bucket = buckets[sys.argv[2]]
    if bucket=="spb-nonprod-netcracker9p-us-west-2-archive":
        s3=s3Operations(bucket,S3_ARCHIVE_READ_ROLE)
    else:
        s3=s3Operations(bucket)
    
    if sys.argv[1]=="list":
        contents = s3.listFilesInBucket()
        print(contents)        
    elif sys.argv[1]=="read":
        response = s3.readFileFromBucket(sys.argv[3])
        contents = response[1]
    fo = open('s3.log',"w")
    fo.write(str(contents))
    fo.close()
            
    '''
    # MANUAL METHOD
    #s3=s3Operations("spb-nonprod-netcracker9p-us-west-2-archive",S3_ARCHIVE_READ_ROLE)
    s3=s3Operations("preprod-ira-spb-pii-exporter-pii-files",)
    files = s3.listFilesInBucket()
    contents = s3.readFileFromBucket('pii.csv')[1]
    '''
