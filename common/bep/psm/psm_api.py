import uuid
import urllib3
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import secrets
import sys
import json
from json import loads, dumps
import os
import time
import bep_common
import psm_parameters
from robot.api import logger

class PSM_API_LIB:
    def getToken(self):
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        try:
            status, token = comBep.getBepJwtToken(psm_parameters.PSM_JWT_URL)
            if status == 200:
                return True, token
        except Exception as e:
            return False, funcName +": Unable to retrieve PSM API token: "+ str(e)


    def getProductInstance(self, productInstanceId):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        payload = {"query":"{\n  getProductInstances(input: {productInstanceId: \"" + productInstanceId + "\"}) {\n \n productInstances {state\n productInstanceId\n productTypeId\n name\n  \
                   partySummary {\n name\n value\n }\n locations {\n address {\n addressLine\n municipality\n region\n postalCode\n countryCode\n }\n coordinates {\n latitude\n longitude\n }\n }  \
        \n productTypeId\n name\n description\n kind\n characteristics {\n name\n value\n valueType\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n value\n currency \
        {\n name\n alphabeticCode\n numericCode\n majorUnitSymbol\n minorUnits\n }\n }\n percentage\n unitOfMeasure\n characteristics {\n name\n value\n valueType\n }\n }\n } \
        productInstanceRelationships {\n productInstanceRelationshipId\n sourceProductInstance {kind productTypeId productInstanceId}\n destinationProductInstance {productTypeId productInstanceId}\n \
        productRelationshipType\n startTimestamp\n endTimestamp\n \n }\n }\n}\n"}
        logger.info(str(payload))

        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = '+str(r.status_code))
            if r.status_code == 200:               
                response = r.json()
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = '+str(e))
            return False, funcName+":Error calling getParty PSM Endpoint, Error --> "+str(e)

    def requestProductInstanceLifecycleStateChange(self, productInstanceId, state):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        payload = {"query":"mutation {\n  requestProductInstanceLifecycleStateChange(input: {productInstanceId: \"" + productInstanceId + "\" state: " + state + "}) {\n  success}}\n"}
        try:
            logger.info(str(payload))
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = ' + str(r.status_code))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + ":Error calling requestProductInstanceLifecycleStateChange PSM Endpoint, Error --> " + str(e)

    def getProductInstanceEvents(self, productInstanceId):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        payload = {"query":"{\n getProductInstanceEvents(input: {productInstanceId: \"" + productInstanceId +"\"}) {\n \n events {caller timestamp action response request}\n }\n}\n"}
        try:
            logger.info(str(payload))
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = ' + str(r.status_code))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + ":Error calling getProductInstanceEvents PSM Endpoint, Error --> " + str(e)

    def insertProductInstanceRelationship(self, srcProductInstanceId, destProductInstanceId, relationshipType):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        payload = {"query":"mutation {\n insertProductInstanceRelationship(input: {productInstanceRelationshipId: \"" + str(uuid.uuid1()) + "\" productRelationshipType: " + relationshipType+ " sourceProductInstanceId:\"" + srcProductInstanceId + "\" destinationProductInstanceId:\"" + destProductInstanceId + "\"}) {\n \n  productRelationshipType\n  productInstanceRelationshipId \n\n  }}\n"}
        try:
            logger.info(str(payload))
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = ' + str(r.status_code))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + ":Error calling insertProductInstanceRelationship PSM Endpoint, Error --> " + str(e)

    def requestUpsertCharacteristics(self, productInstanceId, name, value):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        payload = {"query":"mutation {\n requestUpsertCharacteristic(input: {\n productInstanceId: \"" + productInstanceId + "\" \n characteristics:{\n valueType:\"String\"\n name: \"" + name + "\",\n value : \"" + value + "\"\n \n } }\n \n ) \n \n {\n success\n }\n}"}
        try:
            logger.info(str(payload))
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = ' + str(r.status_code))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + ":Error calling requestUpsertCharacteristics PSM Endpoint, Error --> " + str(e)

    def getProductInstanceWithRelnId(self, relnId):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        returnSet = "productInstances{productInstanceId kind}"
        payload = '{"query":"query{getProductInstances(input:{partySummary:{name:\\"relnId\\", value:\\"'+relnId+'\\"}}){'+returnSet+'}}"}'
        logger.info(str(payload))
        logger.info(str(url))
		
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            logger.console('status code = ' + str(r.status_code))
            print(r.text)
            if r.status_code == 200:
                return True, r.json()
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + " Error caling getProductInstanceWithRelnId PSM Endpoint, Error --> " + str(e)

    def getProductInstanceForFOWithRelnId(self, relnId):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)
        returnSet = "productInstances{state, productInstanceId, productTypeId, name, kind, characteristics {name, value}}"
        payload = '{"query":"query{getProductInstances(input:{partySummary:{name:\\"relnId\\",value: \\"'+relnId+'\\"}}){'+returnSet+'}}"}'
        logger.console(str(payload))
        logger.info(str(url))
		
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            logger.console('status code = ' + str(r.status_code))
            print(r.text)
            if r.status_code == 200:
                return True, r.json()
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + " Error caling getProductInstanceWithRelnId PSM Endpoint, Error --> " + str(e)

        
    def upsertProductInstance(self, partyRoleId):
        funcName = sys._getframe().f_code.co_name
        url = psm_parameters.PSM_PP_URL
        payload = {"query":"mutation {\n\tUpsertProductInstance(\n\t\tinput: {\n\t\t\tproductInstanceId: null,\n\t\t\t#Create new productInstanceId\n\t\t\tparty: [{\n\t\t\t\tpartyRoleId: \""+partyRoleId+"\"\n\t\t\t}],\n\t\t\tlocation: {\n\t\t\t\tlatitude: 39.55,\n\t\t\t\tlongitude: -104.86,\n\t\t\t\taddressLine: \"349 Inverness Drive South\",\n\t\t\t\tcity: \"Englewood\",\n\t\t\t\tregionOrState: \"CO\",\n\t\t\t\tisoCountryCode: {\n\t\t\t\t\tname: \"USA\",\n\t\t\t\t\talphabeticThreeCharacterCode: \"USA\"\n\t\t\t\t}\n\t\t\t},\n\t\t\tproductTypeId: \"36e3f8a3-9356-458e-bfca-36954ec7ee24\",\n\t\t\tproducts: [{\n\t\t\t\t\tproductTypeId: \"0b81d9a9-3c4f-4e6a-9f1d-7a21de4169fa\",\n          products: [{\n\t\t\t\t\t\tproductTypeId: \"297413e0-d2de-4912-9786-90f561bdd7cb\",       \n\t\t\t\t\t}]\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\tproductTypeId: \"c20903c6-8e97-4f8e-9130-7795dcfdf1ba\",\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\tproductTypeId: \"019c2568-93d1-499a-9713-4a569fcca0ab\"\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\tproductTypeId: \"a9e23320-7346-44fc-93a4-871123a476fa\",\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\tproductTypeId: \"560328d6-3848-4d20-b256-5f565fb3dca5\",\n\t\t\t\t\tproducts: [{\n\t\t\t\t\t\tproductTypeId: \"4df71269-b681-451e-b826-4c3b09f9415b\",\n          },\n        {\n         productTypeId: \"ab4d360a-79fd-4908-a7b6-24eeac7402a4\",\n        }]\n\t\t\t\t}\n\t\t\t]\n\t\t}\n\t) {\n\t\tproductInstanceId\n\t}\n}"}
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        logger.info ("header is:")
        logger.info (header)

        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling getParty PSM Endpoint, Error --> "+str(e)

    def createPom2PsmDict(self, psmResponse):
        funcName = sys._getframe().f_code.co_name
        #jsonStruct = json.dumps(jsonPsmResponse)
        pom2psm_dict = {}
        HLPID = psmResponse['data']['GetProductInstance']['productInstanceId']
        HLPTID = psmResponse['data']['GetProductInstance']['productTypeId']
        pom2psm_dict[HLPTID] = HLPID
        #print(pom2psm_dict)
        #print(HLPID)
        #print(HLPTID)
        SP1ID = psmResponse['data']['GetProductInstance']['products'][0]['productInstanceId']
        SP1TID = psmResponse['data']['GetProductInstance']['products'][0]['productTypeId']
        pom2psm_dict
        #print(SP1TID)
        SSP1ID = psmResponse['data']['GetProductInstance']['products'][0]['products'][0]['productInstanceId']
        SSP1TID = psmResponse['data']['GetProductInstance']['products'][0]['products'][0]['productTypeId']
        #print(SSP1TID)
        SP2ID = psmResponse['data']['GetProductInstance']['products'][1]['productInstanceId']
        SP2TID = psmResponse['data']['GetProductInstance']['products'][1]['productTypeId']
        #print(SP2ID)
        SP3ID = psmResponse['data']['GetProductInstance']['products'][2]['productInstanceId']
        SP3TID = psmResponse['data']['GetProductInstance']['products'][2]['productTypeId']
        #print(SP3ID)
        SP4ID = psmResponse['data']['GetProductInstance']['products'][3]['productInstanceId']
        SP4TID = psmResponse['data']['GetProductInstance']['products'][3]['productTypeId']
        #print(SP4ID)
        SP5ID = psmResponse['data']['GetProductInstance']['products'][4]['productInstanceId']
        SP5TID = psmResponse['data']['GetProductInstance']['products'][4]['productTypeId']

        SSP5S1ID = psmResponse['data']['GetProductInstance']['products'][4]['products'][0]['productInstanceId']
        SSP5S1TID = psmResponse['data']['GetProductInstance']['products'][4]['products'][0]['productTypeId']
        SSP5S2ID = psmResponse['data']['GetProductInstance']['products'][4]['products'][1]['productInstanceId']
        SSP5S2TID = psmResponse['data']['GetProductInstance']['products'][4]['products'][1]['productTypeId']
        #print(SSP5S1ID)
        #print(SSP5S1TID)
        pom2psm_dict = {HLPTID:HLPID, SP1TID:SP1ID, SSP1TID:SSP1ID, SP2TID:SP2ID, SP3TID:SP3ID, SP4TID:SP4ID, SP5TID:SP5ID, SSP5S1TID:SSP5S1ID, SSP5S1TID:SSP5S1ID, SSP5S2TID:SSP5S2ID}
        print(pom2psm_dict)
        return True, pom2psm_dict


def usePsmApi(apiMethod,*argv):
    funcName = sys._getframe().f_code.co_name
    psmApi = PSM_API_LIB()
    if apiMethod=='requestUpsertCharacteristics':
        result = psmApi.requestUpsertCharacteristics(argv[0],argv[1],argv[2])
    elif apiMethod=='requestProductInstanceLifecycleStateChange':
        result = psmApi.requestProductInstanceLifecycleStateChange(argv[0],argv[1])
    elif apiMethod=='getProductInstanceEvents':
        result = psmApi.getProductInstanceEvents(argv[0])
    elif apiMethod=='insertProductInstanceRelationship':
        result = psmApi.insertProductInstanceRelationship(argv[0],argv[1],argv[2])
    else:
       result = getattr(psmApi,apiMethod)(argv[0])

    return result
if __name__ == "__main__":
    psm = PSM_API_LIB()
    result = psm.getProductInstanceForFOWithRelnId('72dd6563-7fdf-4202-9cc7-f80b1da2ad90')
    print(str(result))