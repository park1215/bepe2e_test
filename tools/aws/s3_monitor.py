import sys
import boto3
import json
import botocore
import argparse

# define the function blocks for diff S3 bucket operations
def bucket_exists():
    if bucket_name.creation_date:
        print('bucket exists')
        return True     
    else:
        print('bucket does not exist')
        return False
#Empties contents of bucket
def delete_bucket():
    bucket_name.objects.all().delete()
    bucket_name.delete()

#Force deletes bucket and its contents
def empty_bucket():
    bucket_name.objects.all().delete()

#Check for file/folder/key within bucket
def check_key():
    objs = list(bucket_name.objects.filter(Prefix=key))
    if len(objs) > 0 and objs[0].key == key:
        return True
    else:
        return False
#Print contents of bucket to file & return filepath
def read_keyfile():
    if check_key:
        return s3.Object(sys.argv[2],key).get()['Body'].read()
    else:
        return None

#Prints out all file.folder contents in a bucket
def bucket_contents():
    for object in bucket_name.objects.all():
        print(object)

if __name__ == '__main__':

    c2 = boto3.resource('ec2')
    s3 = boto3.resource('s3')
    parser = argparse.ArgumentParser(description='Perform various operations on a specific S3 bucket')
    parser.add_argument('-o', dest='operation', required=True, help='Operation you want performed on a specific S3 bucket')
    parser.add_argument('-b', dest='bucket', required=True, help='Name of the S3 bucket')
    parser.add_argument('-f', dest='key', required=False, default=None, help='Full path of file/folder/key in S3 bucket')
    
    args = parser.parse_args()

    s3_operation = args.operation
    bucket_name = s3.Bucket(args.bucket)
    key = args.key

# map the inputs to the function blocks
    options = {'a' : bucket_exists,
               'b' : check_key,
               'c' : empty_bucket,
               'd' : delete_bucket,
               'f' : read_keyfile,
               'g' : bucket_contents,
               'h' : read_keyfile,
    }

    options[s3_operation]()
