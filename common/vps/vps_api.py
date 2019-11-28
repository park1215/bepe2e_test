import urllib3
from urllib.parse import urlencode
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys
import json
from json import loads, dumps
from dynamodb import *
import os
import re
import argparse
from bep_common import *
from credentials import *
from bep_parameters import *
from robot.api import logger

class VPS_API_LIB:
    def __init__(self,systemName='MexicoResidential'):
        self.baseUrl = VPS_INFO[systemName]['BASE_URL']
        if 'PAYE' in systemName:
            vpsInstance = 'EU'
        else:
            vpsInstance = systemName
        logger.console("vpsInstance="+vpsInstance)
        logger.console("creds="+str(VPS_CREDENTIALS[vpsInstance]))
        self.clientId = VPS_CREDENTIALS[vpsInstance]['CLIENT_ID']
        self.clientSecret = VPS_CREDENTIALS[vpsInstance]['CLIENT_SECRET']
        self.username = VPS_CREDENTIALS[vpsInstance]['OOE_USERNAME']
        self.password = VPS_CREDENTIALS[vpsInstance]['OOE_PASSWORD']
        self.ooeToken = VPS_CREDENTIALS[vpsInstance]['OOE_TOKEN']
        result = self.getToken()
        if result[0]==True:
            self.token = result[1]
            logger.info("TOKEN:"+str(self.token))
        else:
            raise Exception(result[1])
      
    def getToken(self):
        try:
            tokenArgs = urlencode({'grant_type':'password','client_id':self.clientId,'client_secret':self.clientSecret,\
                                  'username':self.username,'password':self.password+self.ooeToken})
            url = self.baseUrl + VPS_AUTH_ENDPOINT+ "?" + tokenArgs
            logger.info('url='+url)
            r = requests.post(url, verify=False)
            if r.status_code==200:
                response = json.loads(r.text)
                if 'access_token' in response:
                    return True, response['access_token']
                else:
                    # need to try this and see what is returned
                    return False, r.text
            else:
                if r.text:
                    return False, "token request status code = " + str(r.status_code) + ":" + str(r.text)
                else:
                    return False, "token request status code = " + str(r.status_code)
        except Exception as e:
            return False, "Unable to retrieve VPS API token: "+ str(e)

    def retrieveBatchTransactionId(self):
        funcName = sys._getframe().f_code.co_name        
        try:
            r = requests.get(url=self.baseUrl + VPS_BATCH_ENDPOINT+'/'+self.batchTransactionId, verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                logger.info(str(r.text))
                return True, r.json()
            else:
                return False, r.status_code
        except requests.exceptions.RequestException as e:
            return False, funcName+": Error calling VPS Endpoint, Error --> "+str(e)


    def retrievePaymentTransactionId(self,id):
        funcName = sys._getframe().f_code.co_name        
        try:
            r = requests.get(url=self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT+'/'+id, verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                logger.info(str(r.text))
                return True, r.json()
            else:
                return False, r.status_code
        except requests.exceptions.RequestException as e:
            return False, funcName+": Error calling VPS Endpoint, Error --> "+str(e)
   
    def requestPaymentTransactionId(self,params):
        funcName = sys._getframe().f_code.co_name
        try:
            logAPI(self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT,'',str(params))
            r = requests.post(url=self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT, json=params, verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                response = json.loads(r.text)
                if 'id' in response:
                    self.paymentTransactionId = response['id']
                    return True, response['id']

                else:
                    return False, str(response)
            else:
                return False, r.status_code
        except requests.exceptions.RequestException as e:
            return False, funcName+": Error calling requestPaymentTransactionId VPS Endpoint, Error --> "+str(e)

    def modifyPaymentTransactionId(self,params):
        funcName = sys._getframe().f_code.co_name
        billingAddress = str(params["billingAddress"])
        billingAddress = billingAddress.replace("'",'"')
        try:
            command = 'curl --request PUT --url ' + self.baseUrl + 'services/apexrest/paymentservice/'+self.paymentTransactionId+' --header \'authorization: Bearer '+self.token+'\' \
            --header \'content-type: application/json\' \
   --data \'{"txnType": "'+params["txnType"]+'", "txnAmount": "'+str(params["txnAmount"])+'", "systemName": "'+params["systemName"]+'","customerRef": "'+params["customerRef"]+'", "useragent": "API", "additionalDetails": {"billingAccount": "'+params['additionalDetails']['billingAccount']+'"}}\''
            logAPI(self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT + '/' + self.paymentTransactionId,'',command)
            os.system(command)
            r = requests.get(url=self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT + '/'+self.paymentTransactionId,  verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            return True, r.json()["additionalDetails"]["billingAccount"]

        except requests.exceptions.RequestException as e:
            return False, funcName+": Error calling modifyPaymentTransactionId VPS Endpoint, Error --> "+str(e)

    def requestPaymentOnFile(self,params):
        funcName = sys._getframe().f_code.co_name
        try:
            params = self.checkBooleans(params)
            logAPI(self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT,'',str(params))
            r = requests.post(url=self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT, json=params, verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                response = r.json()
                if 'paymentOnFileId' in response:
                    return [True, response['paymentOnFileId']]
                else:
                    return [False, str(response)]
            else:
                return [False, r.status_code]
        except requests.exceptions.RequestException as e:
            return [False, funcName+": Error calling " + funcName + " VPS Endpoint, Error --> "+str(e)]

    def retrievePaymentOnFile(self,params):
        funcName = sys._getframe().f_code.co_name
        try:
            url = self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT +'/'+ params['id']
            logAPI(url,'',str(params))
            r = requests.get(url, verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                try:
                    response = r.json()
                except:
                    response = r.text
                return [True,response]
            else:
                return [False, r.status_code]
        except requests.exceptions.RequestException as e:
            return [False, funcName+": Error calling " + funcName + " VPS Endpoint, Error --> "+str(e)]        

    def checkBooleans(self,checkedValues):
        for key in checkedValues.keys():
            if checkedValues[key]=='True':
                checkedValues[key] = True
            if checkedValues[key]=='False':
                checkedValues[key] = False
        return checkedValues
    
    def queryPaymentOnFile(self,params):
        funcName = sys._getframe().f_code.co_name
        try:
            url = self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT +'/query?systemName='+params['systemName']+'&customerRef='+params['id']
            logAPI(url,'',str(params))
            r = requests.get(url, verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                try:
                    response = r.json()
                except:
                    response = r.text
                return [True,response]
            else:
                return [False, r.status_code]
        except requests.exceptions.RequestException as e:
            return [False, funcName+": Error calling " + funcName + " VPS Endpoint, Error --> "+str(e)]               

    def updatePaymentOnFile(self,new_params):
        funcName = sys._getframe().f_code.co_name
        result = self.retrievePaymentOnFile(new_params)
        if result[0]==False:
            return [False, 'Unable to retrieve payment on file with id = '+str(new_params['id'])]
        del new_params['id']
        logger.info(" params to update = "+str(new_params))
        params = result[1]
        
        filteredParams = {}
        filteredParams['displayName'] = params['displayName']
        # update the key/value pairs provided in input
        for key in new_params.keys():
            filteredParams[key] = new_params[key]
        try:
            url = self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT +'/'+ params['id']
            filteredParams = self.checkBooleans(filteredParams)

            args = '{'
            for key in filteredParams.keys():
                if key=='displayName':
                    args = args + '"' + key + '":"' + filteredParams[key] + '"' + ','                  
                else:
                    args = args + '"' + key + '":' + (str(filteredParams[key])).lower() + ','
            args = args[:-1] + '}'

            command = 'curl --request PUT --url ' + url+' --header \'authorization: Bearer '+self.token+'\' --header \'content-type: application/json\' --data ' + "'" + args  + "'"

            os.system(command)            
            
            logAPI(url,'',command,True,True)
            return [True,'success']

        except requests.exceptions.RequestException as e:
            return [False, funcName+": Error calling " + funcName + " VPS Endpoint, Error --> "+str(e)]

    def deletePaymentOnFile(self,params):
        funcName = sys._getframe().f_code.co_name
        try:
            url = self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT +'/'+ params['id']
            logAPI(url,'',str(params))
            r = requests.delete(url=url,verify=False, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                return [True, r.status_code]
            else:
                return [False, r.status_code]
        except requests.exceptions.RequestException as e:
            return [False, funcName+": Error calling " + funcName + " VPS Endpoint, Error --> "+str(e)]
 
    def refundTransaction(self,params):
        # Minimum time between sale and refund: 5 minutes
        # params include id of original transaction (optional), and txnAmount*1000
        funcName = sys._getframe().f_code.co_name
        self.refundAmount = params['txnAmount']
        if 'paymentTxnId' in params:
            self.paymentTransactionId = params['paymentTxnId']
            del params['paymentTxnId']
        try:
            url = self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT +'/'+ self.paymentTransactionId + '/refund'
            logAPI(url,'',str(params))
            # only parameter is txnAmount
            r = requests.post(url=url,verify=False, json=params, headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                logger.info(r.text)
                if 'txnStatus' in r.json():
                    if r.json()['txnStatus']=='Success':
                        self.addTransactionToDDB('Refund')
                    return [True, r.json()["txnStatus"]]
                else:
                    return [False,r.json()]
            else:
                return [False, r.status_code]
        except requests.exceptions.RequestException as e:
            return [False, funcName+": Error calling " + funcName + " VPS Endpoint, Error --> "+str(e)]        
           
    def auth(self,params):
        funcName = sys._getframe().f_code.co_name
        if hasattr(self,'paymentTransactionId'):
            try:
                r = requests.post(url=self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT+'/'+self.paymentTransactionId+'/auth', json=params, verify=False,\
                                  headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token})
                logAPI(self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT+'/'+self.paymentTransactionId+'/auth','',str(params))
                if r.status_code == 200:
                    response = json.loads(r.text)
                    if 'txnStatus' in response:
                        if response['txnStatus']=='Success':
                            return True, 'Success'
                        else:
                            return False, str(response)
                    else:
                        return False, str(response)
                else:
                    return False, r.status_code
            except requests.exceptions.RequestException as e:
                return False, funcName+": Error calling Auth VPS Endpoint, Error --> "+str(e)
        else:
            return False, funcName + ": Error, no paymentTransactionId"
        
    def addTransactionToDDB(self,type):
        paymentTxn = self.retrievePaymentTransactionId(self.paymentTransactionId)
        if paymentTxn[0] == True:
            if 'additionalDetails' in paymentTxn[1]:
                if 'billingAccount' in paymentTxn[1]['additionalDetails']:
                    if type=="Sale":
                        addPaymentTransaction(self.paymentTransactionId,paymentTxn[1]['additionalDetails']['billingAccount'],int(paymentTxn[1]['txnAmount']*1000))
                    elif type=="Refund":
                        addRefund(self.paymentTransactionId,paymentTxn[1]['additionalDetails']['billingAccount'],int(float(self.refundAmount)*1000))
            
    def sale(self,params):
        funcName = sys._getframe().f_code.co_name
        if 'paymentTxnId' in params:
            self.paymentTransactionId = params['paymentTxnId']
            del params['paymentTxnId']
        if hasattr(self,'paymentTransactionId'):
            try:
                url = self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT+'/'+self.paymentTransactionId+'/sale'
                logAPI(url,'',str(params))
                r = requests.post(url=self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT+'/'+self.paymentTransactionId+'/sale', json=params, verify=False,\
                                  headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
                if r.status_code == 200:
                    response = json.loads(r.text)
                    logger.info(r.text)
                    self.addTransactionToDDB('Sale')  
                    if 'txnStatus' in response:
                        if response['txnStatus']=='Success':
                            return True, 'Success'
                        else:
                            return False, str(response)
                    else:
                        return False, str(response)
                else:
                    return False, r.status_code
            except requests.exceptions.RequestException as e:
                return False, funcName+": Error calling Sale VPS Endpoint, Error --> "+str(e)
        else:
            return False, funcName + ": Error, no paymentTransactionId"

    def captureSale(self):
        funcName = sys._getframe().f_code.co_name

        if hasattr(self,'paymentTransactionId'):
            try:
                r = requests.post(url=self.baseUrl + VPS_PAYMENT_SERVICE_ENDPOINT+'/'+self.paymentTransactionId+'/sale', verify=False,\
                                  headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
                if r.status_code == 200:
                    response = json.loads(r.text)
                    logger.info(str(r.text))
                    if 'txnStatus' in response:
                        if response['txnStatus']=='Success':
                            self.addTransactionToDDB('Sale')  
                            return True,  response['id']
                        else:
                            return False, str(response)
                    else:
                        return False, str(response)
                else:
                    return False, r.status_code
            except requests.exceptions.RequestException as e:
                return False, funcName+": Error calling sale VPS Endpoint, Error --> "+str(e)
        else:
            return False, funcName + ": Error, no paymentTransactionId"
    
    def queryPaymentOnFileDetails(self,systemName,customerRef):
        funcName = sys._getframe().f_code.co_name

        try:
            r = requests.get(url=self.baseUrl + VPS_PAYMENT_ON_FILE_ENDPOINT+'/query?systemName='+systemName+'&customerRef='+customerRef, verify=False,\
                              headers={'Content-type': 'application/json', 'Authorization': 'Bearer %s' %self.token}) 
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except requests.exceptions.RequestException as e:
            return False, funcName+": Error calling paymentonfile VPS Endpoint, Error --> "+str(e)


def useVpsApi(apiMethod,params={},vpsApi=None):
    funcName = sys._getframe().f_code.co_name
    if apiMethod == 'initialize':
        logger.console("PARAMS = "+str(params))
        try:
            if 'vpsSystemName' not in params:
                params['vpsSystemName']='MexicoResidential'
            vpsApi = VPS_API_LIB(params['vpsSystemName'])
            return True,vpsApi
        except Exception as e:
            logger.error("Error in " + funcName +": could not get VPS token," +str(e))
            return False,str(e)
    if apiMethod=='captureSale':
        result = vpsApi.captureSale()
    elif apiMethod=='retrievePaymentTransactionId':
        result = vpsApi.retrievePaymentTransactionId(params['id'])
    else:
        result = getattr(vpsApi, apiMethod)(params)
    return result

if __name__ == "__main__":
    '''
    {
      "nameOnCard":"Jane Doe",
      "ccNumber":"4400000000000008",
      "ccExpYear":2020,
      "ccExpMonth":10,
      "ccCVV":"737",
      "saveCard": true,
      "useAsDefault": true,
      "useForRecurringPayment": true
    }
    '''
    defaults = {'retrievePaymentTransactionId':"a2Lr0000000kbwLEAQ", \
                'requestPaymentTransactionId':{'systemName':'PAYE-00005','txnType':'Sale','txnAmount':10.00,'customerRef':"b22e1477-8f6d-4ade-9f26-718a42112e2b","currencyIsoCode": "EUR", \
                "userAgent":"API"}, \
                'auth':{'nameOnCard':'Bep Test','ccNumber':'4212345678901237','ccExpYear':2020,'ccExpMonth':10,'ccCVV':'737'}, \
                'queryPaymentOnFileDetails':{'systemName':'PAYE-00005','customerRef':'1609ac6d-bd8d-4baf-a160-872845b4e65c'}, \
                'sale':{'nameOnCard':'BLOCKED_CARD : 06 : ERROR','ccNumber':'4001590000000001','ccExpYear':2020,'ccExpMonth':10,'ccCVV':'737',"paymentTxnId":"a0L8E000004uIs7UAE"}, \
                'refundTransaction':{"paymentTxnId":"a0L8E000004uIoAUAU","txnAmount":5.24}}

    ccSale = {'nameOnCard':'BLOCKED_CARD : 06 : ERROR','ccNumber':'4001590000000001','ccExpYear':2020,'ccExpMonth':10,'ccCVV':'737'}
    pofSale = {"paymentOnFileId":"a058E000009zzhoQAA","paymentTxnId":"a0L8E000004uIoAUAU"}
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--method", dest="method", help="If present, archive result in artifactory", default="requestPaymentTransactionId") 
    args = parser.parse_args()
    
    try:
        vps = VPS_API_LIB()
    except Exception as e:
        logger.info("Exception = "+str(e))
        exit()
    '''
    if args.method in defaults:
        result = getattr(vps,args.method)(defaults[args.method])
    else:
        result = getattr(vps,args.method)()
    if result[0]==True:
        logger.console('valid response = '+str(result[1]))
    else:
        logger.console('invalid response = '+str(result[1]))
    '''
