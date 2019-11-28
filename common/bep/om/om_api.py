import urllib3
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys
import json, uuid
from json import loads, dumps
import os
import time, datetime
import dateutil.parser
import re
import bep_common
from om_parameters import *
from robot.api import logger

class OM_API_LIB:
    def getToken(self):
        comBep = bep_common.BEP_API()
        try:
            token = comBep.getBepJwtToken(OM_JWT_URL)
            if token[0]==200:                
                return True, token[1]
            else:
                return False, "token request status code = " + str(token[0])
        except Exception as e:
            return False, "Unable to retrieve OM API token: "+ str(e)
    
    def getVersion(self):
        funcName = sys._getframe().f_code.co_name
        try:
            url = OM_NP_URL+"version"
            r = requests.get(url, verify=False)
            if r.status_code == 200:
                return True, r.text

            else:
                return False, r.status_code
        except Exception as e:
            return False, funcName+":Error calling getOrder OM Endpoint, Error --> "+str(e)

    def cancelOrder(self, orderId):
        funcName = sys._getframe().f_code.co_name
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        payload = {"query":"mutation { cancelOrder (\n  orderId:\"" + orderId + "\"\n cancelReason:\"Competition\")\n \n  {state\n  orderId\n  serviceLocation\n {city latitude }\n \
                   orderLines{\n state\n productInstanceId\n characteristics{name value valueType} configuredProductType{description characteristics{name value valueType} name prices{name kind amount{value currency{name}} \
                   percentage }\n }\n }\n productInstanceIds\n  customerRelationshipId\n executionDate\n \n } \
                   \n \n}"}
        logger.info("payload = " + str(payload))

        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(OM_NP_URL, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, r.status_code
        except Exception as e:
            return False, funcName + ":Error calling cancelOrder OM Endpoint, Error --> " + str(e)
        
    def getOrder(self, orderId):
        funcName = sys._getframe().f_code.co_name
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        #returnSet = ''
        #for item in returns:
        #    returnSet = returnSet + ',' + item
        #returnSet = returnSet[1:]
        #payload = {"query":"{getOrder(orderId: \""+orderId+"\"){"+returnSet+"}}"}
        payload = {"query":"query  {getOrder(orderId: \"" + orderId + "\"){state, orderId, executionDate, customerRelationshipId, ,orderLines{productCandidateGraph{productCandidates {name kind description id productTypeId}} , state, productInstanceId, characteristics{name value valueType}, serviceLocation{latitude,longitude,addressLines,city},  \
                   productInstanceId,configuredProductType{id, name, description,products{name,description,kind, \
                   characteristics{name,value,valueType}}}}}}"}
        logger.info("payload = "+str(payload))
        
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(OM_NP_URL, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, r.status_code
        except Exception as e:
            return False, funcName+":Error calling getOrder OM Endpoint, Error --> "+str(e)

    def getOrdersByCustomerRelationshipId(self, customerRelationshipId):
        funcName = sys._getframe().f_code.co_name
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        payload = {"query":"query  {getOrdersByCustomerRelationshipId \n  (customerRelationshipId: \"" + customerRelationshipId + "\"  )\n {state \n orderId\n executionDate \n \
                   customerRelationshipId,\n paymentTransactionId\n serviceLocation {addressLines city \
                   regionOrState zipOrPostCode longitude latitude}\n  orderLineItemConfigurations {orderLineItemId} orderLines {orderLineId , state characteristics{name value valueType} productInstanceId, \n  \
                   serviceLocation{latitude,longitude,addressLines,city},\n productInstanceId, \
                   configuredProductType{ name, id ,description,\n products{name, prices\n {amount {value currency{numericCode alphabeticCode majorUnitSymbol name} } \n description \
                   name percentage unitOfMeasure kind recurrence} \n description,kind, characteristics{name,value,valueType }}}}}}"}
        logger.info("payload = " + str(payload))

        header = bep_common.createBEPHeader(tokenResponse[1], {}, True)
        logger.info("header is:")
        logger.info(header)
        try:
            r = requests.post(OM_NP_URL, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, r.status_code
        except Exception as e:
            return False, funcName + ":Error calling getOrdersByCustomerRelationshipId OM Endpoint, Error --> " + str(e)

    def upsertOrder(self, orderId, cartId, customerRelationshipId, serviceLocation, paymentTransactionId, expectedCompletionDate, cartItemId, billingAccountId, contractId, fulfillmentcartItemId, destProductCandidateId, srcProductCandidateid):
        funcName = sys._getframe().f_code.co_name
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        try:
            if serviceLocation is None:
                serviceLocationInput = ''
            else:
                serviceLocationInput = ',serviceLocation:'+ str(serviceLocation)
        except:
            serviceLocationInput = ',serviceLocation:'+ str(serviceLocation)
        if paymentTransactionId is None:
             paymentTransactionInput = ''
        else:
            paymentTransactionInput = ',paymentTransactionId:"'+ paymentTransactionId+'"'

        if expectedCompletionDate is None:
             expectedCompletionDate = ''
        else:
            expectedCompletionDate = ',executionDate:"'+ expectedCompletionDate+'"'

        if billingAccountId == 'None':
            content = 'order:{orderId: "' + orderId + '",shoppingCartId: "' + cartId + '",customerRelationshipId: "' + customerRelationshipId + '"' \
                  + paymentTransactionInput + serviceLocationInput + expectedCompletionDate + '}'
        else:
            #removed orderLineItemConfigurations field
            #orderLineItemConfigurations_field = '[{orderLineItemId: "' + cartItemId + '", attributes: [{valueType: \"test-attribute-value-type-1\", name: \"SPB:billingAccountId\", value: "' + billingAccountId + '"}]}]'
            #orderLineItemConfigurations = ',orderLineItemConfigurations:' + orderLineItemConfigurations_field
            #content = 'order:{orderId: "' + orderId + '",shoppingCartId: "' + cartId + '",customerRelationshipId: "' + customerRelationshipId + '"' \
            #       + paymentTransactionInput + orderLineItemConfigurations + serviceLocationInput + expectedCompletionDate + '}'
            if contractId == 'None':
                logger.info("no contract id")
                orderLines_field = '[{orderLineItemId: "' + str(uuid.uuid1()) + '", characteristics: {valueType: \"test-attribute-value-type-1\", name: \"SPB:billingAccountId\", value: "' + billingAccountId + '"} orderLineEvent: Add ,shoppingCartItemId: "' + cartItemId +'",' + serviceLocationInput + ' }]'
                orderLineItem = ',orderLines:' + orderLines_field
                content = 'order:{orderId: "' + orderId + '",shoppingCartId: "' + cartId + '",customerRelationshipId: "' + customerRelationshipId + '"' \
                    + paymentTransactionInput + serviceLocationInput + orderLineItem + expectedCompletionDate + '}'
            else:

                orderLines_field = '[{orderLineItemId: "' + str(uuid.uuid1()) + '", characteristics: {valueType: \"test-attribute-value-type-1\", name: \"SPB:billingAccountId\", value: "' + billingAccountId + '"} orderLineEvent: Add,shoppingCartItemId: "' + cartItemId +'", contractId: "' + contractId + '"  ' + serviceLocationInput + ' }]'
                orderLineItem = ',orderLines:' + orderLines_field
                content = 'order:{orderId: "' + orderId + '",shoppingCartId: "' + cartId + '",customerRelationshipId: "' + customerRelationshipId + '"' \
                    + paymentTransactionInput + serviceLocationInput + orderLineItem + expectedCompletionDate + '}'

                if fulfillmentcartItemId == 'None':
                    logger.info("no product candidate id")
                else:
                    orderLines_field = '[{orderLineItemId: "' + str(
                        uuid.uuid1()) + '", characteristics: {valueType: \"test-attribute-value-type-1\", name: \"SPB:billingAccountId\", value: "' + billingAccountId + '"} orderLineEvent: Add,shoppingCartItemId: "' + cartItemId + '", contractId: "' + contractId + '"  ' + serviceLocationInput + ' }, {orderLineItemId: "' + str(
                        uuid.uuid1()) + '", characteristics: {valueType: \"test-attribute-value-type-1\", name: \"SPB:billingAccountId\", value: "' + billingAccountId + '"} orderLineEvent: Add,shoppingCartItemId: "' + fulfillmentcartItemId + '"}]'
                    orderLineItem = ',orderLines:' + orderLines_field
                    #productCandidateGraphEdits_field = '[{\n  id: "'  + str(uuid.uuid1()) + ' ", editType: AddReln, addRelnEdit: { destinationId: "' + destProductCandidateId + '" destinationType: ProductCandidateId, sourceId: "' + srcProductCandidateid + '", sourceType: ProductCandidateId\n relnType: \"FULFILLS\" } }]'
                    #productCandidateGraphEdits = ',productCandidateGraphEdits:' + productCandidateGraphEdits_field
                    #content = 'order:{orderId: "' + orderId + '",shoppingCartId: "' + cartId + '",customerRelationshipId: "' + customerRelationshipId + '"' \
                    #          + paymentTransactionInput + serviceLocationInput + orderLineItem + productCandidateGraphEdits +expectedCompletionDate + '}'

                    productCandidateGraphEdits_field = '[{ id: "' + str(uuid.uuid1()) +'", editType: AddReln, addRelnEdit: {destinationId:"' + destProductCandidateId + '"  destinationType: ProductCandidateId sourceId: "' + srcProductCandidateid +'" sourceType: ProductCandidateId relnType: \"FULFILLS\" } }]'
                    productCandidateGraphEdits = ',productCandidateGraphEdits:' + productCandidateGraphEdits_field
                    content = 'order:{orderId: "' + orderId + '",shoppingCartId: "' + cartId + '",customerRelationshipId: "' + customerRelationshipId + '"' \
                              + paymentTransactionInput + serviceLocationInput + orderLineItem + productCandidateGraphEdits +expectedCompletionDate + '}'

        # remove quotes from lat/long values
        content = re.sub(r'([\'"]\w*itude[\'"]:\s*)[\'"]([-\d\.]*)[\'"]',r'\1\2',content)
        content = removeValueQuotes(content,'\w*itude')
        # remove quotes from money value
        content = removeValueQuotes(content,'amount[\'"]:\s*{[\'"]value')
        content = removeKeyQuotes(content)
        content = addDoubleBackslash(content)
        logger.info("content is:")
        logger.info(content)


        payload = '{"query":"mutation { upsertOrder('+content+'){orderId}}"}'
        logger.info("payload = "+payload)

        #omUpsertOrderExecutionId = ''
        #header = bep_common.createBEPHeader(tokenResponse[1])
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        omUpsertOrderExecutionId = header['X-BEP-Execution-Id']
        logger.info("header = " + str(header))
        
        try:
            r = requests.post(OM_NP_URL, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                return True, r.text, omUpsertOrderExecutionId
            else:
                return False, "status code = "+str(r.status_code), omUpsertOrderExecutionId
        except Exception as e:
            return False, funcName+":Error calling upsertOrder OM Endpoint, Error --> "+str(e), omUpsertOrderExecutionId

def generateFutureDatetime(unit, value):
    now = datetime.datetime.now()
    logger.info("current time is")
    logger.info(now)
    if unit == "minutes":
        future_time = now + datetime.timedelta(minutes=int(value))
    elif unit =="hours":
        future_time = now + datetime.timedelta(hours=int(value))
    elif unit == "days":
        future_time = now + datetime.timedelta(days=int(value))
    isoFormat = future_time.isoformat()
    logger.info(isoFormat)
    return isoFormat

def getCurrentIsoDatetimeAndOffeset(orderTimestamp):
    now = datetime.datetime.now()
    logger.info("now in datetime")
    logger.info(now)
    isoFormat = now.isoformat()
    logger.info("now in iso is:")
    logger.info(isoFormat)
    logger.info("order time in iso")
    logger.info(orderTimestamp)
    orderTimestampDatetime = dateutil.parser.parse(orderTimestamp)
    logger.info("order time in datetime")
    logger.info(orderTimestampDatetime)
    orderoffesetDateTime = orderTimestampDatetime + datetime.timedelta(minutes=5)
    logger.info("order time + offset in datetime")
    logger.info(orderoffesetDateTime)
    orderisoFormat = orderoffesetDateTime.isoformat()
    logger.info("order time + offset in iso")
    logger.info(orderisoFormat)
    return isoFormat, orderisoFormat

def getProductTypeIdByName(products,name):
    for product in products:
        if product['name']==name:
            return product['id']
    return None

def getProductInstanceIdByType(products,id):
    for product in products:
        if product['productTypeId']==id:
            return product['productInstanceId']
    return None
    
def removeValueQuotes(expression,key):
    result = re.sub(r'([\'"]'+key+'[\'"]:\s*)[\'"]([-\d\.]*)[\'"]',r'\1\2',expression)
    return result

def removeKeyQuotes(expression):
    result = re.sub(r'[\'"](\w*)[\'"]:',r'\1:',expression)
    return result

def addDoubleBackslash(expression):
    result = re.sub(r'[\'"]',r'\\"',expression)
    return result

def callRemove():
    input = {"a1":{"a2":1,"characteristics":[]},"b1":{"b2":{"b3":[1,2],"b4":""},"characteristics":[],"prices":[]}}
    output = removeEmptyLists(input)
    return output
    
def removeEmptyLists(input):
    characteristics =  {"name": "charName", "value": "null", "valueType": "undefined"}
    for k in list(input):
        v=input[k]
        if isinstance(v,dict):
            input[k] = removeEmptyLists(v)
        elif isinstance(v,list):
                if k=='prices':
                    del input[k]
                elif len(v)==0:
                    if k=='characteristics':
                        v.append(characteristics)

                else:
                    for i in range(0,len(v)):
                        if isinstance(v[i],dict) or isinstance(v[i],list):
                            input[k][i]=removeEmptyLists(v[i])            
        elif v=="":
            input[k] = "null"
        elif v is None:
            input[k] = "None"

    return input

def useOmApi(apiMethod,*argv):
    funcName = sys._getframe().f_code.co_name
    omApi = OM_API_LIB()
    if apiMethod=='getOrder':
        result = omApi.getOrder(argv[0])
    elif apiMethod=='upsertOrder':
        result = omApi.upsertOrder(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],argv[8],argv[9],argv[10],argv[11])
    elif apiMethod == "cancelOrder":
        result = omApi.cancelOrder(argv[0])
    elif apiMethod == "getOrdersByCustomerRelationshipId":
        result = omApi.getOrdersByCustomerRelationshipId(argv[0])
    elif apiMethod=="getVersion":
        result = omApi.getVersion()
    return result
