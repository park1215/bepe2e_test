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
import re
import ira_api
import bep_common
import ira_parameters
from robot.api import logger

class IRA_API_LIB:
    def getToken(self):
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        try:
            status, token = comBep.getBepJwtToken(ira_parameters.IRA_JWT_URL)
            if status == 200:
                return True, token
        except Exception as e:
            return False, funcName +": Unable to retrieve IRA API token: "+ str(e)

    def getParty(self, partyId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "{getParty(partyId: \""+partyId+"\" ){ ... on Individual { fullName partyId version } groups {groupName description} contactMethods {contactMethodId, notes, ... on EmailContactMethod {email} ... on PhoneContactMethod {phoneNumber} ... on AddressContactMethod {address{addressLines municipality region postalCode countryCode}}}}}"}
        #logger.console(payload)
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console(str(r.status_code))
            logger.console(r.text)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)

        except Exception as e:

            return False, funcName+":Error calling getParty IRA Endpoint, Error --> "+str(e)

    def getEmailContactMethodFromParty(self, partyId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "{getParty(partyId: \""+partyId+"\" ){ contactMethods {... on EmailContactMethod {contactMethodId email notes}}}}"}
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role}, True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                #print(r.status_code)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling getParty IRA Endpoint, Error --> "+str(e)


    def getPartyVersion(self, partyId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "{getParty(partyId: \""+partyId+"\" ){ version}}"}
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role}, True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                #print(r.status_code)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error retrieving partyVerion from getParty IRA Endpoint, Error --> "+str(e)

    def getPhoneContactMethodFromParty(self, partyId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "{getParty(partyId: \""+partyId+"\" ){ contactMethods {... on PhoneContactMethod {contactMethodId phoneNumber notes}}}}"}
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role}, True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                #print(r.status_code)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error retrieving phoneContact Method from getParty IRA Endpoint, Error --> "+str(e)

    def getAddressContactMethodFromParty(self, partyId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "{getParty(partyId: \""+partyId+"\" ){ contactMethods { ... on AddressContactMethod {contactMethodId address{addressLines municipality region postalCode countryCode} notes}}}}"}
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role}, True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                #print(r.status_code)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error retrieving phoneContact Method from getParty IRA Endpoint, Error --> "+str(e)

    def addIndividual(self, fullName, groups):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL 
        deDupId = str(uuid.uuid4())
        mutation = 'addIndividual(deduplicationId: \\"'+deDupId+'\\" ,fullName:\\"' + fullName + '\\",groups: [\\"'+groups+'\\"]){partyId, fullName, version, groups{groupName}}'
        payload = '{"query":"mutation{'+mutation+'}"}'
        logger.info(payload)
        #Get jwtToken
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]   
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling addIndividual IRA Endpoint, Status Code Error --> "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling addIndividual IRA Endpoint, Error --> "+str(e)

    def updateIndividual(self, partyId, updatedFullName):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "mutation {updateIndividual(partyId: \""+partyId+"\", fullName: \""+updatedFullName+"\"){partyId fullName, version, groups{groupName}}}"}
        #payload = ira_parameters.ADD_INDIVIDUAL_PAYLOAD
        logger.info(payload)
        #print(payload)
        #Get jwtToken
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling updateIndividual IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling updateIndividual IRA Endpoint, Error --> "+str(e)

    def addEmailContactMethod(self, partyId, emailAddress):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "mutation {addEmailContactMethod(partyId: \""+partyId+"\", email: \""+emailAddress+"\"){email}}"}
        logger.info(payload)
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling addEmailContactMethod IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling addEmailContactMethod IRA Endpoint, Error --> "+str(e)

    def addPhoneContactMethod(self, partyId, phoneNumber):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "mutation {addPhoneContactMethod(partyId: \""+partyId+"\", phoneNumber: \""+phoneNumber+"\"){phoneNumber}}"}
        #payload = ira_parameters.ADD_INDIVIDUAL_PAYLOAD
        #Get jwtToken
        logger.info(payload)
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling addPhoneContactMethod IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling addPhoneContactMethod IRA Endpoint, Error --> "+str(e)

    def addAddressContactMethod(self, partyId, addressLines, municipality, region, postalCode, countryCode):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        
        addressLine = str(addressLines)
        addressLine = addressLine[1:-1]
        addressLine = addressLine.replace("'",'"')
        
        if region != None:
            payload = {"query": "mutation {addAddressContactMethod(partyId: \""+partyId+"\", addressLines:["+ addressLine+"], municipality: \""+municipality+"\", region: \""+region+"\", postalCode: \""+postalCode+"\", countryCode: \""+countryCode+"\"){address{addressLines municipality region postalCode countryCode}}}"}
        else:
            payload = {"query": "mutation {addAddressContactMethod(partyId: \""+partyId+"\", addressLines:["+ addressLine+"], municipality: \""+municipality+"\", postalCode: \""+postalCode+"\", countryCode: \""+countryCode+"\"){address{addressLines municipality region postalCode countryCode}}}"}

        logger.info(payload)
        #Get jwtToken
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling addAddressContactMethod IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling addAddressContactMethod IRA Endpoint, Error --> "+str(e)

    def addCustomerRelationship(self, partyId, orgGroup, sellerOrgId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query": "mutation {addCustomerReln (groups: \""+orgGroup+"\", sellerId: \""+sellerOrgId+"\", customerId: \""+partyId+"\" ){relnId, version}}"}
        #payload = ira_parameters.ADD_INDIVIDUAL_PAYLOAD
        logger.info(payload)
        #Get jwtToken
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling addCustomerRelationship IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling addCustomerRelationship IRA Endpoint, Error --> "+str(e)

    def addCustomerInfo(self, partyId, emailId, addressLine, municipality, region, postalCode, countryCode, phone, externalIdTypeName, externalIdValue, orgGroup, sellerOrgId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        addressLine = str(addressLine)
        logger.console("addressLine="+addressLine)
        addressLine = addressLine[1:-1]
        addressLine = addressLine.replace("'",'\\"')
        payload = '{"query":"mutation {id1:addEmailContactMethod(partyId:\\"' + partyId +'\\", email:\\"' +emailId+'\\"){email} id2:addAddressContactMethod(partyId:\\"' + \
                   partyId +'\\", addressLines:[' + addressLine+ '], municipality:\\"' + municipality +'\\",'

        if region != '':
            payload = payload + 'region:\\"' + region +'\\",'

        payload = payload + \
         'postalCode:\\"' + \
            postalCode +'\\", countryCode:\\"' +countryCode +'\\"){address{addressLines municipality region postalCode countryCode}}id3:addPhoneContactMethod(partyId:\\"' + \
            partyId + '\\", phoneNumber:\\"' +phone +'\\"){phoneNumber}  id4:addExternalId(partyId:\\"' +partyId +'\\", typeName:\\"' +externalIdTypeName +'\\", value:\\"' + \
           externalIdValue + '\\"){value, type{typeName}} id5:addCustomerReln(groups:\\"' +orgGroup + '\\", sellerId:\\"' +sellerOrgId +'\\", customerId:\\"' +partyId +'\\"){relnId, version}}"}'

        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info("header is:")
        logger.info(header)
        bep_common.logAPI(url,str(header),payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                logger.info("return code is:")
                logger.info(r.status_code)
                return False, funcName+":Error calling addCustomerInfo IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling addCustomerInfo IRA Endpoint, Error --> "+str(e)

    def getRelationship(self, relnId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = '{"query":"{getRelationship(relnId: \\"'+relnId+'\\") { ...on CustomerReln{ relnId version groups {groupName}} roles{__typename partyRoleId  party {partyId  \
                  ...on Individual {fullName contactMethods{ ... on EmailContactMethod{email} ... on PhoneContactMethod{phoneNumber} \
                  ... on AddressContactMethod{address{postalCode}}}} }  version}}}"}'

        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role}, True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                return True, r.json()
            else:
                return False, funcName+":Error calling getRelationship IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling getRelationship IRA Endpoint, Error --> "+str(e)

    def addPayerRole(self, partyId, relnId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query":"mutation {\n  addPayerRole(\n    relnId: \""+relnId+"\"\n    label: \"Customer\"\n    notes: \"BEPE2E Customer\"\n    partyId: \""+partyId+"\"\n  ) {party{partyId} reln{relnId} partyRoleId label}}"}
        #payload = ira_parameters.ADD_INDIVIDUAL_PAYLOAD
        logger.info(payload)
        #Get jwtToken
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                return True, json.loads(r.text)
            else:
                return False, funcName+":Error calling addPayerRole IRA Endpoint, Error --> "+str(r.text)
        except Exception as e:
            return False, funcName+":Error calling addPayerRole IRA Endpoint, Error --> "+str(e)


    def getPartyByExternalId(self, externalId, typeName):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query":"{\n getPartyByExternalId(externalId: \"" + externalId + "\", typeName: \"" + typeName + "\") {\n externalIds {\n type {\n description\n pattern\n typeName\n }\n value\n}\n partyId\n groups {\n groupName\n }\n}\n}\n"}
        #logger.console(payload)
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role}, True)
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
            return False, funcName+":Error calling getPartyByExternalId IRA Endpoint, Error --> "+str(e)

    def addExternalId(self, partyId, typeName, value):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        mutation = 'addExternalId(partyId: \\"'+partyId+'\\",typeName: \\"'+typeName+'\\" ,value: \\"'+value+'\\"){value, type{typeName}}'
        payload = '{"query":"mutation{'+mutation+'}"}'
        #payload = {"query":"mutation  {\n addExternalId (partyId: \"" + partyId + "\", typeName:\"" + typeName + "\", value:\"" + value + "\")\n {\n value type {typeName}\n }\n}"}
        logger.info(payload)

        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        logger.info ("header is:")
        logger.info (header)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False,funcName + ":" + r.status_code
        except Exception as e:
            return False, funcName+":Error calling addExternalId IRA Endpoint, Error --> "+str(e)


    def deleteContactMethod(self, contactMethodId):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = {"query":"mutation { \n  deleteContactMethod (contactMethodId:\"" + contactMethodId + "\")\n}\n\n"}
        logger.info(payload)
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
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
            return False, funcName+":Error calling deleteContactMethod IRA Endpoint, Error --> "+str(e)
    
    def listRelationshipsByPartyId(self,partyIds):
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        
        relationships = {}
        payload = {}
        for partyIdEntry in partyIds:
            partyId = partyIdEntry['partyId']
            payload[partyId] = '{"query":"query {listRelationships(filter:{role:{partyId:\\"' + partyId +'\\"}}){items{relnId roles{partyRoleId  party{partyId} __typename}}}}"}'
            try:
                r = requests.post(url, headers=header, verify=False, data=payload[partyId])
                if r.status_code == 200:
                    items = r.json()['data']['listRelationships']['items']
                    for item in items:
                        relationships[partyId] = {}
                        relnId = item['relnId']
                        relationships[partyId][relnId] = {}
                        for role in item['roles']:                  
                            if role['party']['partyId'] == partyId:
                                relationships[partyId][relnId][role['__typename']]=role['partyRoleId']
                else:
                    relationships[partyId]['statusCode'] = r.status_code
            except Exception as e:
                relationships[partyId]['error'] = e
        return relationships
      
    def locatePartyByPhoneNumber(self, phoneNumber):
        funcName = sys._getframe().f_code.co_name
        role = ira_parameters.IRA_ROLE
        url = ira_parameters.IRA_PP_URL
        payload = '{"query":"query {partySearch(filter:{contactMethod:{phoneNumber:\\"' + phoneNumber + '\\"}}){results{partyId} }}"}'
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{'X-BEP-IRA-Role': '%s' %role},True)
        bep_common.logAPI(url,str(header),payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                try:
                    relationships = self.listRelationshipsByPartyId(r.json()['data']['partySearch']['results'])
                    return True,relationships
                except Exception as e:
                    return False, funcName+":Error calling " + funcName + " IRA Endpoint, Error --> "+str(e)
            else:
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling " + funcName + " IRA Endpoint, Error --> "+str(e)        
        

def useIraApi(apiMethod,*argv):
    funcName = sys._getframe().f_code.co_name
    iraApi = IRA_API_LIB()
    if len(argv)==1:
        result = getattr(iraApi,apiMethod)(argv[0])
    elif len(argv)==2:
        result = getattr(iraApi,apiMethod)(argv[0],argv[1])
    elif apiMethod=='addCustomerRelationship':
        result = iraApi.addCustomerRelationship(argv[0],argv[1],argv[2])
    elif apiMethod=='addAddressContactMethod':
        result = iraApi.addAddressContactMethod(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5])
    elif apiMethod=='addCustomerInfo':
        result = iraApi.addCustomerInfo(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],argv[8],argv[9],argv[10],argv[11])
    elif apiMethod=='addExternalId':
        result = iraApi.addExternalId(argv[0],argv[1],argv[2])
    else:
       result =  (False,funcName + " incorrect number of arguments for "+funcName)

    return result

if __name__ == "__main__":
    iraApi = IRA_API_LIB()
    #result = iraApi.locatePartyByPhoneNumber('+5231241656')
    result = iraApi.locatePartyByPhoneNumber('+34189719125')
    #result = spbApi.getBillingAccountData(sys.argv[1])
    print(str(result))
