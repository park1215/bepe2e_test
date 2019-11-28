#!/usr/bin/python3.6

import sys
import psycopg2
import json, os, random
from credentials import *
from sql_libs import *
import time
from robot.api import logger
import urllib3
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
# urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
import secrets
import xmltodict
import time
import jaydebeapi
import sys
from robot.api import logger
import boto3
import argparse
#from bep_parameters import *
from bep_common import *
from html.parser import HTMLParser
from botocore.exceptions import ClientError

class SERTIFI_API_Lib:

    # At initialization generates information needed for security header
    '''
    def __init__(self, inputLog=False):
        # Initialize username and password used in requests
        self._cms_pg_name = "CMS"
        self._cms_pg_port = "5432"
        self._cms_pg_username = "cms_ro_user"

        #### Preprod Environment
        self._cms_pg_ip = "cmspreprod.ckv4gb50klga.us-west-2.rds.amazonaws.com"
        self._cms_pg_password = "cms_ro_user092019"
    '''

    # private function, wrapper for printing to make logs more visible
    def _print_wrapper(self, data, header):
        topLine = "------------%s------------" % str(header)
        print(topLine)
        print(data)
        botLine = "-" * len(topLine)
        print(botLine + "\n")
        return

    # returns filename (which should include relative path from this file) preceded by path of this file
    def _realPath(self, filename):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)), filename)

    def applySignature(self, apiCode, fileId, pdfId, firstName, lastName, email):
        # initialize url and header variables
        url = 'https://sandbox.sertifi.net/wildblue/services/gateway.asmx'
       # header = {''}
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://apps.sertifi.net/services/ApplySignature"', 'Content-Length': '853',
                  'Host': 'sandbox.sertifi.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_181)'}
        logger.info("################## Line # 47 ##############")
        # get payload template and generate security header
        with open(self._realPath('applySignatureTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)
        fullName = firstName + ' ' + lastName

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:ApplySignature'][
            'ser:pstr_APICode'] = apiCode
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:ApplySignature'][
            'ser:pstr_FileID'] = fileId
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:ApplySignature'][
            'ser:pstr_DocumentID'] = pdfId
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:ApplySignature'][
            'ser:pstr_NameSigned'] = fullName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:ApplySignature'][
            'ser:pstr_Email'] = email
        logger.info("################## Line # 75 ##############")
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        logger.info("################## Line # 77 ##############")
        self._print_wrapper(body, "INPUT")
        logger.info("################## Line # 79 ##############")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        logger.info("URL:" + str(url))
        logger.info("################## Line # 82 ##############")
        try:
            logger.info("################## Line # 84 ##############")
            r = requests.post(url, data=body, headers=header, verify=False)
            logger.info("################## Line # 86 ##############")
            output = xmltodict.parse(r.text)
            logger.info("################## Line # 88 ##############")
            logger.info(r)
            logger.info("################## Line # 90 ##############")
            return True, output
        except Exception as e:
            logger.info("################## Line # 92 ##############")
            output = {"error": "Could not complete request applySignature" + str(e)}
        logger.info("################## Line # 94 ##############")
        logger.info(output)
        return False, output

    def applySignatureAndParseRespose(self, apiCode, fileId, pdfId, firstName, lastName, email):
        status, returnObj = self.applySignature(apiCode, fileId, pdfId, firstName, lastName, email)
        if status:

            logger.info('returnObj in applySignature: ' + str(returnObj))
            print("applySignatureResponse = " + str(xmltodict.unparse(returnObj, pretty=True)))
            try:
                result = returnObj['soap:Envelope']['soap:Body']['ApplySignatureResponse']['ApplySignatureResult']
                logger.info('applySignatureResponse: ' + result)
                return status, result
            except Exception as e:
                logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
                return False, funcName + ":Error in applySignatureAndParseRespose " + str(e)
        else:
            return status, returnObj

def deleteEmailFile(bucket, fileName):
    """delete file from an S3 bucket

    :param bucket: Bucket to upload to
    :param file_name: File to delete
    :return: True if file was deleted, else False   """
    s3_client = boto3.client('s3')
    try:
        response = s3_client.delete_object(Bucket=bucket, Key=fileName)
        return True, response
    except ClientError as e:
        logger.error(str(e))
        return False, files

def getEmailFiles(bucket):
    """get files from an S3 bucket

    :param bucket: Bucket to upload to
    :param file_name: File to upload
    :return: True if file was uploaded, else False and files   """
    s3_resource = boto3.resource('s3')
    files = []
    try:
        bucket = s3_resource.Bucket(bucket)
        for obj in bucket.objects.all():
            #logger.info(obj.key)
            files.append(obj.key)
        return True, files
    except ClientError as e:
        logger.error(str(e))
        return False, files

def getAndReadFilesFromEmailBucket(bucket, text, firstName, lastName):
    s3_resource = boto3.resource('s3')
    status, files = getEmailFiles(bucket)
    if status:
        logger.info("count of file is" + str(len(files)))
        for file in files:
            try:
                contents = s3_resource.Object(bucket, file).get()['Body'].read()
                contents = contents.decode()
                if "servicessandbox@sertifi.net" in contents:
                    logger.info("file name is:")
                    logger.info(file)
                    if firstName in contents:
                        logger.info("first name found")
                        bepe2e, random_str = lastName.split("_", 1)
                        if random_str in contents:
                            logger.info("found email matching with first and last name")
                            if text in contents:
                                logger.info("found email matching with expected text")
                                parser = HTMLParser()
                                logger.info("parsed email with HTMLParser")
                                html_decoded_string = parser.unescape(contents)
                                logger.info("parsed to escape char with unescape")
                                logger.info(html_decoded_string)
                                new_html_decoded_string = html_decoded_string.replace("=", "")
                                logger.info("formatted email by replacing =")
                                logger.info(new_html_decoded_string)
                                return True, file, new_html_decoded_string
            except Exception as e:
                logger.info('error = ' + str(e))
                logger.info("exception while reading file")
                return False, False, "error reading " + file + " from " + str(bucket) + " is " + str(e)
    else:
        return False, False, files

def useSertifiApi(apiMethod, *argv):
    logger.info("inside 146")
    funcName = sys._getframe().f_code.co_name
    logger.info("inside 148")
    SertifiApi = SERTIFI_API_Lib()
    logger.info("inside 150")
    if apiMethod == 'applySignatureAndParseRespose':
        result = SertifiApi.applySignatureAndParseRespose(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5])
    #elif apiMethod == "getAndReadFilesFromEmailBucket":
    #    logger.info("inside useSertifiApi")
    #    logger.info(argv)
    #    result = SertifiApi.getAndReadFilesFromEmailBucket(argv[0])
    else:
        result = (False, funcName + " Incorrect number of arguments for " + funcName)
    return result


if __name__ == "__main__":
    SertifiApi = SERTIFI_API_Lib()



