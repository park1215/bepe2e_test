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
import cms_parameters
from robot.api import logger


class CMS_API_LIB:
    def getToken(self):
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        try:
            status, token = comBep.getBepJwtToken(cms_parameters.CMS_JWT_URL)
            if status == 200:
                return True, token
        except Exception as e:
            return False, funcName + ": Unable to retrieve CMS API token: " + str(e)

    def createContractInstance(self, contractInstanceId, customerId, firstName, lastName, phone, email, addressLine1, addressLine2, contractTemplateId, inviteSigner):
        funcName = sys._getframe().f_code.co_name
        url = cms_parameters.CMS_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1], {}, False)
        logger.info("header is:")
        logger.info(header)
        str_inviteSigner = str(inviteSigner)
        str_inviteSigner = str_inviteSigner.replace("'", "")
        logger.info("inputs are:")
        logger.info(firstName)
        logger.info(contractTemplateId)
        logger.info(phone)
        logger.info(email)
        logger.info(addressLine1)
        logger.info(addressLine2)
        payload = {"query":"mutation {\ncreateContractInstance(\n  contractId: \"" + contractInstanceId + "\", \n  customerId: \"" + customerId + "\", \n  productInstanceId: \"56785678\", \n  firstName: \"" + firstName + "\", \n  lastName: \"" + lastName + "\",\n  phoneNumber: \"" + phone + "\",\n  email: \"" + email + "\",\n  addressLine1: \"" + addressLine1 + "\", \n  addressLine2: \"" + addressLine2 + "\",\n  contractTemplateId: \"" + contractTemplateId + "\", \n  inviteSigner: " + str_inviteSigner + ")\n }\n \n\n "}
        logger.info(payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = ' + str(r.status_code))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + ":Error calling createContractInstance CMS Endpoint, Error --> " + str(e)

    def getContractInstance(self, contractInstanceId):
        funcName = sys._getframe().f_code.co_name
        url = cms_parameters.CMS_PP_URL
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1], {}, False)
        logger.info("header is:")
        logger.info(header)
        payload = {"query":"query {\ngetContractInstance(contractId:\"" + contractInstanceId + "\" ){\n signerUrl,\n signedStatus,\n dateCreated,\n dateModified\n}\n}\n\n"}
        logger.info(payload)
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            logger.console('status code = ' + str(r.status_code))
            if r.status_code == 200:
                response = json.loads(r.text)
                return True, response
            else:
                return False, r.status_code
        except Exception as e:
            logger.console('exception = ' + str(e))
            return False, funcName + ":Error calling createContractInstance CMS Endpoint, Error --> " + str(e)


def useCmsApi(apiMethod, *argv):
    funcName = sys._getframe().f_code.co_name
    cmsApi = CMS_API_LIB()
    if apiMethod == 'createContractInstance':
        result = cmsApi.createContractInstance(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9])
    elif apiMethod == 'getContractInstance':
        result = cmsApi.getContractInstance(argv[0])
    else:
        result = (False, funcName + " incorrect number of arguments for " + funcName)

    return result
