import uuid
import urllib3
import requests, uuid
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import secrets
import sys
import json
from json import loads, dumps
import os
import time
import bep_common
import spb_parameters
from robot.api import logger
import re

class SPB_API_LIB:
    def getToken(self):
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        try:
            status, token = comBep.getBepJwtToken(spb_parameters.SPB_JWT_URL)
            if status == 200:
                return True, token
        except Exception as e:
            return False, funcName +": Unable to retrieve SPB API token: "+ str(e)

    def getVersion(self):
        funcName = sys._getframe().f_code.co_name      

        results = {}
        for key in spb_parameters.SPB_VERSION_URLS:
            try:
                url = spb_parameters.SPB_VERSION_URLS[key]
                r = requests.get(url, verify=False)
                matches = re.search('com.viasat.spb : [a-zA-Z\s-]* : (.*)',r.text)
                if r.status_code == 200:
                    results[key] = matches[1]
                else:
                    results[key] = r.status_code
            except Exception as e:
                results[key] = funcName+":Error calling getVersion for SPB Endpoint, Error --> "+str(e)
        return results
        
    def getProductInstance(self, productInstanceId):
        funcName = sys._getframe().f_code.co_name
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]

        url = spb_parameters.SPB_PP_URL

        payload = {"query":"query {\n getProductInstance(productInstanceId: \"" + productInstanceId + "\")\n {\n  productInstanceStatus\n  accountNumber\n  name\n  productInstanceId\n  customerAgreementId\n  price {amount {currency {alphabeticCode minorUnits majorUnitSymbol name numericCode} value } description kind name}\n  subscriptionId\n\t}}"}

        if tokenResponse[0] == True:
            header = bep_common.createBEPHeader(tokenResponse[1],{},True)
            logger.info ("header is:")
            logger.info (header)
        try:
            logger.info(json.dumps(payload))
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.info("response is:")
            logger.info(r)
            print(r.status_code)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = " + str(r.status_code)
        except Exception as e:
            return False, funcName + ":Error calling getProductInstance SPB Endpoint, Error --> " + str(e)


    def addOneTimePayment(self, paymentTransactionId, paymentReferenceType):
        funcName = sys._getframe().f_code.co_name
        url = spb_parameters.SPB_PP_URL      
        payload = '{"query":"mutation{addOneTimePayment(paymentTransactionId: \\"'+paymentTransactionId+'\\",paymentReferenceType:\\"'+paymentReferenceType+'\\"){paymentTransactionId}}"}'
        
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        bep_common.logAPI(url,str(header),payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                response = r.text
                logger.info(response)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)+": "+r.text
        except Exception as e:
            return False, funcName+":Error calling addOneTimePayment SPB Endpoint, Error --> "+str(e)
        
    def getBillingAccountData(self, accountNumber):
        funcName = sys._getframe().f_code.co_name
        url = spb_parameters.SPB_PP_URL
        payload = '{"query":"query{getBillingAccount(accountNumber:\\"'+accountNumber+'\\"){invoicingOrganization{invoicingOrgId description} accountGroupNumber accountNumber accountStatus mailingPIIRefId billingPIIRefId paymentReference {type{description name } value} piiFileLocationId billingCycleDayOfMonth nextBillPeriodStartDate recurringPaymentMethodType currentBalance{value  \
                  currency{name alphabeticCode numericCode majorUnitSymbol minorUnits}}}}"}'
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        bep_common.logAPI(url,str(header),payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                logger.info(r.text)
                return True, r.json()['data']['getBillingAccount']
            else:
                return False, "status code = "+str(r.status_code)+": "+r.text
        except Exception as e:
            return False, funcName+":Error calling getBillingAccount SPB Endpoint, Error --> "+str(e)        
        
    def upsertProductInstance(self, highLevelProductInstanceId, equipmentInstanceId, customerId, buyerId, customerRelId):
        funcName = sys._getframe().f_code.co_name
        url = spb_parameters.SPB_PP_URL
        equipmentOrderInstanceId= str(uuid.uuid1())
        highLevelProductOrderInstanceId = str(uuid.uuid1())
        #payload = {"query":"mutation {  upsertProductInstance(input: { productInstanceEvent: \"ADD\", partySummary: [ {partyRoleId: \""+customerId+"\", role: \"Customer\"}, {partyRoleId: \""+buyerId+"\", role: \"Payer\"}], location: { isoCountryCode: { alphabeticThreeCharacterCode: \"MEX\", name: \"Mexico\" } }, products: [ {productInstanceId: \""+highLevelProductInstanceId+"\", orderLineInstanceId: \""+highLevelProductOrderInstanceId+"\", productTypeId: \"4d0b6b7b-9eb2-44ad-8ac6-2adf1ba00a9b\", name: \"Viasat Business Metered 50 GB\", description: \"Viasat 50 Mbps - MX - V2\", kind: \"RESIDENTIAL_INTERNET\" features: [ {name: \"BILLING_PRODUCT_ID\", value: \"502\"}, {name: \"BILLING_PRICE_ID\", value: \"1003\"}, ], prices: [{kind: \"OfferedPrice\", frequency: \"Monthly\", money: {amount: 1300, currency: {name: \"Pesos\", alphabeticCode: \"MEX\", majorUnitSymbol: \"MEX$\"}}}], products:[ { productInstanceId: \""+equipmentInstanceId+"\", orderLineInstanceId: \""+equipmentOrderInstanceId+"\", productTypeId: \"e7bd3035-8e0a-45dc-9922-2ce0cbff3f0a\", name: \"Equipment Lease Fee - Monthly\",  kind: \"EQUIPMENT_LEASE_FEE\", features: [   {name: \"BILLING_PRODUCT_ID\", value: \"504\"}, {name: \"BILLING_PRICE_ID\", value: \"1007\"},], prices: [{kind: \"OfferedPrice\", frequency: \"Monthly\", money: {amount: 200, currency: {name: \"Pesos\", alphabeticCode: \"MEX\", majorUnitSymbol: \"MEX$\"}}}]  } ]}]}) { name productInstanceId,productInstanceStatus, price{money { amount currency {alphabeticCode} }} products { productInstanceId productInstanceStatus name } }\n}"}
        payload = {"query":"mutation { upsertProductInstance( input: { customerRelationshipId: \""+customerRelId+"\" location: { isoCountryCode: { alphabeticThreeCharacterCode: \"MEX\", name: \"Mexico\" } } partySummary: [ { partyRoleId: \"" + customerId + "\" role: \"Customer\" } { partyRoleId: \""+buyerId+"\", role: \"Payer\" } ] productInstanceEvent: \"ADD\" products: [ { characteristics: [ { name: \"BILLING_PRODUCT_ID\", value: \"502\", valueType: \"string\" } { name: \"BILLING_PRICE_ID\", value: \"1004\", valueType: \"string\" } ] productInstanceId: \""+highLevelProductInstanceId+"\" orderLineInstanceId: \""+highLevelProductOrderInstanceId+"\" productTypeId: \"37977211-824a-4ca8-922a-6fcb8b6dcddd\" name: \"Viasat 12 Mbps\" description: \"Viasat 12 Mbps - MX - V2\" kind: \"RESIDENTIAL_INTERNET\" prices: [ { kind: \"OfferedPrice\" recurrence: \"Once\" amount: { currency: { alphabeticCode: \"MEX\" majorUnitSymbol: \"MEX$\" minorUnits: null name: \"Pesos\" numericCode: null } value: 1080 } } ] products: [ { productInstanceId: \""+equipmentInstanceId+"\" orderLineInstanceId: \""+equipmentOrderInstanceId+"\" productTypeId: \"7e57ccf2-64a8-4e6a-9793-876c7845ef69\" name: \"Lease Fee Monthly\" kind: \"EQUIPMENT_LEASE_FEE\" characteristics: [ { name: \"BILLING_PRODUCT_ID\",   value: \"504\", valueType: \"string\"} { name: \"BILLING_PRICE_ID\", value: \"1007\", valueType: \"string\" } ] prices: [ { kind: \"OfferedPrice\" recurrence: \"Monthly\" amount: { currency: { alphabeticCode: \"MEX\" majorUnitSymbol: \"MEX$\" minorUnits: null name: \"Pesos\" numericCode: null } value: 200 } } ] } ] } ] } ) { name productInstanceId productInstanceStatus price { amount { currency { alphabeticCode majorUnitSymbol minorUnits name numericCode } value } } products {productInstanceId productInstanceStatus name } customerAgreementId, subscriptionId } }"}
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info(header)
        try:
            logger.info(url)
            logger.info('payload is')
            logger.info(payload)
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling upsertProductInstance SPB Endpoint, Error --> "+str(e)
        
    def addBillingAccount(self,params):
        funcName = sys._getframe().f_code.co_name
        url = spb_parameters.SPB_PP_URL
        payload = '{"query":"mutation{addBillingAccount('
        for key in params.keys():
            payload = payload + str(key) + ':\\"' + str(params[key]) + '\\",'
        payload = payload[:-1] + '){accountNumber}}"}'
        
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        bep_common.logAPI(url,str(header),payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                logger.console("spb response = " +r.text)
                response = r.json()
                accountId = 'none'
                if 'errors' in response:
                    return False, r.text
                else:
                    return True, response["data"]["addBillingAccount"]["accountNumber"]
            else:
                return False, "status code = "+str(r.status_code)+": "+r.text
        except Exception as e:
            return False, funcName+":Error calling addBillingAccount SPB Endpoint, Error --> "+str(e)
    
    def getPaymentHistory(self,params):
        funcName = sys._getframe().f_code.co_name
        url = spb_parameters.SPB_PP_URL
        payload = '{"query":"query{getPaymentHistory(accountNumber:\\"'+params['accountNumber']+'\\"){paymentStatus isRefund paymentDate paymentAmount{value currency{name}} paymentType}}"}'
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        bep_common.logAPI(url,str(header),payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                if 'errors' in r.json():
                    return False, r.text
                return True, r.json()
            else:
                return False, "status code = "+str(r.status_code)+": "+r.text
        except Exception as e:
            return False, funcName+":Error calling " + funcName + " SPB Endpoint, Error --> "+str(e)        

def CreatePIDMappingForMainAndSubProducts(*argv):
    # This creates a dict for product instance ids example:{pid:[kind, spb_cat, acct_id, cust_ref, subscriptionid, product_id, tariff_id]}
    billingAccountId  = argv[0]
    subscriptionId = argv[1]
    ncCustomerRef  = argv[2]
    highLevelProdInstanceId  = argv[3]
    contractProdInstanceId = argv[4]
    discountProdInstanceId = argv[5]
    internetKind = argv[6]
    contractKind = argv[7]
    discountKind = argv[8]
    mainProdTariffId  = argv[9]
    contractTariffId = argv[10]
    discountTariffId = argv[11]
    highLevelSpbCat = argv[12]
    contractSpbCat = argv[13]
    discountSpbCat = argv[14]
    mainProdId = argv[15]
    contractProdId = argv[16]
    discountProdId = argv[17]
    productMapping = {highLevelProdInstanceId:[internetKind, highLevelSpbCat,billingAccountId, ncCustomerRef, subscriptionId, mainProdId, mainProdTariffId], contractProdInstanceId:[contractKind, contractSpbCat,billingAccountId, ncCustomerRef, subscriptionId, contractProdId, contractTariffId], discountProdInstanceId:[discountKind, discountSpbCat,billingAccountId, ncCustomerRef, subscriptionId, discountProdId, discountTariffId]}
    return  productMapping


def CreatePIDMappingForMainAndSubProductsForNorway(*argv):
    # This creates a dict for product instance ids example:{pid:[kind, spb_cat, acct_id, cust_ref, subscriptionid, product_id, tariff_id]}
    billingAccountId  = argv[0]
    subscriptionId = argv[1]
    ncCustomerRef  = argv[2]
    highLevelProdInstanceId  = argv[3]
    contractProdInstanceId = argv[4]
    equipmentLeaseProdInstanceId = argv[5]
    internetKind = argv[6]
    contractKind = argv[7]
    equipmentLeaseKind = argv[8]
    mainProdTariffId  = argv[9]
    contractTariffId = argv[10]
    equipmentLeaseTariffId = argv[11]
    highLevelSpbCat = argv[12]
    contractSpbCat = argv[13]
    equipmentLeaseSpbCat = argv[14]
    mainProdId = argv[15]
    contractProdId = argv[16]
    equipmentLeaseProdId = argv[17]
    productMapping = {highLevelProdInstanceId:[internetKind, highLevelSpbCat,billingAccountId, ncCustomerRef, subscriptionId, mainProdId, mainProdTariffId], contractProdInstanceId:[contractKind, contractSpbCat,billingAccountId, ncCustomerRef, subscriptionId, contractProdId, contractTariffId], equipmentLeaseProdInstanceId:[equipmentLeaseKind, equipmentLeaseSpbCat,billingAccountId, ncCustomerRef, subscriptionId, equipmentLeaseProdId, equipmentLeaseTariffId]}
    return  productMapping

def useSpbApi(apiMethod,*argv):
    funcName = sys._getframe().f_code.co_name
    spbApi = SPB_API_LIB()

    if apiMethod=='upsertProductInstance':
        result = getattr(spbApi,apiMethod)(argv[0], argv[1], argv[2], argv[3], argv[4])
    elif apiMethod=='addOneTimePayment':
        result = getattr(spbApi,apiMethod)(argv[0],argv[1])
    elif apiMethod=='getVersion':
        result = getattr(spbApi,apiMethod)()
    else:
        result = getattr(spbApi,apiMethod)(argv[0])

    return result

if __name__ == "__main__":
    spbApi = SPB_API_LIB()
    #result = spbApi.getVersion()
    result = spbApi.getPaymentHistory({"accountNumber":sys.argv[1]})
    print(str(result))
