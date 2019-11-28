#!/usr/bin/python3.6
import pysftp
from robot.api import logger
import os

SFTP_HOST = 'sftp.eci-ss.viasat.io'
SFTP_USERNAME = 'netcracker9p'
SFTP_PRIVATE_KEYFILE = 'netcracker9pe2e.key'
SFTP_DIRECTORY = '/spb-nonprod-netcracker9p-us-west-2-in/payments'
SFTP_TOP_FOLDER = '/spb-nonprod-netcracker9p-us-west-2-in'
SFTP_SUB_FOLDER = 'payments'


def listFiles(dir=SFTP_DIRECTORY):
    cnOpts = pysftp.CnOpts()
    cnOpts.log = True
    dir_path = os.path.dirname(os.path.realpath(__file__))

    with pysftp.Connection(SFTP_HOST,username=SFTP_USERNAME,private_key=dir_path+'/'+SFTP_PRIVATE_KEYFILE,cnopts=cnOpts) as sftp:        
        fileList = sftp.listdir(dir)
        logger.console("files = "+str(fileList))
    
def putFile(filename):
    cnOpts = pysftp.CnOpts()
    cnOpts.log = True
    dir_path = os.path.dirname(os.path.realpath(__file__))
    with pysftp.Connection(SFTP_HOST,username=SFTP_USERNAME,private_key=dir_path+'/'+SFTP_PRIVATE_KEYFILE,cnopts=cnOpts) as sftp:
        try:
            with sftp.cd(SFTP_TOP_FOLDER):
                sftp.put(filename,remotepath=SFTP_SUB_FOLDER+'/'+filename)
                result = [True,'']
        except Exception as e:
            logger.console("sftp put failure for file "+filepath+": "+str(e))
            result = [False,str(e)]
    return  result
if __name__ == "__main__":
    #putFile('VGBP_ESP_3017_20190820180035.txt')
    listFiles()

