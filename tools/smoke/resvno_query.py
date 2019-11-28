import sys
import argparse
import time
from fabric import Connection
import xml.etree.ElementTree as ET
import requests
from requests.auth import HTTPDigestAuth
from requests.packages.urllib3.exceptions import InsecureRequestWarning

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
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    def getStatus(self,endpoint='all'):
        if endpoint != 'all' and endpoint in URLS:
            URL_Dict = {endpoint:URLS[endpoint]}
        else:
            URL_Dict = URLS
        for urlKey in URL_Dict:
            url = URLS[urlKey]
            resp = requests.get(url, verify=False, auth=HTTPDigestAuth(USERNAME,PASSWORD))
            root = ET.fromstring(resp.content)
            status = root.find('status')
            self.status[urlKey+"01"] = status.text
            url = url.replace("01.test","02.test",1)
            resp = requests.get(url, verify=False, auth=HTTPDigestAuth(USERNAME,PASSWORD))
            root = ET.fromstring(resp.content)
            status = root.find('status')
            self.status[urlKey+"02"] = status.text
        return self.status
        
    def sendStatus(self):
        print("sending status")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("endpoint", help="resvno endpoint to check")
    args = parser.parse_args()
    
    rl = RESVNO_LIB()
    status = rl.getStatus(args.endpoint)
    for key in status.keys():
        print(key+":"+status[key])

