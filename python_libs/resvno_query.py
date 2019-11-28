import sys
import argparse
import time
from fabric import Connection
import xml.etree.ElementTree as ET
import requests
from requests.auth import HTTPDigestAuth
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import logging
from logging.handlers import RotatingFileHandler
import json

URLS = {"XMLAgent":"https://xmlagent01.test.wdc1.wildblue.net:8443/XMLAgent/applicationstatus",         # submit orders
        "ServiceAvailability":"https://iws-serviceavailability01.test.wdc1.wildblue.net:8443/ServiceAvailability/v2/applicationstatus",   
        "PublicCatalogService":"https://pws-catalog01.test.wdc1.wildblue.net:8443/PublicCatalogService/v2/applicationstatus",   # get package info 
        "BusinessTransactionService":"https://iws-businesstransaction01.test.wdc1.wildblue.net:8443/BusinessTransactionWebService/v4/applicationstatus",  # get acct ref data
        "Facade-Catalog":"https://fcd-catalog01.test.wdc1.wildblue.net:8443/Facade-Catalog/v1/applicationstatus",   # get reference values for customer/account
        "ProvisioningFacade":"https://fcd-provisioningrouter01.test.wdc1.wildblue.net:8443/ProvisioningFacade/v4/applicationstatus",  # facilitate modem provisioning
        "Facade-ServiceActivationRouter":"https://fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443/Facade-ServiceActivationRouter/v1/applicationstatus",  # same
        "AuthenticationWebService":"https://iws-authentication01.test.wdc1.wildblue.net:8443/AuthenticationWebService/applicationstatus",  # authenticate a user calling public web service
        "SubscriberSearch":"https://iws-subscribersearch01.test.wdc1.wildblue.net:8443/SubscriberSearch/v2/applicationstatus",  
        "AccountInfoService":"https://pws-accountinfo01.test.wdc1.wildblue.net:8443/AccountInfoService/v3/applicationstatus",    
        "BillingFacade":"https://fcd-billing01.test.wdc1.wildblue.net:8443/BillingFacade/v5/applicationstatus",   # interact with RB, needed for create/suspend/disconnect accounts
        "Facade-Fulfillment":"https://fcd-fulfillment01.test.wdc1.wildblue.net:8443/Facade-Fulfillment/v4/applicationstatus"}  # interact with FSM

USERNAME = "appstatus"
PASSWORD = "appstatus"

    
class RESVNO_LIB:
    def  __init__(self):
        self.status = {}
        self.status['in_error'] = []
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    def getStatus(self,endpoint='all'):
        if endpoint != 'all' and endpoint in URLS:
            URL_Dict = {endpoint:URLS[endpoint]}
        else:
            URL_Dict = URLS
        for urlKey in URL_Dict:
            url = URLS[urlKey]
            for i in range(1,3):
                resp = requests.get(url, verify=False, auth=HTTPDigestAuth(USERNAME,PASSWORD))
                if resp.status_code==200:
                    root = ET.fromstring(resp.content)
                    statusAll = 'OK'
                    resources = root.findall('.//resource')
                    for resource in resources:
                        if resource.find('status').text!='OK':                      
                            self.status['in_error'].append(urlKey+"0"+str(i)+resource.find('name').text)
                            statusAll = status.text
                    self.status[urlKey+"0"+str(i)] = statusAll
                else:
                    self.status[urlKey+"0"+str(i)] = 'UNREACHABLE'
                url = url.replace("01.test","02.test",1)
        
        return self.status
        
    def saveStatus(self):
        print(self.status)

def logStatus(filename='/var/log/bepstatus/resvno_status.log'):
    rl = RESVNO_LIB()
    status = rl.getStatus()

    logger = logging.getLogger('resvno_health')
    logger.setLevel(logging.DEBUG)
    fh = RotatingFileHandler(filename, maxBytes=100*1024*1024,backupCount=5)
    fh.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(message)s')
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    
    logger2 = logging.getLogger('resvno_fails')
    logger2.setLevel(logging.DEBUG)
    logger2.addHandler(fh)    

    if len(status['in_error']) > 0:
        logger2.debug(str(status['in_error']))
    del status['in_error']
    logger.debug(json.dumps(status))


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", help="resvno endpoint to check",default="all")
    args = parser.parse_args()
    
    rl = RESVNO_LIB()
    status = rl.getStatus(args.endpoint)
    if len(status['in_error'])>0:
        print('FAILURE')
    for key in status.keys():
        print(key+":"+str(status[key]))
        
