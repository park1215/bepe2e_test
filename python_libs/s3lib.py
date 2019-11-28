# assumes credentials are in ~/.aws/credentials
import boto3
from botocore.exceptions import ClientError
from robot.api import logger

class s3library:
    def __init__(self,bucketName,assumedRole=None):
        print("bucket="+bucketName)
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
            logger.info("error accessing bucket " + bucketName + ":" + str(e))  

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

def getIraPii(searchString="Bepe2e",country=None):
    s3Instance = s3library("preprod-ira-spb-pii-exporter-pii-files")
    result = s3Instance.readFileFromBucket("pii.csv")
    if result[0]==False:
        print(result[1])
        return False
    else:
        lines = result[1].split("\n")
        bepe2e_accounts = []
        none_count = 0
        country_count = 0
        for line in lines:
            if searchString in line and 'Bepe2e_AZ' not in line:             
                linelist = line.split(';')
                if country is None or linelist[7]==country:
                    bepe2e_accounts.append(linelist)
        logger.console("number of bepe2e accounts = "+str(len(bepe2e_accounts)))

        return bepe2e_accounts
 
def useS3Bucket(bucketName,assumedRole=None):
    s3Instance = s3lib(bucketName,assumedRole)
    return s3Instance


