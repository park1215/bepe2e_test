import urllib3
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
# urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
import secrets
import xmltodict
import time
import jaydebeapi
import sys
import json
import os
from robot.api import logger


class BO_API_Lib:
    # Reads in credentials from file
    def _readCreds(self):
        try:
            with open(self._realPath("../../python_libs/credentials.json")) as json_file:
                creds_json = json.load(json_file)
        except FileNotFoundError:
            print(os.getcwd())
            print("credential file not found")
            return False
        except Exception as e:
            print("Error, need to take a look:" + str(e))
            return False
        return creds_json

    # returns filename (which should include relative path from this file) preceded by path of this file
    def _realPath(self, filename):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)), filename)

    def doNothing(self):
        return 'nothing'

    # Reads in parameters  from file
    def _readParams(self):
        try:
            with open("parameters.json") as json_file:
                params_json = json.load(json_file)
        except FileNotFoundError:
            print("Parameter file not found")
            return False
        except Exception as e:
            print("Error, need to take a look")
            return False
        return params_json

    # At initialization generates information needed for security header
    def __init__(self, inputLog=False):
        # reads in credentials from credential file, if any of the passwords are not supplied, kill object
        creds_json = self._readCreds()
        if not creds_json:
            print("Error getting creds, killing and returning False")
            del self
            return
        # Initialize username and password used in requests, hardcoded for now
        self._user = creds_json["backofficeUser"]
        self._password = creds_json["backofficePass"]
        # Generate Nonce
        generatedNonce = secrets.token_urlsafe(16)
        self._completeNonce = generatedNonce + "=="
        # Generate TimestampID
        idTimestamp = secrets.token_hex(17)
        idTimestamp = idTimestamp[:-1]
        self._idTimestamp = "TS-" + idTimestamp.upper()
        # Generate UserTokenID
        idUserToken = hex(int(idTimestamp, base=16) + 1)
        idUserToken = idUserToken[2:35]
        self._idUserToken = "UsernameToken-" + idUserToken.upper()
        # Generate epoch time in milliseconds
        epoch = time.time()
        self._epochMilli = int(round(epoch * 1000))
        # Generate current UTC Timestamp
        UTCTime = time.gmtime(epoch)
        self._currentUTCTime = time.strftime("%Y-%m-%dT%H:%M:%S", UTCTime) + "." + str(self._epochMilli)[-3:] + "Z"
        # Generate future UTC Timestamp
        UTCTimeExpire = time.gmtime(epoch + 5 * 60)
        self._futureUTCTime = time.strftime("%Y-%m-%dT%H:%M:%S", UTCTimeExpire) + "." + str(self._epochMilli)[-3:] + "Z"
        # Generate local time
        timeOutput = time.localtime()
        self._localTime = time.strftime("%Y-%m-%d:%I:%M:%S", timeOutput)
        # Suppress error message for insecurerequestwarning
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
        # Stores SDP user and password
        self._sdpUser = creds_json["sdpApiUser"]
        self._sdpPass = creds_json["sdpApiPass"]
        # Stores WB database creds
        self._wb_db_user = creds_json["wb_db_user"]
        self._wb_db_pass = creds_json["wb_db_pass"]
        # Stores RB Event Source database creds
        self._rb_db_user = creds_json["rb_db_user"]
        self._rb_db_pass = creds_json["rb_db_pass"]
        # Stores RB Event Source Admin database creds
        self._rb_db_admin_user = creds_json["rb_db_admin_user"]
        self._rb_db_admin_pass = creds_json["rb_db_admin_pass"]
        # Stores VB database creds
        self._vb_db_user = creds_json["vb_db_user"]
        self._vb_db_pass = creds_json["vb_db_pass"]
        # Holds JWT token for sdp calls
        self._jwtToken = ""
        # Indicates if input logging should be used
        self._inputLog = inputLog
        # Stores FSM datbase creds
        self._fsm_db_user = creds_json["fsm_db_user"]
        self._fsm_db_pass = creds_json["fsm_db_pass"]
        self._rb_db_ip = "rac02-qa-scan.test.wdc1.wildblue.net"
        self._rb_db_port = "1521"
        self._rb_db_sid = "vsqa11"
        self._rb_db_string = "@" + self._rb_db_ip + ":" + self._rb_db_port + ":" + self._rb_db_sid
        self._wb_db_ip = "rac02-qa-scan.test.wdc1.wildblue.net"
        self._wb_db_port = "1521"
        self._wb_db_sid = "wbat3"
        self._wb_db_string = "@" + self._wb_db_ip + ":" + self._wb_db_port + ":" + self._wb_db_sid
        self._vb_db_ip = "rac02-qa-scan.test.wdc1.wildblue.net"
        self._vb_db_port = "1521"
        self._vb_db_sid = "vbst1"
        self._vb_db_string = "@" + self._vb_db_ip + ":" + self._vb_db_port + ":" + self._vb_db_sid

        # private function that constructs the wsse security header in a given payload. Currently only two versions of headers are supported

    def _generateHeader(self, inputDict):
        # print(inputDict['soapenv:Envelope']['soapenv:Header'])
        # checks which version of security header is being used on input
        if 'pws:wildBlueHeader' in inputDict['soapenv:Envelope']['soapenv:Header']:
            inputDict['soapenv:Envelope']['soapenv:Header']['pws:wildBlueHeader']['pws:invokedBy'][
                'pws:username'] = self._localTime
            inputDict['soapenv:Envelope']['soapenv:Header']['pws:wildBlueHeader']['pws:invokedBy'][
                'pws:application'] = self._epochMilli
        elif 'head:wildBlueHeader' in inputDict['soapenv:Envelope']['soapenv:Header']:
            inputDict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
                'head:username'] = self._localTime
            inputDict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
                'head:application'] = self._epochMilli
        else:
            print('wildBlueHeader DOES NOT exist')

        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsu:Timestamp']['@wsu:Id'] = self._idTimestamp
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsu:Timestamp'][
            'wsu:Created'] = self._currentUTCTime
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsu:Timestamp'][
            'wsu:Expires'] = self._futureUTCTime
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsse:UsernameToken'][
            '@wsu:Id'] = self._idUserToken
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsse:UsernameToken']['wsse:Nonce'][
            '#text'] = self._completeNonce
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsse:UsernameToken'][
            'wsu:Created'] = self._currentUTCTime
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsse:UsernameToken'][
            'wsse:Username'] = self._user
        inputDict['soapenv:Envelope']['soapenv:Header']['wsse:Security']['wsse:UsernameToken'][
            'wsse:Password'] = self._password
        return inputDict

    # private function, wrapper for printing to make logs more visible
    def _print_wrapper(self, data, header):
        topLine = "------------%s------------" % str(header)
        print(topLine)
        print(data)
        botLine = "-" * len(topLine)
        print(botLine + "\n")
        return

    def getMacHistory(self, serviceAgrRef):
        # initialize url and header variables
        url = 'https://fcd-provisioningrouter.test.wdc1.wildblue.net/ProvisioningFacade/v4/services/ProvisioningFacade'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"urn://#NewOperation"', 'Content-Length': '1572',
                  'Host': 'fcd-provisioningrouter.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/getMacHistoryTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['prov:getMacHistory'][
            'prov:serviceAgreementReference'] = serviceAgrRef
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        logger.console('before get mac history post body is : ' + str(body))
        logger.console('before get mac history post header is : ' + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request for mac history"}
        return output

    def addSoaRequest(self, systemID, transactionTypeName, externalTransactionReference):
        # initialize url and header variables
        url = 'https://iws-businesstransaction.test.wdc1.wildblue.net/BusinessTransactionWebService/v4/services/BusinessTransactionService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2106', 'Host': 'iws-businesstransaction.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/addSoaRequestTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaRequest']['externalSystemName'] = systemID
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaRequest'][
            'externalTransactionReference'] = externalTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaRequest'][
            'transactionTypeName'] = transactionTypeName
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request addSoaRequest"}
        return output

    def addSoaTransaction(self, transactionTypeName, systemID, salesChannel, soaRequestId, externalTransactionReference,
                          extServiceAgrRef):
        # initialize url and header variables
        url = 'https://iws-businesstransaction.test.wdc1.wildblue.net/BusinessTransactionWebService/v4/services/BusinessTransactionService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2106', 'Host': 'iws-businesstransaction.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/addSoaTransactionTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaTransaction'][
            'transactionTypeName'] = transactionTypeName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaTransaction'][
            'externalSystemName'] = systemID
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaTransaction'][
            'salesChannelName'] = salesChannel
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaTransaction'][
            'soaRequestId'] = soaRequestId
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaTransaction'][
            'externalTransactionReference'] = externalTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:addSoaTransaction'][
            'externalServiceAgreementReference'] = extServiceAgrRef
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request addSoaTransaction"}
        return output

    def updateSoaTransaction(self, soaTransactionReference, transactionStatusName):
        # initialize url and header variables
        url = 'https://iws-businesstransaction.test.wdc1.wildblue.net/BusinessTransactionWebService/v4/services/BusinessTransactionService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2106', 'Host': 'iws-businesstransaction.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/updateSoaTransactionTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:updateSoaTransaction'][
            'soaTransactionReference'] = soaTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:updateSoaTransaction'][
            'transactionStatusName'] = transactionStatusName
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request updateSoaTransaction"}
        return output

    def updateSubscriberProfile(self, soaTransactionReference, serviceAgrRef, oldMacAddress, macAddr):
        # initialize url and header variables
        url = 'https://iws-subscriberprofile.test.wdc1.wildblue.net/InternalWebService-SubscriberProfile/services/SubscriberProfileService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2106', 'Host': 'iws-subscriberprofile.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/updateSubscriberProfileTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:updateSubscriberProfile'][
            'transactionReference'] = soaTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:updateSubscriberProfile'][
            'subscriberProfile']['subscriberId'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:updateSubscriberProfile'][
            'subscriberProfile']['username'] = oldMacAddress
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:updateSubscriberProfile']['newUsername'] = macAddr
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request updateSubscriberProfile"}
        return output

    def modemSwap(self, soaTransactionReference, serviceAgrRef, oldMacAddress, macAddr):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter.test.wdc1.wildblue.net/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.wildblue.viasat.com/WSDL/v1.0/ServiceActivationFacade/modemSwap"',
                  'Content-Length': '2106', 'Host': 'fcd-serviceactivationrouter.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/modemSwapTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:modemSwap'][
            'ser:transactionReference'] = soaTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:modemSwap'][
            'ser:serviceAgreementReference'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:modemSwap'][
            'ser:oldModemMacAddress'] = oldMacAddress
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:modemSwap'][
            'ser:newModemMacAddress'] = macAddr
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request modemSwap"}
        return output

    def equipmentSwap(self, soaTransactionReference, soaRequestId, serviceAgrRef, oldMacAddress, newMACAddress):
        # initialize url and header variables
        url = 'http://soa01.test.wdc1.wildblue.net:10151/soa-infra/services/default/EquipmentSwap/equipmentswapvalidation_client_ep'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"process"',
                  'Content-Length': '1008', 'Host': 'soa01.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}

        # get payload template and generate security header
        with open(self._realPath('templates/equipmentSwapTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['equ:process'][
            'equ:externalTransactionReference'] = soaTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['equ:process'][
            'equ:soaTransactionReference'] = soaTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['equ:process'][
            'equ:soaRequestId'] = soaRequestId
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['equ:process'][
            'equ:serviceAgreementReference'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['equ:process'][
            'equ:oldMACAddress'] = oldMacAddress
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['equ:process'][
            'equ:newMACAddress'] = newMACAddress
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            logger.info(r)
            logger.console(r)
        except Exception as e:
            output = {"error": "Could not complete request equipmentSwap"}
        return output

    ###
    ### API CALLS FOR ACCOUNT CREATION
    ###

    def getServiceAvailability(self, postalCode, city, state, address, salesChannel, countryCode):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/PublicServiceAvailability/v2/services/PublicServiceAvailabilityService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2106', 'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/getServiceAvailabilityTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getServiceAvailability']['pub:location']['Address'][
            'postalCode'] = postalCode
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getServiceAvailability']['pub:location']['Address'][
            'municipality'] = city
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getServiceAvailability']['pub:location']['Address'][
            'region'] = state
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getServiceAvailability']['pub:location']['Address'][
            'addressLine'] = address
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getServiceAvailability'][
            'pub:salesChannel'] = salesChannel
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getServiceAvailability']['pub:location']['Address']['countryCode'] = countryCode

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        logger.info("BODY:" + str(body))
        logger.info("HEADER:" + str(header))
        try:
            r = requests.post(url, data=body, headers=header)
            output = xmltodict.parse(r.text)
            logger.info(r)
        except Exception as e:
            output = {"error": "Could not complete request for service availability"}
        return output

    def getPackages(self, salesChannel, customerType, transactionType, beamNumber, satelliteName, geoLat, geoLong,
                    countryCode):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/PublicCatalogService/v2/services/PublicCatalogService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2202', 'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/getPackagesTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # puts inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier'][
            'cat:salesChannel'] = salesChannel
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier'][
            'cat:customerType'] = customerType
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier'][
            'cat:transactionType'] = transactionType
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier'][
            'cat:beamNumber'] = beamNumber
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier'][
            'cat:satelliteName'] = satelliteName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier']['cat:location'][
            'GeoPosition']['latitude'] = geoLat
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier']['cat:location'][
            'GeoPosition']['longitude'] = geoLong
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getPackages']['cat:qualifier']['cat:location'][
            'Address']['countryCode'] = countryCode

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        try:
            r = requests.post(url, data=body, headers=header)
            output = xmltodict.parse(r.text)
        except Exception as e:
            logger.error("error getting packages: " + str(e))
            output = False
        return output

    def getComponents(self, masterCatalogReferences):
        # initialize url and header variables
        url = 'https://fcd-catalog.test.wdc1.wildblue.net/Facade-Catalog/v1/services/CatalogService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1971', 'Host': 'fcd-catalog.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template and generate security header
        with open(self._realPath('templates/getComponentsTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v1:getComponents']['v1:masterCatalogReference'].extend(
            masterCatalogReferences)

        # print(bodyTemplate_dict)
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def suspendAccountRequest(self, requestor, sourceSystemID, systemID, orderReference, orderSoldBy,
                              startDate, accountReference):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/XMLAgent/request'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml', 'Content-Length': '5195',
                  'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/suspendAccountRequestTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['Request']['Requestor'] = requestor
        bodyTemplate_dict['Request']['Transaction']['SourceSystemID'] = sourceSystemID
        bodyTemplate_dict['Request']['Transaction']['SystemID'] = systemID
        bodyTemplate_dict['Request']['Transaction']['SuspendAccount']['OrderCommon']['OrderReference'] = orderReference
        bodyTemplate_dict['Request']['Transaction']['SuspendAccount']['OrderCommon']['SellerInfo'][
            'OrderSoldBy'] = orderSoldBy
        bodyTemplate_dict['Request']['Transaction']['SuspendAccount']['OrderCommon']['StartDate'] = startDate
        bodyTemplate_dict['Request']['Transaction']['SuspendAccount']['TargetAccount'] = accountReference
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request

        r = requests.post(url, data=body, headers=header)
        output = xmltodict.parse(r.text)
        self._print_wrapper(body, output)
        return output

    def resumeAccountRequest(self, requestor, sourceSystemID, systemID, orderReference, orderSoldBy,
                             startDate, accountReference):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/XMLAgent/request'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml', 'Content-Length': '5195',
                  'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/resumeAccountRequestTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['Request']['Requestor'] = requestor
        bodyTemplate_dict['Request']['Transaction']['SourceSystemID'] = sourceSystemID
        bodyTemplate_dict['Request']['Transaction']['SystemID'] = systemID
        bodyTemplate_dict['Request']['Transaction']['ResumeAccount']['OrderCommon']['OrderReference'] = orderReference
        bodyTemplate_dict['Request']['Transaction']['ResumeAccount']['OrderCommon']['SellerInfo'][
            'OrderSoldBy'] = orderSoldBy
        bodyTemplate_dict['Request']['Transaction']['ResumeAccount']['OrderCommon']['StartDate'] = startDate
        bodyTemplate_dict['Request']['Transaction']['ResumeAccount']['TargetAccount'] = accountReference
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request

        r = requests.post(url, data=body, headers=header)
        output = xmltodict.parse(r.text)
        self._print_wrapper(body, output)
        return output

    def addCustomerRequest(self, service, requestor, sourceSystemID, systemID, orderReference, trackingKey, orderSoldBy,
                           orderEnteredBy, startDate, customerReference, \
                           firstName, lastName, phoneDaytime, countryCode, address1, address2, city, state, zipcode, zip4, busName,
                           parentCustomerID, accountReference, \
                           accountType, salesChannel, one_time):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/XMLAgent/request'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml', 'Content-Length': '5195',
                  'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/addCustomerRequestTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['Request']['Requestor'] = requestor
        bodyTemplate_dict['Request']['Transaction']['SourceSystemID'] = sourceSystemID
        bodyTemplate_dict['Request']['Transaction']['SystemID'] = systemID
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['OrderCommon']['OrderReference'] = orderReference
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['OrderCommon']['trackingKey'] = trackingKey
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['OrderCommon']['SellerInfo'][
            'OrderSoldBy'] = orderSoldBy
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['OrderCommon']['SellerInfo'][
            'OrderEnteredBy'] = orderEnteredBy
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['OrderCommon']['StartDate'] = startDate
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo'][
            'CustomerReference'] = customerReference
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['Person'][
            'FirstName'] = firstName
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['Person'][
            'LastName'] = lastName
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo'][
            'PhoneDaytime'] = phoneDaytime
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address']['Country'] = countryCode
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address'][
            'Address1'] = address1
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address'][
            'Address2'] = address2
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address'][
            'City'] = city
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address'][
            'State'] = state
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address'][
            'ZipCode'] = zipcode
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['CustomerInfo']['Contact']['ContactInfo']['Address'][
            'Zip4'] = zip4
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['AccountReference'] = accountReference
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['AccountType'] = accountType
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['SalesChannel'] = salesChannel
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address']['Country'] = countryCode
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address'][
            'Address1'] = address1
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address'][
            'Address2'] = address2
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address'][
            'City'] = city
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address'][
            'State'] = state
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address'][
            'ZipCode'] = zipcode
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['Address'][
            'Zip4'] = zip4
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['ContactPerson'][
            'FirstName'] = firstName
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['ContactPerson'][
            'LastName'] = lastName
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ServiceLocation']['ContactDetail'][
            'PhoneDaytime'] = phoneDaytime
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['Person'][
            'FirstName'] = firstName
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['Person'][
            'LastName'] = lastName
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'PhoneDaytime'] = phoneDaytime
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo']['Address']['Country'] = countryCode
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'Address']['Address1'] = address1
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'Address']['Address2'] = address2
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'Address']['City'] = city
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'Address']['State'] = state
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'Address']['ZipCode'] = zipcode
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['ShippingContact']['ContactInfo'][
            'Address']['Zip4'] = zip4
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['OnetimePayment']['Amount'] = one_time
        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['AccountInfo']['RecurringPayment'][
            'StartDate'] = startDate

        bodyTemplate_dict['Request']['Transaction']['AddCustomer']['Service'] = []
        serviceList = []
        for srv in service:
            tmp = xmltodict.parse(srv)
            bodyTemplate_dict['Request']['Transaction']['AddCustomer']['Service'].append(tmp['Service'])
            serviceList.append(tmp)
            # print(tmp['Service'])

        # print(xmltodict.unparse(bodyTemplate_dict, pretty=True))
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getSoaTransactionsByExtAccRef(self, externalSystemName, externalAccountReference):
        # initialize url and header variables
        url = 'https://iws-businesstransaction.test.wdc1.wildblue.net/BusinessTransactionWebService/v4/services/BusinessTransactionService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1704', 'Host': 'iws-businesstransaction.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        logger.info('inside getSoaTransactionsByExtAccRef')
        logger.info(externalSystemName)

        # get payload template
        with open(self._realPath('templates/getSoaTransactionsByExtAccRefTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)



        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:getSoaTransactionsByExternalAccountReference'][
            'externalSystemName'] = externalSystemName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:getSoaTransactionsByExternalAccountReference'][
            'externalAccountReference'] = externalAccountReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        logger.info('inside getSoaTransactionsByExtAccRef request is')
        logger.info(body)
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        logger.info('inside getSoaTransactionsByExtAccRef response is')
        logger.info(output)
        return output

    def executeOracleQuery(self, query, connection):
        curs = connection.cursor()
        curs.execute(query)
        output = curs.fetchall()
        curs.close()
        return output

    def queryWBA(self, systemID, orderReference):
        # initialize sql command
        sqlCommand = """Select e.EXTERNAL_SYSTEM As EXT_SYS, sc.SALES_CHANNEL As SALE_CH,
                          sct.SALES_CHANNEL_TYPE As SALE_CH_T, c.CUSTOMER_ID As CUST_ID,
                          ct.CUSTOMER_TYPE As CUST_TYPE, ctc.CUSTOMER_TYPE_CATEGORY As CUST_CATEGORY,
                          c.EXTERNAL_CUSTOMER_REF As CUST_REF, c.EXTERNAL_CUSTOMER_REF_SEQ As CUST_SQ,
                          a.ACCOUNT_ID As ACCT_ID, a.EXTERNAL_ACCOUNT_REF As EXT_ACCT_REF,
                          a.EXTERNAL_ACCOUNT_REF_SEQ As ACCT_SQ, s.SERVICE_AGREEMENT_ID As SVC_AGR_ID,
                          dvp.DEVICE_PLATFORM As DEV_PLATFORM, s.EXTERNAL_SVC_AGREEMENT_REF As
                          EXT_SVC_AGR_REF, s.EXTERNAL_SVC_AGREEMENT_REF_SEQ As SVC_AGR_SQ,
                          s.SALES_CHANNEL_AGENT_ID As SVC_AGR_SC_AGENT_ID, sau.SALES_CHANNEL_AGENT_ID As
                          SC_AGENT_ID, t.SOLD_BY As SOLD_BY
                        From wb_data_owner.external_system e Inner Join
                          wb_data_owner.customer_ref_map c On c.EXTERNAL_SYSTEM_ID = e.EXTERNAL_SYSTEM_ID
                          Left Outer Join
                          wb_data_owner.transaction t On c.EXTERNAL_CUSTOMER_REF = t.EXTERNAL_CUSTOMER_REF And
                            c.EXTERNAL_SYSTEM_ID = t.EXTERNAL_SYSTEM_ID And
                            c.EXTERNAL_CUSTOMER_REF_SEQ = t.EXTERNAL_TRANSACTION_REF_SEQ And
                            t.TRANSACTION_TYPE_ID In (4, 5, 6) Left Outer Join
                          wb_data_owner.sales_agent_user sau On UPPER(t.SOLD_BY) = UPPER(sau.USERNAME) Inner Join
                          wb_data_owner.account_ref_map a On a.CUSTOMER_ID = c.CUSTOMER_ID Inner Join
                          wb_data_owner.service_agreement_ref_map s On s.ACCOUNT_ID = a.ACCOUNT_ID Inner Join
                          wb_data_owner.device_platform dvp On dvp.DEVICE_PLATFORM_ID = s.DEVICE_PLATFORM_ID
                          Inner Join
                          wb_data_owner.sales_channel sc On sc.SALES_CHANNEL_ID = s.SALES_CHANNEL_ID Inner Join
                          wb_data_owner.sales_channel_type sct On sct.SALES_CHANNEL_TYPE_ID = sc.SALES_CHANNEL_TYPE_ID
                          Inner Join
                          wb_data_owner.customer_type ct On ct.CUSTOMER_TYPE_ID = c.CUSTOMER_TYPE_ID Inner Join
                          wb_data_owner.customer_type_category ctc On ctc.CUSTOMER_TYPE_CATEGORY_ID =
                            ct.CUSTOMER_TYPE_CATEGORY_ID
                        Where
                          e.EXTERNAL_SYSTEM =
                          '%s'
                          And
                          a.EXTERNAL_ACCOUNT_REF =
                          '%s'
                        Order By 9, 12, 15""" % (systemID, orderReference)

        # connect using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        return output

    def queryWBAforDeviceStatus(self, serviceAgreementId):
        # WARNING - order matters in output - counting on status being the 3rd item obtained
        sqlCommand = """SELECT DISTINCT sad.svc_agreement_device_id AS deviceId,
                    dt.device_type AS deviceType,
                    ds.device_status AS status,
                    dta2.attribute_value AS category,
                    dta.attribute_value AS tier,
                    dta1.attribute_value AS fsmEquipType,
                    sad.create_date,
                    sad.update_date,
                    sad.created_by,
                    sad.updated_by
                    FROM WB_DATA_OWNER.service_agreement_ref_map sarm
                    LEFT OUTER JOIN WB_DATA_OWNER.service_agreement_device sad
                    ON sarm.service_agreement_id = sad.service_agreement_id
                    LEFT OUTER JOIN WB_DATA_OWNER.device_type dt
                    ON sad.device_type_id = dt.device_type_id
                    LEFT OUTER JOIN WB_DATA_OWNER.device_status ds
                    ON sad.device_status_id = ds.device_status_id
                    LEFT OUTER JOIN WB_DATA_OWNER.device_type_attribute dta
                    ON dta.device_type_id = dt.device_type_id
                    AND dta.attribute_name = 'DEVICE_TIER'
                    LEFT OUTER JOIN WB_DATA_OWNER.device_type_attribute dta1
                    ON dta1.device_type_id = dt.device_type_id
                    AND dta1.attribute_name = 'FULFILLMENT_EQUIPMENT_TYPE'
                    LEFT OUTER JOIN WB_DATA_OWNER.device_type_attribute dta2
                    ON dta2.device_type_id = dt.device_type_id
                    AND dta2.attribute_name = 'DEVICE_CATEGORY'
                    WHERE sarm.SERVICE_AGREEMENT_ID = '%s'
                    ORDER BY category""" % (serviceAgreementId)
        # connect using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        print(output)
        results = {}
        for result in output:
            if 'MODEM' in result:
                results['MODEM'] = result[2]
            elif 'TRIA' in result:
                results['TRIA'] = result[2]
        return results

    def queryWBAforSuspendedAccountReference(self, systemID, salesChannel, extAcctStatsWith, modemType,
                                             no_of_days_active_account, plan):
        # WARNING - order matters in output - counting on status being the 3rd item obtained
        logger.console('inputs: ' + str(systemID) + " " + str(salesChannel) + " " + str(extAcctStatsWith) + " " + str(
            modemType) + " " + str(no_of_days_active_account) + " " + " " + str(plan))
        sqlCommand = """SELECT account_id,
                           external_account_ref,
                           external_system,
                           service_agreement_id,
                           EXTERNAL_SVC_AGREEMENT_REF,
                           customer_id,
                           external_customer_ref,
                           customer_type,
                           rate_name,
                           sales_channel,
                           device_status,
                           device_protocol,
                           create_date,
                           SUM(CASE WHEN transaction_type = 'newConnect' THEN 1 ELSE 0 END) AS new_connect,
                           SUM(CASE WHEN transaction_type = 'videoDataSaverOptionValue' THEN 1 ELSE 0 END) AS videoDataSaverOptionValue,
                           SUM(CASE WHEN transaction_type = 'suspendAllServiceAgreements' THEN 1 ELSE 0 END) AS suspendAllServiceAgreements,
                           SUM(CASE WHEN transaction_type = 'resumeAllServiceAgreements' THEN 1 ELSE 0 END) AS resumeAllServiceAgreements,
                           SUM(CASE WHEN transaction_type = 'disconnectAccount' THEN 1 ELSE 0 END) AS disconnectAccount
                    FROM (
                    SELECT DISTINCT arm.account_id,
                                    arm.external_account_ref,
                                    es.external_system,
                                    sarm.service_agreement_id,
                                    sarm.EXTERNAL_SVC_AGREEMENT_REF,
                                    crm.customer_id,
                                    crm.external_customer_ref,
                                    ct.customer_type,
                                    tcror.rate_name,
                                    sc.sales_channel,
                                    ds.DEVICE_STATUS,
                                    dp.DEVICE_PROTOCOL,
                                    tt.transaction_type,
                                    arm.create_date
                      from wb_data_owner.service_item_ref_map      sirm,
                           TRIBOLD_CATALOG_RPT_OWNER.RATE          tcror,
                           WB_DATA_OWNER.ACCOUNT_REF_MAP           arm,
                           WB_DATA_OWNER.SERVICE_AGREEMENT_REF_MAP sarm,
                           WB_DATA_OWNER.SERVICE_AGREEMENT_DEVICE  sad,
                           WB_DATA_OWNER.DEVICE_STATUS             ds,
                           WB_DATA_OWNER.DEVICE_PROTOCOL           dp,
                           WB_DATA_OWNER.DEVICE_PLATFORM           dplat,
                           wb_data_owner.sales_channel             sc,
                           wb_data_owner.transaction               t,
                           wb_data_owner.transaction_type          tt,
                           wb_data_owner.transaction_status        ts,
                           wb_data_owner.external_system           es,
                           WB_DATA_OWNER.CUSTOMER_REF_MAP          crm,
                           wb_data_owner.customer_type             ct      
                    --where sirm.service_agreement_id = '403025085'
                    where arm.EXTERNAL_ACCOUNT_REF LIKE '%s'
                       and sirm.service_agreement_id = sarm.service_agreement_id
                       and sirm.MASTER_CATALOG_REFERENCE = tcror.MASTER_CATALOG_REFERENCE
                       and sarm.ACCOUNT_ID = arm.ACCOUNT_ID
                       and sarm.service_agreement_id = sad.service_agreement_id
                       and arm.customer_id = crm.customer_id
                       and crm.customer_type_id = ct.customer_type_id   
                       and sarm.DEVICE_PLATFORM_ID = dplat.DEVICE_PLATFORM_ID
                       and dp.DEVICE_PROTOCOL_ID = dplat.DEVICE_PROTOCOL_ID
                       and sc.sales_channel = '%s'   
                       and ds.DEVICE_STATUS = 'ACTIVE'
                       and tcror.rate_name LIKE '%s'
                       and dp.device_protocol = '%s'
                       and es.external_system = '%s'
                       and arm.external_account_ref = t.external_account_ref
                       and t.transaction_type_id = tt.transaction_type_id
                       and t.transaction_status_id = ts.transaction_status_id
                       AND ts.transaction_status = 'COMPLETE'
                       and t.transaction_status_id = 6
                       AND t.external_system_id  = es.external_system_id
                       AND arm.create_date > sysdate - %s
                    )
                    GROUP BY account_id, 
                           external_account_ref,
                           external_system,
                           service_agreement_id,
                           EXTERNAL_SVC_AGREEMENT_REF,
                           customer_id,
                           external_customer_ref,
                           customer_type,
                           rate_name,
                           sales_channel,
                           device_status,
                           device_protocol,
                           create_date
                    HAVING SUM(CASE WHEN transaction_type = 'newConnect' THEN 1 ELSE 0 END) > 0
                    AND SUM(CASE WHEN transaction_type = 'videoDataSaverOptionValue' THEN 1 ELSE 0 END) > 0
                    AND SUM(CASE WHEN transaction_type = 'suspendAllServiceAgreements' THEN 1 ELSE 0 END) > 0
                    AND SUM(CASE WHEN transaction_type = 'resumeAllServiceAgreements' THEN 1 ELSE 0 END) = 0
                    AND SUM(CASE WHEN transaction_type = 'disconnectAccount' THEN 1 ELSE 0 END) = 0
                    ORDER BY dbms_random.value""" % (
        extAcctStatsWith, salesChannel, plan, modemType, systemID, no_of_days_active_account)
        # connect using jdbc library and run command

        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        return output[0]

    def queryWBAforInternalAccountReference(self, customerRelnId, productInstanceId):
        logger.console('inputs: ' + str(customerRelnId) + " " + str(productInstanceId))
        sqlCommand = """SELECT DISTINCT account_id
                        FROM (
                                SELECT DISTINCT
                                    arm.account_id,
                                    tt.transaction_type
                        FROM
                            wb_data_owner.service_item_ref_map sirm,
                            tribold_catalog_rpt_owner.rate tcror,
                            wb_data_owner.account_ref_map arm,
                            wb_data_owner.service_agreement_ref_map sarm,
                            wb_data_owner.service_agreement_device sad,
                            wb_data_owner.device_status ds,
                            wb_data_owner.device_protocol dp,
                            wb_data_owner.device_platform dplat,
                            wb_data_owner.sales_channel sc,
                            wb_data_owner.transaction t,
                            wb_data_owner.transaction_type tt,
                            wb_data_owner.transaction_status ts,
                            wb_data_owner.external_system es,
                            wb_data_owner.customer_ref_map crm,
                            wb_data_owner.customer_type ct
                        WHERE
                            sirm.service_agreement_id = sarm.service_agreement_id
                            AND sirm.master_catalog_reference = tcror.master_catalog_reference
                            AND sarm.account_id = arm.account_id
                            AND sarm.service_agreement_id = sad.service_agreement_id
                            AND arm.customer_id = crm.customer_id
                            AND crm.customer_type_id = ct.customer_type_id
                            AND sarm.device_platform_id = dplat.device_platform_id
                            AND dp.device_protocol_id = dplat.device_protocol_id
                            AND t.sales_channel_id = sc.sales_channel_id
                            AND arm.external_account_ref = t.external_account_ref
                            AND t.transaction_type_id = tt.transaction_type_id
                            AND t.transaction_status_id = ts.transaction_status_id
                            AND t.external_system_id = es.external_system_id
                            AND ds.device_status = 'ACTIVE'
                            AND arm.external_account_ref LIKE '%s'
                            AND t.external_transaction_ref = '%s'
                            AND ts.transaction_status = 'DISPATCHED'
                            )
                        GROUP BY
                            account_id
                        ORDER BY
                            dbms_random.value""" % (customerRelnId, productInstanceId)
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        return int(output[0][0])

    def queryWBAforActiveAccountReference(self, systemID, salesChannel, extAcctStatsWith, modemType, no_of_days_active_account, plan):
        # WARNING - order matters in output - counting on status being the 3rd item obtained
        logger.console('inputs: ' + str(systemID) + " " + str(salesChannel) + " " + str(extAcctStatsWith) + " " + str(
            modemType) + " " + str(no_of_days_active_account) + " " + " " + str(plan))
        sqlCommand = """SELECT DISTINCT account_id,
                        external_account_ref,
                       external_system,
                       service_agreement_id,
                       EXTERNAL_SVC_AGREEMENT_REF,
                       customer_id,
                       external_customer_ref,
                       customer_type,
                       rate_name,
                       sales_channel,
                       device_status,
                       device_protocol,
                       create_date,
                       SUM(CASE WHEN transaction_type = 'newConnect' THEN 1 ELSE 0 END) AS new_connect,
                       SUM(CASE WHEN transaction_type = 'disconnectAccount' THEN 1 ELSE 0 END) AS disconnectAccount,
                       SUM(CASE WHEN transaction_type = 'videoDataSaverOptionValue' THEN 1 ELSE 0 END) AS videoDataSaverOptionValue,
                       SUM(CASE WHEN transaction_type = 'suspendAllServiceAgreements' THEN 1 ELSE 0 END) AS suspendAllServiceAgreements,
                       SUM(CASE WHEN transaction_type = 'updateService' THEN 1 ELSE 0 END) AS updateService
                FROM (
                SELECT DISTINCT arm.account_id,
                                arm.external_account_ref,
                                es.external_system,
                                sarm.service_agreement_id,
                                sarm.EXTERNAL_SVC_AGREEMENT_REF,
                                crm.customer_id,
                                crm.external_customer_ref,
                                ct.customer_type,
                                tcror.rate_name,
                                sc.sales_channel,
                                ds.DEVICE_STATUS,
                                dp.DEVICE_PROTOCOL,
                                tt.transaction_type,
                                arm.create_date
                  from wb_data_owner.service_item_ref_map      sirm,
                       TRIBOLD_CATALOG_RPT_OWNER.RATE          tcror,
                       WB_DATA_OWNER.ACCOUNT_REF_MAP           arm,
                       WB_DATA_OWNER.SERVICE_AGREEMENT_REF_MAP sarm,
                       WB_DATA_OWNER.SERVICE_AGREEMENT_DEVICE  sad,
                       WB_DATA_OWNER.DEVICE_STATUS             ds,
                       WB_DATA_OWNER.DEVICE_PROTOCOL           dp,
                       WB_DATA_OWNER.DEVICE_PLATFORM           dplat,
                       wb_data_owner.sales_channel             sc,
                       wb_data_owner.transaction               t,
                       wb_data_owner.transaction_type          tt,
                       wb_data_owner.transaction_status        ts,
                       wb_data_owner.external_system           es,
                       WB_DATA_OWNER.CUSTOMER_REF_MAP          crm,
                       wb_data_owner.customer_type             ct
                --where sirm.service_agreement_id = '403029847'
                --bepe2e_56786578676
                where  sirm.service_agreement_id = sarm.service_agreement_id
                   and sirm.MASTER_CATALOG_REFERENCE = tcror.MASTER_CATALOG_REFERENCE
                   and sarm.ACCOUNT_ID = arm.ACCOUNT_ID
                   and sarm.service_agreement_id = sad.service_agreement_id
                   and arm.customer_id = crm.customer_id
                   and crm.customer_type_id = ct.customer_type_id   
                   and sarm.DEVICE_PLATFORM_ID = dplat.DEVICE_PLATFORM_ID
                   and dp.DEVICE_PROTOCOL_ID = dplat.DEVICE_PROTOCOL_ID
                   and ds.DEVICE_STATUS = 'ACTIVE'
                   and sc.sales_channel = '%s'
                   -- and sc.sales_channel = 'WB_DIRECT'
                   and arm.EXTERNAL_ACCOUNT_REF LIKE '%s'
                   and tcror.rate_name LIKE '%s'
                   --and sc.sales_channel = 'WB_DIRECT'
                   --and sc.sales_channel_type_id = 1
                   and dp.device_protocol = '%s'
                   and es.external_system = '%s'
                   and arm.external_account_ref = t.external_account_ref
                   and t.transaction_type_id = tt.transaction_type_id
                   and t.transaction_status_id = ts.transaction_status_id
                   AND ts.transaction_status = 'COMPLETE'
                   AND t.external_system_id  = es.external_system_id
                   --AND arm.create_date = sysdate - 24
                    AND arm.create_date > sysdate - %s
                )
                GROUP BY account_id, 
                       external_account_ref,
                       external_system,
                       service_agreement_id,
                       EXTERNAL_SVC_AGREEMENT_REF,
                       customer_id,
                       external_customer_ref,
                       customer_type,
                       rate_name,
                       sales_channel,
                       device_status,
                       device_protocol,
                       create_date
                HAVING SUM(CASE WHEN transaction_type = 'newConnect' THEN 1 ELSE 0 END) = 1
                AND SUM(CASE WHEN transaction_type = 'videoDataSaverOptionValue' THEN 1 ELSE 0 END) = 1
                AND SUM(CASE WHEN transaction_type = 'disconnectAccount' THEN 1 ELSE 0 END) < 1
                AND SUM(CASE WHEN transaction_type = 'suspendAllServiceAgreements' THEN 1 ELSE 0 END) < 1
                AND SUM(CASE WHEN transaction_type = 'updateService' THEN 1 ELSE 0 END) < 1
                ORDER BY dbms_random.value""" % (
            salesChannel, extAcctStatsWith, plan, modemType, systemID, no_of_days_active_account)
        # connect using jdbc library and run command

        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        return output[0]

    def queryVolubillAccountStatus(self, serviceAgreementId):
        sqlCommand = """SELECT
                        a.account_no AS acct_no,
                        sp.name AS provider,
                        a.id AS vb_account,
                        at.type,
                        DECODE(a.deleted,'N','Active','Y','Closed') AS acct_status,
                        ac.flexfield_str2 AS customer_code,
                        TO_CHAR(a.start_date,'YYYY-MM-DD HH24:MI:SS') AS start_date,
                        TO_CHAR(ac.registration_date,'YYYY-MM-DD HH24:MI:SS') AS registration_date,
                        abc.block_cause_comment,
                        TO_CHAR(abc.block_date,'YYYY-MM-DD HH24:MI:SS') AS block_date
                    FROM
                        dcp.account_vw a,
                        dcp.service_provider_vw sp,
                        dcp.account_customer ac,
                        dcp.enum_account_type at,
                        dcp.account_block_cause abc
                    WHERE
                        a.account_type = at.id
                        AND a.ispvn_id = sp.id
                        AND a.id = ac.account_id (+)
                        AND a.id = abc.account_id (+)
                        AND a.account_no = '%s'""" % (serviceAgreementId)
        # connect using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._vb_db_user + "/" + self._vb_db_pass + self._vb_db_string,
                                  [self._vb_db_user, self._vb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()
        curs.close()
        conn.close()
        # print(output)
        return output[0]

    def queryVolubillProductStatus(self, serviceAgreementId):
        sqlCommand = """SELECT *
                              FROM (SELECT a.account_no,
                                           sc.id AS svc_sub_id,
                                           MAX(csv.string_value) AS svc_item_ref,
                                           cs.name AS commerc_svc,
                                           ps.id AS prod_sub_id,
                                           p.name AS product,
                                           DECODE(ps.usage_state,
                                                  1,
                                                  'NEW',
                                                  2,
                                                  'ACTIVE',
                                                  3,
                                                  'CLOSED',
                                                  4,
                                                  'BLOCKED',
                                                  '???-UNKNOWN') AS product_status,
                                           MIN(TO_CHAR(csv.timestamp_value, 'YYYY-MM-DD HH24:MI:SS')) AS create_dt,
                                           MAX(TO_CHAR(csv.timestamp_value, 'YYYY-MM-DD HH24:MI:SS')) AS update_dt,
                                           DECODE(sne.state, '01', 'PENDING', '03', 'HANDLED') AS ne_prov_status,
                                           MIN(TO_CHAR(sne.activation_time, 'YYYY-MM-DD HH24:MI:SS')) AS ne_activation_time,
                                           MIN(TO_CHAR(sne.completion_time, 'YYYY-MM-DD HH24:MI:SS')) AS ne_completion_time,
                                           vac.clid AS active_MAC,
                                           usv.string_value AS registered_MAC,
                                           MAX(TO_CHAR(cbc.block_date, 'YYYY-MM-DD HH24:MI:SS')) AS block_dt,
                                           MAX(ecbc.block_cause) AS block_cause,
                                           ROW_NUMBER() OVER(PARTITION BY a.account_no, cs.name ORDER BY DECODE(ps.usage_state, 2, 1, --ACTIVE
                                           4, 2, --SUSPENDED
                                           1, 3, --NEW
                                           3, 4), --TERMINATED
                                           ps.original_start_date DESC) rn
                                      FROM dcp.account_vw                a,
                                           dcp.product_subscription      ps,
                                           dcp.product                   p,
                                           dcp.cs_subscription_vw        sc,
                                           dcp.cs_subscription_value_vw  csv,
                                           dcp.sf_parameter              sfp,
                                           dcp.sf_parameter              sfp2,
                                           dcp.commercial_service        cs,
                                           dcp.css_network_element_vw    sne,
                                           dcp.css_block_cause           cbc,
                                           dcp.enum_css_block_cause      ecbc,
                                           vbs01.access_clid             vac,
                                           dcp.unique_subscription_value usv
                                     WHERE sc.product_subscription_id = ps.id
                                       AND sc.commercial_service_id = cs.id
                                       AND sc.id = csv.subscription_id
                                       AND csv.parameter_id = sfp.id(+)
                                       AND (sfp.name IN
                                           ('service_item_reference', 'ServiceItemReference', 'Date') OR
                                           (cs.name = 'LDAP' AND csv.string_value IS NULL))
                                       AND ps.product_id = p.id
                                       AND a.id = sc.owner_account_id
                                       AND sc.id = sne.cs_subscription_id(+)
                                       AND sc.id = cbc.cs_subscription_id(+)
                                       AND (cbc.block_cause_id =
                                           (SELECT MAX(cbc1.block_cause_id)
                                               FROM dcp.css_block_cause cbc1
                                              WHERE cbc1.cs_subscription_id = cbc.cs_subscription_id
                                              GROUP BY cbc1.cs_subscription_id) OR
                                           cbc.block_cause_id IS NULL)
                                       AND cbc.block_cause_id = ecbc.id(+)
                                       AND sc.id = vac.subscription_id(+)
                                       AND sc.id = usv.cs_subscription_id(+)
                                       AND usv.parameter_id(+) = 1000269
                                       AND a.account_no = '%s'
                                     GROUP BY a.account_no,
                                              ps.original_start_date,
                                              sc.id,
                                              cs.name,
                                              ps.id,
                                              p.name,
                                              ps.usage_state,
                                              sne.state,
                                              cbc.cs_subscription_id,
                                              vac.clid,
                                              usv.string_value)
                            WHERE rn = 1""" % (serviceAgreementId)
        # connect using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._vb_db_user + "/" + self._vb_db_pass + self._vb_db_string,
                                  [self._vb_db_user, self._vb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()
        curs.close()
        conn.close()
        # print(output)
        return output

    def queryWBAforAccountInfo(self, ntdID, deviceProtocol):
        # WARNING - order matters in output - counting on status being the 3rd item obtained
        logger.console('inputs: ' + str(ntdID) + " " + str(deviceProtocol))
        sqlCommand = """SELECT DISTINCT account_id,
                        external_account_ref,
                       external_system,
                       service_agreement_id,
                       EXTERNAL_SVC_AGREEMENT_REF,
                       customer_id,
                       external_customer_ref,
                       customer_type,
                       rate_name,
                       sales_channel,
                       device_status,
                       device_protocol,
                       create_date
                FROM (
                SELECT DISTINCT arm.account_id,
                                arm.external_account_ref,
                                es.external_system,
                                sarm.service_agreement_id,
                                sarm.EXTERNAL_SVC_AGREEMENT_REF,
                                crm.customer_id,
                                crm.external_customer_ref,
                                ct.customer_type,
                                tcror.rate_name,
                                sc.sales_channel,
                                ds.DEVICE_STATUS,
                                dp.DEVICE_PROTOCOL,
                                tt.transaction_type,
                                arm.create_date
                  from wb_data_owner.service_item_ref_map      sirm,
                       TRIBOLD_CATALOG_RPT_OWNER.RATE          tcror,
                       WB_DATA_OWNER.ACCOUNT_REF_MAP           arm,
                       WB_DATA_OWNER.SERVICE_AGREEMENT_REF_MAP sarm,
                       WB_DATA_OWNER.SERVICE_AGREEMENT_DEVICE  sad,
                       WB_DATA_OWNER.DEVICE_STATUS             ds,
                       WB_DATA_OWNER.DEVICE_PROTOCOL           dp,
                       WB_DATA_OWNER.DEVICE_PLATFORM           dplat,
                       wb_data_owner.sales_channel             sc,
                       wb_data_owner.transaction               t,
                       wb_data_owner.transaction_type          tt,
                       wb_data_owner.transaction_status        ts,
                       wb_data_owner.external_system           es,
                       WB_DATA_OWNER.CUSTOMER_REF_MAP          crm,
                       wb_data_owner.customer_type             ct
                where  sirm.service_agreement_id = sarm.service_agreement_id
                   and sirm.MASTER_CATALOG_REFERENCE = tcror.MASTER_CATALOG_REFERENCE
                   and sarm.ACCOUNT_ID = arm.ACCOUNT_ID
                   and sarm.service_agreement_id = sad.service_agreement_id
                   and arm.customer_id = crm.customer_id
                   and crm.customer_type_id = ct.customer_type_id   
                   and sarm.DEVICE_PLATFORM_ID = dplat.DEVICE_PLATFORM_ID
                   and dp.DEVICE_PROTOCOL_ID = dplat.DEVICE_PROTOCOL_ID
                   and sirm.service_agreement_id = '%s'
                   and ds.DEVICE_STATUS = 'ACTIVE'
                  -- and sc.sales_channel = 'WB_DIRECT'
                   and dp.device_protocol = '%s'
                   and arm.external_account_ref = t.external_account_ref
                   and t.transaction_type_id = tt.transaction_type_id
                   and t.transaction_status_id = ts.transaction_status_id
                   AND ts.transaction_status = 'COMPLETE'
                   AND t.external_system_id  = es.external_system_id
                )
                GROUP BY account_id, 
                       external_account_ref,
                       external_system,
                       service_agreement_id,
                       EXTERNAL_SVC_AGREEMENT_REF,
                       customer_id,
                       external_customer_ref,
                       customer_type,
                       rate_name,
                       sales_channel,
                       device_status,
                       device_protocol,
                       create_date
                ORDER BY create_date""" % (ntdID, deviceProtocol)
        # connect using jdbc library and run command

        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        row_count = len(output)
        logger.console('no of rows returned: ' + str(row_count))
        return output[0]

    def getRbCustomerFromAccount(self, accountReference):
        sqlCommand = """SELECT cu.customer_ref
                        FROM geneva_admin.customer cu,
                        geneva_admin.customertype cut,
                        geneva_admin.customerattributes ca,
                        geneva_admin.customercontract cc,
                        geneva_admin.custproductattrdetails cpad,
                        geneva_admin.account ac,
                        geneva_admin.accountattributes aa
                        WHERE cut.customer_type_id = cu.customer_type_id
                        AND ca.customer_ref = cu.customer_ref
                        AND cc.customer_ref(+) = cu.customer_ref
                        AND cu.customer_ref = cpad.customer_ref
                        AND LTRIM(cpad.attribute_value) = 'CONTRACT'
                        AND ac.customer_ref = cu.customer_ref
                        AND aa.account_num = ac.account_num
                        AND aa.account_reference = '%s'
                        UNION
                        SELECT cu.customer_ref
                        FROM geneva_admin.customer cu,
                        geneva_admin.customertype cut,
                        geneva_admin.customerattributes ca,
                        geneva_admin.customercontract cc,
                        geneva_admin.custproductattrdetails cpad,
                        geneva_admin.custproductattrdetails cpad1,
                        geneva_admin.productattribute pa,
                        geneva_admin.account ac,
                        geneva_admin.accountattributes aa
                        WHERE cut.customer_type_id = cu.customer_type_id
                        AND ca.customer_ref = cu.customer_ref
                        AND cc.customer_ref(+) = cu.customer_ref
                        AND cu.customer_ref = cpad.customer_ref(+)
                        AND LTRIM(cpad.attribute_value) = 'OPT_OUT_CONTRACT'
                        AND cpad1.customer_ref(+) = cpad.customer_ref
                        AND cpad1.product_seq(+) = cpad.product_seq
                        AND cpad1.product_attribute_subid = pa.product_attribute_subid(+)
                        AND pa.attribute_ua_name = 'OPT_OUT_REASON'
                        AND ac.customer_ref = cu.customer_ref
                        AND aa.account_num = ac.account_num
                        AND aa.account_reference = '%s'""" % (accountReference, accountReference)
        # connect using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._rb_db_user + "/" + self._rb_db_pass + self._rb_db_string,
                                  [self._rb_db_user, self._rb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        if len(output) > 0:
            result = output[0][0]
        else:
            result = ""
        return result

    def getAccountStatusFromCustomerRef(self, customerRef):
        sqlCommand = """select cps.product_status,cps.status_reason_txt,p.product_name,cps.product_seq,cps.effective_dtm 
        from geneva_admin.custproductstatus cps
        left outer join geneva_admin.custhasproduct chp
        ON chp.customer_ref = cps.customer_ref and chp.product_seq=cps.product_seq
        left outer join geneva_admin.product p
        on p.product_id=chp.product_id
        where  cps.customer_ref='%s'
        AND cps.effective_dtm = (
        SELECT
            MAX(cps2.effective_dtm) AS effective_date
        FROM
            geneva_admin.custproductstatus cps2
        WHERE
            cps2.customer_ref = cps.customer_ref
            AND cps.product_seq = cps2.product_seq
        )""" % (customerRef)
        # connect using jdbc library and run command

        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._rb_db_user + "/" + self._rb_db_pass + self._rb_db_string,
                                  [self._rb_db_user, self._rb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)

        output_dicts = []
        for product in output:
            prod = {}
            prod['status'] = product[0]
            prod['reason'] = product[1]
            prod['name'] = product[2]
            prod['sequence'] = product[3]
            prod['date'] = product[4]
            output_dicts.append(prod)
        conn.close()
        return output_dicts

    def getAccountHierarchy_SDP(self, accountReference):
        # initialize url and header variables
        url = 'https://fcd-provisioningrouter.test.wdc1.wildblue.net/ProvisioningFacade/v4/services/ProvisioningFacade'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"urn://#NewOperation"', 'Content-Length': '1572',
                  'Host': 'fcd-provisioningrouter.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getAccountHierarchy_SDPTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['prov:getAccountHierarchy'][
            'prov:accountReference'] = accountReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getAvailableInstallDates(self, fromDate, toDate, lat, long, postalCode, state, city, address,
                                 salesChannel, customerType):
        # initialize url and header variables
        url = 'https://api.test.exede.net/PublicWebService-Fulfillment/v1/services/PublicFulfillmentService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '2171', 'Host': 'api.test.exede.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getAvailableInstallDatesTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:fromDate'] = fromDate
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:toDate'] = toDate
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'GeoPosition']['latitude'] = lat
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'GeoPosition']['longitude'] = long
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'Address']['countryCode'] = country
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'Address']['postalCode'] = postalCode
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'Address']['region'] = state
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'Address']['municipality'] = city
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates']['pub:location'][
            'Address']['addressLine'] = address
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates'][
            'pub:salesChannel'] = salesChannel
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:getAvailableInstallDates'][
            'pub:customerType'] = customerType

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    # currently not being used and not finished for that reason
    def scheduleCustomerInstall(self, externalSystemName, externalAccountReference, externalOrderReference, fromDate,
                                toDate, externalTransactionReference):
        # initialize url and header variables
        url = 'https://api.test.exede.net/PublicWebService-Fulfillment/v1/services/PublicFulfillmentService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1715', 'Host': 'api.test.exede.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/scheduleCustomerInstallTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:scheduleCustomerInstall'][
            'pub:externalSystemName'] = externalSystemName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:scheduleCustomerInstall'][
            'pub:externalAccountReference'] = externalAccountReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:scheduleCustomerInstall'][
            'pub:externalOrderReference'] = externalOrderReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:scheduleCustomerInstall']['pub:scheduleDate'][
            'pub:fromDate'] = fromDate
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:scheduleCustomerInstall']['pub:scheduleDate'][
            'pub:toDate'] = toDate
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pub:scheduleCustomerInstall'][
            'pub:notes'] = externalTransactionReference
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        # print(bodyTemplate_dict)

    ###
    ### COMMANDS FOR PROVISIONING MODEM
    ###

    def registerModem(self, transactionReference, serviceAgrRef, beamNumber, satName, macAddr, lat, long, installerId,
                      timezone):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.wildblue.viasat.com/WSDL/v1.0/ServiceActivationFacade/registerModem"',
                  'Content-Length': '1996', 'Host': 'fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/registerModemTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem'][
            'ser:transactionReference'] = transactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem'][
            'ser:serviceAgreementReference'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:beamNumber'] = beamNumber
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:satelliteName'] = satName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:macAddress'] = macAddr
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:latitude'] = lat
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:longitude'] = long
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:installerId'] = installerId
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:registerModem']['ser:timezone'] = timezone

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    # need to update to not bypass that it is now
    def updateQoiResults(self, transactionReference, serviceAgrRef, qoiStatus, triaSerialNum):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.wildblue.viasat.com/WSDL/v1.0/ServiceActivationFacade/updateQOIResults"',
                  'Content-Length': '1773', 'Host': 'fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/updateQoiResultsTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:updateQOIResults'][
            'ser:transactionReference'] = transactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:updateQOIResults'][
            'ser:serviceAgreementReference'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:updateQOIResults']['ser:qoiStatus'] = qoiStatus
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:updateQOIResults'][
            'ser:triaSerialNumber'] = triaSerialNum

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def activateISP(self, transactionReference, serviceAgrRef):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.wildblue.viasat.com/WSDL/v1.0/ServiceActivationFacade/activateISP"',
                  'Content-Length': '1627', 'Host': 'fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/activateISPTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:activateISP'][
            'ser:transactionReference'] = transactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:activateISP'][
            'ser:serviceAgreementReference'] = serviceAgrRef

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def activateModemAccess(self, transactionReference, serviceAgrRef, device):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.wildblue.viasat.com/WSDL/v1.0/ServiceActivationFacade/activateModemAccess"',
                  'Content-Length': '1692', 'Host': 'fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/activateModemAccessTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:activateModemAccess'][
            'ser:transactionReference'] = transactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:activateModemAccess'][
            'ser:serviceAgreementReference'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:activateModemAccess']['ser:device'] = device

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    ###### need to verify that number is correct
    def provisioningComplete(self, transactionReference, serviceAgrRef, deviceInternalRef, deviceType, deviceName,
                             deviceStatus, serviceInternalRef, serviceType, serviceName, serviceStatus):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.wildblue.viasat.com/WSDL/v1.0/ServiceActivationFacade/provisioningComplete"',
                  'Content-Length': '2293', 'Host': 'fcd-serviceactivationrouter01.test.wdc1.wildblue.net:8443',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/provisioningCompleteTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete'][
            'ser:transactionReference'] = transactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete'][
            'ser:serviceAgreementReference'] = serviceAgrRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:deviceStatus'][
            'ser:internalReference'] = deviceInternalRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:deviceStatus'][
            'ser:type'] = deviceType
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:deviceStatus'][
            'ser:name'] = deviceName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:deviceStatus'][
            'ser:status'] = deviceStatus
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:serviceStatus'][
            'ser:internalReference'] = serviceInternalRef
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:serviceStatus'][
            'ser:type'] = serviceType
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:serviceStatus'][
            'ser:name'] = serviceName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:provisioningComplete']['ser:serviceStatus'][
            'ser:status'] = serviceStatus

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def resolveInstallation(self, macAddr, intAccRef):
        # initialize url and header variables
        url = 'https://fcd-serviceactivationrouter.test.wdc1.wildblue.net/Facade-ServiceActivationRouter/v1/services/ServiceActivationService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1541', 'Host': 'fcd-serviceactivationrouter.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/resolveInstallationTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:resolveInstallation'][
            'ser:modemMacAddress'] = macAddr
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['ser:resolveInstallation'][
            'ser:accountReference'] = intAccRef

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        output = xmltodict.parse(r.text)
        return output

    ###
    ### COMMANDS FOR TRANSITIONING SERVICE
    ###

    def getUserOrganization(self, username):
        # initialize url and header variables
        url = 'https://iws-authentication.test.wdc1.wildblue.net/AuthenticationWebService/services/Authentication/' + username + '/organization'
        r = requests.get(url, verify=False)
        output = xmltodict.parse(r.text)
        return output

    def findSubscriberBySearchCriteria(self, organization, username, subscriberUsername):
        # initialize url and header variables
        url = 'https://iws-subscribersearch.test.wdc1.wildblue.net/SubscriberSearch/v2/services/SubscriberSearchService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1541', 'Host': 'iws-subscribersearch.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/findSubscriberBySearchCriteriaTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:findSubscribersBySearchCriteria'][
            'sub:organization'] = organization
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:findSubscribersBySearchCriteria'][
            'sub:username'] = username
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['sub:findSubscribersBySearchCriteria'][
            'sub:referenceValue'] = subscriberUsername

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
        except Exception as e:
            logger.error('findSubscriberBySearchCriteria request error = ' + str(e))
            output = {"error": e}
        return output

    def getAllAccountServicesAndReferences(self, externalSystemName, externalReference):
        # initialize url and header variables
        url = 'https://pws-accountinfo01.test.wdc1.wildblue.net:8443/AccountInfoService/v3/services/AccountInfoService'
        # url = 'https://webservices.test.wildblue.net/AccountInfoService/v3/services/AccountInfoService'
        # header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
        # 'Content-Length': '1474', 'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
        # 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}

        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1474', 'Host': 'pws-accountinfo01.test.wdc1.wildblue.net:8443',
                  'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}

        # get payload template
        with open(self._realPath('templates/getAllAcctServAndRefTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v3:getAllAccountServicesAndReferences'][
            'v3:externalSubscriberIdentifier']['externalSystemName'] = externalSystemName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v3:getAllAccountServicesAndReferences'][
            'v3:externalSubscriberIdentifier']['externalReference'] = externalReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getTransitionPackages(self, externalSystemName, externalAccountReference):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/PublicCatalogService/v2/services/PublicCatalogService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1689', 'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getTransitionPackagesTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getTransitionPackages'][
            'cat:externalSystemName'] = externalSystemName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['cat:getTransitionPackages'][
            'cat:externalAccountReference'] = externalAccountReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def updateService(self, requestor, sourceSystemID, systemID, orderReference, orderSoldBy, orderEnteredBy, startDate,
                      targetAccount, servItemRef, targetServRef, displayName, priceType, packItemRef):

        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/XMLAgent/request'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml', 'Content-Length': '1446',
                  'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/updateServiceTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['Request']['Requestor'] = requestor
        bodyTemplate_dict['Request']['Transaction']['SourceSystemID'] = sourceSystemID
        bodyTemplate_dict['Request']['Transaction']['SystemID'] = systemID
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['OrderReference'] = orderReference
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['SellerInfo'][
            'OrderSoldBy'] = orderSoldBy
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['SellerInfo'][
            'OrderEnteredBy'] = orderEnteredBy
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['StartDate'] = startDate
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TargetAccount'] = targetAccount
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['From'][
            'TargetService'] = servItemRef
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['To'][
            'ServiceReference'] = targetServRef
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['To'][
            'Name'] = displayName
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['To'][
            'Type'] = priceType
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['To'][
            'CatalogNumber'] = packItemRef

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    '''
    def updateService(self, sourceSystemID, systemID, orderReference, orderSoldBy, orderEnteredBy, startDate,
                      targetAccount, targetServiceFrom, targetServiceTo):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/XMLAgent/request'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml', 'Content-Length': '1446',
                  'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}
        # get payload template
        with open(self._realPath('templates/updateServiceTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # put inputs into template
        bodyTemplate_dict['Request']['Transaction']['SourceSystemID'] = sourceSystemID
        bodyTemplate_dict['Request']['Transaction']['SystemID'] = systemID
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['OrderReference'] = orderReference
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['SellerInfo'][
            'OrderSoldBy'] = orderSoldBy
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['SellerInfo'][
            'OrderEnteredBy'] = orderEnteredBy
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['OrderCommon']['StartDate'] = startDate
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TargetAccount'] = targetAccount
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['From'][
            'TargetService'] = targetServiceFrom
        serviceTo_dict = xmltodict.parse(targetServiceTo)
        bodyTemplate_dict['Request']['Transaction']['UpdateService']['TransitionBaseService']['To'] = serviceTo_dict[
            'To']
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output
    '''

    ###
    ### DISCONNECTING ACCOUNT FROM MODEM
    ###


    def disconnectReasons(self, salesChannel):
        # initialize sql command
        sqlCommand = """select distinct
                        r.REASON as reason
                        from
                        wb_data_owner.SALES_CHANNEL sc,
                        wb_data_owner.TRANSACTION_TYPE tt,
                        wb_data_owner.TRANSACTION_TYPE_REASON ttr,
                        wb_data_owner.REASON r
                        where sc.sales_channel not in ('ATT', 'ENGINEERING_CHANNEL')
                        and sc.end_date > sysdate
                        and tt.end_date > sysdate
                        and sc.SALES_CHANNEL = '%s'
                        and tt.TRANSACTION_TYPE = 'disconnectAccount'
                        and sc.SALES_CHANNEL_ID = ttr.SALES_CHANNEL_ID
                        and tt.TRANSACTION_TYPE_ID = ttr.TRANSACTION_TYPE_ID
                        and r.REASON_ID = ttr.REASON_ID
                        ORDER BY DBMS_RANDOM.VALUE""" % salesChannel

        # connecting using jdbc library and running command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._wb_db_user + "/" + self._wb_db_pass + self._wb_db_string,
                                  [self._wb_db_user, self._wb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()
        curs.close()
        conn.close()
        # print(output)
        return output

    def disconnectRequest(self, transactionID, requestor, systemID, orderReference, orderSoldBy, startDate,
                          targetAccount, disconnectReason):
        # initialize url and header variables
        url = 'https://webservices.test.wildblue.net/XMLAgent/request'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xm', 'Content-Length': '1138',
                  'Host': 'webservices.test.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}
        # get payload template
        with open(self._realPath('templates/disconnectRequestTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header

        # put inputs into template
        bodyTemplate_dict['Request']['TransactionID'] = transactionID
        bodyTemplate_dict['Request']['Requestor'] = requestor
        bodyTemplate_dict['Request']['Transaction']['SystemID'] = systemID
        bodyTemplate_dict['Request']['Transaction']['DisconnectAccount']['OrderCommon'][
            'OrderReference'] = orderReference
        bodyTemplate_dict['Request']['Transaction']['DisconnectAccount']['OrderCommon']['SellerInfo'][
            'OrderSoldBy'] = orderSoldBy
        bodyTemplate_dict['Request']['Transaction']['DisconnectAccount']['OrderCommon']['StartDate'] = startDate
        bodyTemplate_dict['Request']['Transaction']['DisconnectAccount']['TargetAccount'] = targetAccount
        bodyTemplate_dict['Request']['Transaction']['DisconnectAccount']['DisconnectReason'] = disconnectReason

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getSoaTransactionsByExtRef(self, extSysName, extSoaTransRef):
        # initialize url and header variables
        url = 'https://iws-businesstransaction.test.wdc1.wildblue.net/BusinessTransactionWebService/v4/services/BusinessTransactionService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1685', 'Host': 'iws-businesstransaction.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getSoaTransByExtRefTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        bodyTemplate_dict = self._generateHeader(bodyTemplate_dict)
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:getSoaTransactionByExternalReference'][
            'externalSystemName'] = extSysName
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:getSoaTransactionByExternalReference'][
            'externalSoaTransactionReference'] = extSoaTransRef

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def ispStatusCheck(self, serviceAgreeID, transactionID):
        return

    ###
    ### MAC CLEANUP ###
    ###

    def queryRBEventSource(self, macAddr):
        # initialize sql command
        sqlCommand = """select * from geneva_admin.custeventsource ces
                        where ces.EVENT_SOURCE = '%s'""" % macAddr

        # connecting using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._rb_db_user + "/" + self._rb_db_pass + self._rb_db_string,
                                  [self._rb_db_user, self._rb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()
        curs.close()
        conn.close()
        # print(output)
        return output

    def deleteEventSource(self, macAddr):
        # initialize sql command
        sqlCommand = """delete from geneva_admin.custeventsource ces
                        where ces.EVENT_SOURCE = '%s'""" % macAddr

        # connecting using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._rb_db_admin_user + "/" + self._rb_db_admin_pass + self._rb_db_string,
                                  [self._rb_db_admin_user, self._rb_db_admin_pass],
                                  self._realPath("dependencies/ojdbc5.jar"))
        curs = conn.cursor()
        curs.execute(sqlCommand)
        # output = curs.fetchall()   #probably because has no return
        curs.close()
        conn.close()
        # print(output)
        return

    def commit(self):
        return

    def queryVBModem(self, macAddr):
        # initialize sql command
        sqlCommand = """select a.ACCOUNT_NO,usv.CS_SUBSCRIPTION_ID, usv.CS_SUBSCRIPTION_VALUE_ID, usv.STRING_VALUE
                        from DCP.UNIQUE_SUBSCRIPTION_VALUE usv
                        join DCP.CS_SUBSCRIPTION css ON css.ID = usv.CS_SUBSCRIPTION_ID
                        join DCP.ACCOUNT a ON a.ID = css.OWNER_ACCOUNT_ID
                        where USV.STRING_VALUE in  ('%s')""" % macAddr

        # connecting using jdbc library and run command
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._vb_db_user + "/" + self._vb_db_pass + "@rac02-qa-scan.test.wdc1.wildblue.net:1521:vbst03",
                                  [self._vb_db_user, self._vb_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()
        curs.close()
        conn.close()
        # print(output)
        return output

    def vbLogon(self, username, password):
        # initialize url and header variables
        url = 'http://10.67.90.61:8080/axis2/services/DCPCommon/'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"http://www.volubill.com/DCPCommonPort/logon"'}

        # get payload template
        with open(self._realPath('templates/vbLogonTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['soap:Envelope']['soap:Body']['ns2:logonRequest']['username'] = username
        bodyTemplate_dict['soap:Envelope']['soap:Body']['ns2:logonRequest']['password'] = password

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getProdSub(self, macAddr):

        return

    def terminateProdSub(self):
        return

    def vbLogoff(self):
        return

    def getCompleteConfigDoc(self):
        return "okay"

    def getSprSubs(self, networkKey, macAddr):
        # initialize url and header variables
        url = 'https://onsprapi.test.wdc1.wildblue.net/spr/OSSSPRAPIService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '353',
                  'Host': 'onsprapi.test.wdc1.wildblue.ne', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getSprSubsTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['spr:getSubscribers']['spr:networkkey'] = networkKey
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['spr:getSubscribers']['spr:username'] = macAddr

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getSprSubAttr(self, networkKey, subscriberKey):
        # initialize url and header variables
        url = 'https://onsprapi.test.wdc1.wildblue.net/spr/OSSSPRAPIService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '353',
                  'Host': 'onsprapi.test.wdc1.wildblue.ne', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getSprSubAttrTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['spr:getSubscriber']['spr:networkkey'] = networkKey
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['spr:getSubscriber']['spr:subscriberkey'] = subscriberKey

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        output = xmltodict.parse(r.text)
        # return r.text
        return output

    def getOpenetSubBalReq(self, subscriberId):
        # initialize url and header variables
        url = 'http://onpcrfapp.test.wdc1.wildblue.net:41700/axis_secure/services/BalanceManagementEAI'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '732',
                  'Host': 'onpcrfapp.test.wdc1.wildblue.net:41700', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}

        # get payload template
        with open(self._realPath('templates/getSubscriberBalanceRequestTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['eai:GetSubscriberBalancesRequest'][
            'subscriberId'] = subscriberId

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getOpenetSubscribers(self, subscriberId):
        # initialize url and header variables
        url = 'https://onsprapi.test.wdc1.wildblue.net/spr/OSSSPRAPIService?wsdl'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '732',
                  'Host': 'onpcrfapp.test.wdc1.wildblue.net:41700', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}

        # get payload template
        with open(self._realPath('templates/getSubscribersTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['spr:getSubscribers'][
            'spr:subscriberid'] = subscriberId

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def deleteOpenetSubscriber(self, subscriberKey):
        # initialize url and header variables
        url = 'https://onsprapi.test.wdc1.wildblue.net/spr/OSSSPRAPIService?wsdl'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '732',
                  'Host': 'onpcrfapp.test.wdc1.wildblue.net:41700', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}

        # get payload template
        with open(self._realPath('templates/deleteSubscriberTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['spr:deleteSubscriber'][
            'spr:subscriberkey'] = subscriberKey

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def policyDeleteSubscriber(self, acctNum):
        # initialize url and header variables
        url = 'https://provisionapi.test.wdc1.wildblue.net/InternalService-PolicyService/services/PolicyService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '346',
                  'Host': 'provisionapi.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}
        # get payload template
        with open(self._realPath('templates/policyDeleteSubscriberTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['pol:deleteSubscriberRequest'][
            'pol:subscriberId'] = acctNum
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)

        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def getJwtToken(self, user, password, SDPJwtName='exederes'):
        # initialize url
        #url = "https://jwt.us-or.viasat.io/v1/token?stripe=sdpapi-preprod&name=exederes"
        url = "https://jwt.us-or.viasat.io/v1/token?stripe=sdpapi-preprod&name=" + SDPJwtName
        logger.info("jwt_url is")
        logger.info(url)
        r = requests.get(url, verify=False, auth=(user, password))

        # print(r.text)
        return r.text

    def getCmtJwtToken(self, user, password):
        # initialize url
        url = "https://jwt.us-or.viasat.io/v1/token?stripe=cmt&name=user"
        r = requests.get(url, verify=False, auth=(user, password))

        # print(r.text)
        return r.text

    def sdpApiGetDevice(self, macAddr, name):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass, name)
        # initialize url and header
        logger.info("jwt token is:")
        logger.info(self._jwtToken)
        headers = {
            'Content-type': 'application/xml',
            'Authorization': 'Bearer %s' % self._jwtToken}
        url = "http://preprod-internal.sdpapi.viasat.io/Devices?filter=macAddress%3D%22" + macAddr + "%22"
        logger.info("url is: ")
        logger.info(url)
        try:
            r = requests.get(url, headers=headers)
            output = xmltodict.parse(r.text)
            logger.info("output is: ")
            logger.info(output)
            return True, output
        except Exception as e:
            return False, e


    def sdpApiGetDeviceBasedOnId(self, id, jwtName):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass, jwtName)
        # initialize url and header
        headers = {
            'Content-type': 'application/xml',
            'Authorization': 'Bearer %s' % self._jwtToken}
        url = "http://preprod-internal.sdpapi.viasat.io/Devices?filter=id%3D%22" + id + "%22"
        r = requests.get(url, headers=headers)

        output = xmltodict.parse(r.text)
        logger.info("input url in api")
        logger.info(url)
        logger.info("input header in api")
        logger.info(headers)
        logger.info("output in api")
        logger.info(output)
        return output

    def sdpApiGetService(self, serviceId):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/xml',
            'Authorization': 'Bearer %s' % self._jwtToken}
        url = 'http://preprod-internal.sdpapi.viasat.io/Services?filter=configuration.ntdId="' + serviceId + '"'
        r = requests.get(url, headers=headers)

        output = xmltodict.parse(r.text)
        return output

    def deactivateFixedNTD(self, targetId):  # target id is service agreement number
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header variables
        url = 'https://preprod-internal.sdpapi.viasat.io/Commands?'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml;charset=UTF-8',
                    'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)',
                    'Authorization': 'Bearer %s' % self._jwtToken}
        # get payload template
        with open(self._realPath('templates/deactivateFixedNtdTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header
        # put inputs into template
        bodyTemplate_dict['NewDeactivateFixedNTD']['targetId'] = targetId
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)

        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def newConfigureFixedNTD(self, targetId, latitude, longitude):  # target id is service agreement number
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header variables
        url = 'https://preprod-internal.sdpapi.viasat.io/Commands?'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'application/xml;charset=UTF-8',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)',
                  'Authorization': 'Bearer %s' % self._jwtToken}
        # get payload template
        with open(self._realPath('templates/newConfigureFixedNTD.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header
        # put inputs into template
        bodyTemplate_dict['NewConfigureFixedNTD']['targetId'] = targetId
        #bodyTemplate_dict['NewConfigureFixedNTD']['macAddress'] = macAddrMod
        bodyTemplate_dict['NewConfigureFixedNTD']['input']['latitude'] = latitude
        bodyTemplate_dict['NewConfigureFixedNTD']['input']['longitude'] = longitude
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        #self._print_wrapper(body, "INPUT")
        #logger.info("BODY: " + str(body))

        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def sdpApiTestHttpPerformance(self, modem, testType):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/json',
            'Authorization': 'Bearer %s' % self._jwtToken,
            'cache-control': "no-cache",
            'Accept-Encoding': "gzip,deflate",
            'Accept': 'application/xml'}
        url = "https://preprod-internal.sdpapi.viasat.io/Commands"
        payload = {"$type": "TestHttpPerformance", "macAddress": modem, "testType": testType}
        r = requests.post(url, data=json.dumps(payload), headers=headers, verify=False)
        # print(r.text)
        output = xmltodict.parse(r.text)
        return output

    def sdpApiCmdExecStatus(self, jobId):
        # Function takes successfully invoked jobId and returns true until status = completed with timeout of 60s
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            # 'Content-type': 'application/xml',
            'Authorization': 'Bearer %s' % self._jwtToken,
            # 'cache-control': "no-cache",
            'Accept-Encoding': "gzip,deflate",
            'Accept': 'application/xml'}
        url = "https://preprod-internal.sdpapi.viasat.io/Commands/" + jobId
        count = 0  # give 60s for successful execution
        while count < 12:
            print("Running Call: " + str(count))
            response = requests.get(url, headers=headers, verify=False)
            responseDict = xmltodict.parse(response.text)
            print(responseDict)
            if responseDict['TestHttpPerformance']['state'] == 'SUCCEEDED':
                rawspeed = int(responseDict['TestHttpPerformance']['maxBitsPerSec'])
                speedMB = rawspeed / 1048576
                print("The HTTP SPEED Test returned with Status: ")
                print (responseDict['TestHttpPerformance']['state'])
                return True, speedMB
            else:
                count += 1
                print("The HTTP SPEED Test returned with Status: ")
                print (responseDict['TestHttpPerformance']['state'])
                time.sleep(5)
        print("ERROR ! HTTP SPEED Test did not run successfully")
        return False, 0

    def ldapQuery(self, macAddr):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getCmtJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/json',
            'Authorization': 'Bearer %s' % self._jwtToken}
        # headers['Authorization'] = "Bearer %s" % token
        url = "https://api.pre.naw01.cmt.viasat.io/cpe_management/cpe/" + macAddr + "?filter=ldap"
        print (url)
        r = requests.get(url, headers=headers, verify=False)
        # output = xmltodict.parse(r.text)
        return r.text


    def getRealm(self, macAddr):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getCmtJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/json',
            'Authorization': 'Bearer %s' % self._jwtToken}
        # headers['Authorization'] = "Bearer %s" % token
        url = "https://api.pre.cmt.viasat.io/modems/" + macAddr + "/realm"
        logger.info(url)
        try:
            r = requests.get(url, headers=headers, verify=False)
            # output = xmltodict.parse(r.text)
            logger.info("output is")
            logger.info(r)
            return True, r.text
        except Exception as e:
            logger.info("exception in getRealm")
            logger.info(str(e))
            return False, str(e)

    def changeRealm(self, macAddr, newRealm):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getCmtJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/json',
            'Authorization': 'Bearer %s' % self._jwtToken}
        url = "https://api.pre.cmt.viasat.io/modems/" + macAddr + "/realm"
        payload = '{"realm":"'+newRealm+'"}'
        logger.info(url)
        try:
            r = requests.post(url, data=payload, headers=headers, verify=False)
            if r.status_code == 200:
                logger.info("output is")
                logger.info(r)
                return True, r.text
            else:
                logger.info("status code is other than 200 for change realm")
                return False, "status code = "+str(r.status_code)
        except Exception as e:
            logger.info("exception in changeRealm")
            logger.info(str(e))
            return False, str(e)

    def cmtApiCmdExecStatus(self, jobId):
        # Function takes successfully invoked jobId and returns true until status = completed with timeout of 60s
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getCmtJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/json',
            'Authorization': 'Bearer %s' % self._jwtToken}
        # headers['Authorization'] = "Bearer %s" % token
        url = "https://api.pre.naw01.cmt.viasat.io/cpe_management/" + jobId
        count = 0  # give 60s for successful execution
        while count < 6:
            print("Running Call: " + str(count))
            response = requests.get(url, headers=headers, verify=False)
            responseJson = json.loads(response.text)
            if responseJson['ldap_upgrade']['details'][0]['status_text'] == 'complete':
                print("Delete Successful Logical Beam status: ")
                print (responseJson['ldap_upgrade']['details'][0]['status_text'])
                return True
            else:
                count += 1
                print("LDAP CMT clear Logical Beam status: ")
                print (responseJson['ldap_upgrade']['details'][0]['status_text'])
                time.sleep(5)
        print("ERROR ! Beam ID clearing Job did not execute within 30s")
        return False

    def sdpConfigureFixedNTDCommandStatus(self, id):
        # Function takes successfully invoked jobId and returns true until status = completed with timeout of 60s
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            # 'Content-type': 'application/xml',
            'Authorization': 'Bearer %s' % self._jwtToken,
            # 'cache-control': "no-cache",
            'Accept-Encoding': "gzip,deflate",
            'Accept': 'application/xml'}
        url = "https://preprod-internal.sdpapi.viasat.io/Commands/" + id
        logger.info("The URL is: " + url)
        count = 0  # give 60s for successful execution
        while count < 12:
            print("Running Call: " + str(count))
            response = requests.get(url, headers=headers, verify=False)
            responseDict = xmltodict.parse(response.text)
            print(responseDict)
            state = responseDict['ConfigureFixedNTD']['state']
            if state == 'SUCCEEDED':
                print("The ConfigureFixedNTD Command Is In State: ")
                print(state)
                return True, state
            else:
                count += 1
                print("The ConfigureFixedNTD Command after 60s Was In State: ")
                print(state)
                time.sleep(5)
        print("ERROR ! The Command Was Not Successful after 60s")
        return False, state



    def cmtApiLogicalBeamDeletion(self, macAddr, payLoad):
        # checks if JWT token exists, if not generate and store in class
        if not self._jwtToken:
            self._jwtToken = self.getCmtJwtToken(self._sdpUser, self._sdpPass)
        # initialize url and header
        headers = {
            'Content-type': 'application/json',
            'Authorization': 'Bearer %s' % self._jwtToken}
        url = "https://api.pre.naw01.cmt.viasat.io/cpe_management"
        r = requests.post(url, data=json.dumps(payLoad), headers=headers, verify=False)

        return r.text

    ###
    ### Check the status of the FSM services ###
    ###
    def queryFSMCustomer(self, serviceAgreementId):
        # WARNING - order matters in output - counting on the token being item 4
        sqlCommand = """SELECT c.id AS fsm_cust_id, c.external_id_code AS service_agreement_id, s.NAME AS SALES_CHANNEL, c.account_number, c.token
                            FROM fsm.om_customer_t c
                           --JOIN fsm.om_customer_location_t cl ON c.ID = cl.customer_id
                           --JOIN fsm.su_address_t a ON cl.location_id = a.ID
                            JOIN fsm.dm_sales_channel_t s ON c.sales_channel_id = s.ID
                           --JOIN fsm.dm_states_t st ON a.states_id = st.ID
                            WHERE c.external_id_code = '%s'""" % (serviceAgreementId)
        conn = jaydebeapi.connect("oracle.jdbc.driver.OracleDriver",
                                  "jdbc:oracle:thin:" + self._fsm_db_user + "/" + self._fsm_db_pass + "@rac02-qa-scan.test.wdc1.wildblue.net:1521:fsm11t2",
                                  [self._fsm_db_user, self._fsm_db_pass], self._realPath("dependencies/ojdbc5.jar"))
        output = self.executeOracleQuery(sqlCommand, conn)
        conn.close()
        # print(output)
        results = {}
        for result in output:
            if serviceAgreementId in result:
                results['TOKEN'] = result[4]
        return results['TOKEN']

    def getFSMWorkOrderByCustomerToken(self, fsmCustomerToken):
        url = "https://apifsm4.test.wdc1.wildblue.net/fsm-integration/internal/v3/customer/" + fsmCustomerToken + "/workorder"
        headers = {'Accept': 'application/xml'}
        r = requests.get(url, headers=headers, verify=False)
        output = xmltodict.parse(r.text)
        return output

    def getServiceCallTypesByAccount(self, username, application, accountReference):
        # initialize url and header variables
        url = 'https://is-subscriberutilities.test.wdc1.wildblue.net/SubscriberUtilitiesService/v1/services/SubscriberUtilitiesSoapService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1541', 'Host': 'is-subscriberutilities.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getServiceCallTypesByAccountTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header

        # put inptus into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:username'] = username
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:application'] = application
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v1:getServiceCallTypesByAccount'][
            'v1:accountReference'] = accountReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")

        # make request
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            # print(output)
        except Exception as e:
            logger.error('getServiceCallTypesByAccount = ' + str(e))
            output = {"error": e}
        return output

    def addServiceCall(self, username, application, externalSystem, externalTransactionReference,
                       internalServiceAgreementReference, serviceCallType, notes, soldBy, enteredBy):
        # initialize url and header variables
        url = "http://soa01.test.wdc1.wildblue.net:10151/soa-infra/services/default/AddServiceCall!1.23.0-005*soa_1bbaa682-4ce4-49b5-a798-a9f902f2c0a1/AddServiceCallValidation_client_ep"
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1203', 'Host': 'soa01.test.wdc1.wildblue.net:10151', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/addServiceCallTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header

        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:username'] = username
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:application'] = application
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall'][
            'add:externalSystem'] = externalSystem
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall'][
            'add:externalTransactionReference'] = externalTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall'][
            'add:internalServiceAgreementReference'] = internalServiceAgreementReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall'][
            'add:serviceCallType'] = serviceCallType
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall']['add:notes'] = notes
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall']['add:soldBy'] = soldBy
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['add:addServiceCall']['add:enteredBy'] = enteredBy

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")

        # make request
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
        except Exception as e:
            logger.error('addServiceCall = ' + str(e))
            output = {"error": e}
        return output

    def getWorkOrder(self, workOrderReference):
        # initialize url and header variables
        url = 'https://fcd-fulfillment.test.wdc1.wildblue.net/Facade-Fulfillment/v4/services/Facade-Fulfillment'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Content-Length': '1541', 'Host': 'is-subscriberutilities.test.wdc1.wildblue.net',
                  'Connection': 'Keep-Alive', 'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}

        # get payload template
        with open(self._realPath('templates/getWorkOrderTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # bodyTemplate_dict = self._generateHeader(bodyTemplate_dict) #doesn't need security header

        # put inptus into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v4:getWorkOrder'][
            'v4:workOrderReference'] = workOrderReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")

        # make request
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            # print(output)
        except Exception as e:
            logger.error('getWorkOrder = ' + str(e))
            output = {"error": e}
        return output

    def cancelServiceCall(self, username, application, externalSystem, externalTransactionReference,
                          victimTransactionRef):
        print("----------TOP OF API----------")
        url = "http://soa01.test.wdc1.wildblue.net:10151/soa-infra/services/default/AddServiceCall!1.23.0-005*soa_1bbaa682-4ce4-49b5-a798-a9f902f2c0a1/CancelServiceCall_Client_ep"
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Host': 'soa01.test.wdc1.wildblue.net:10151', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}
        with open(self._realPath('templates/cancelServiceCallTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:username'] = username
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:application'] = application
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['can:process']['can:externalSystem'] = externalSystem
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['can:process'][
            'can:externalTransactionReference'] = externalTransactionReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['can:process'][
            'can:victimTransactionRef'] = victimTransactionRef

        print("---------BODY OF API-----------")
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")

        # make request
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            # print(output)
        except Exception as e:
            logger.error('cancelServiceCall = ' + str(e))
            output = {"error": e}
        return output

    def closeServiceCall(self, username, application, workOrderReference, transactionReference):
        print("----------TOP OF API----------")
        url = "http://soa01.test.wdc1.wildblue.net:10151/soa-infra/services/default/AddServiceCall!1.23.0-005*soa_1bbaa682-4ce4-49b5-a798-a9f902f2c0a1/CloseServiceCall_Client_ep"
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'SOAPAction': '""',
                  'Host': 'soa01.test.wdc1.wildblue.net:10151', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_144)'}
        with open(self._realPath('templates/closeServiceCallTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)
        # put inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:username'] = username
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:application'] = application
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['clos:process'][
            'clos:workOrderReference'] = workOrderReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['clos:process'][
            'clos:transactionReference'] = transactionReference

        print("---------BODY OF API-----------")
        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")

        # make request
        try:
            r = requests.post(url, data=body, headers=header, verify=False)
            output = xmltodict.parse(r.text)
            # print(output)
        except Exception as e:
            logger.error('closeServiceCall = ' + str(e))
            output = {"error": e}
        return output

    def getVideoDataSaverOption(self, serviceAgreementReference):
        # iniialize url and header variables
        url = 'https://is-subscriberutilities.test.wdc1.wildblue.net/SubscriberUtilitiesService/v1/services/SubscriberUtilitiesSoapService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8',
                  'SOAPAction': '"urn://#NewOperation"', 'Content-Length': '679',
                  'Host': 'is-subscriberutilities.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)'}
        # get payload template
        with open(self._realPath('templates/getVideoDataSaverOptionTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # puts inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:username'] = self._localTime
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:application'] = self._epochMilli
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v1:getVideoDataSaverOption'][
            'v1:serviceAgreementReference'] = serviceAgreementReference

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")
        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        output = xmltodict.parse(r.text)
        print(output)
        return output

    def updateVideoDataSaverOption(self, serviceAgreementReference, videoDataSaverOption):
        # iniialize url and header variables
        url = 'https://is-subscriberutilities.test.wdc1.wildblue.net/SubscriberUtilitiesService/v1/services/SubscriberUtilitiesSoapService'
        header = {'Accept-Encoding': 'gzip,deflate', 'content-type': 'text/xml;charset=UTF-8', 'Content-Length': '732',
                  'Host': 'is-subscriberutilities.test.wdc1.wildblue.net', 'Connection': 'Keep-Alive',
                  'User-Agent': 'Apache-HttpClient/4.5.2 (Java/1.8.0_162)', 'SOAPAction': '"urn://#NewOperation"'}

        with open(self._realPath('templates/updateVideoDataSaverOptionTemplate.xml')) as template:
            xml_template = template.read()
        bodyTemplate_dict = xmltodict.parse(xml_template)

        # puts inputs into template
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:username'] = self._localTime
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Header']['head:wildBlueHeader']['head:invokedBy'][
            'head:application'] = self._epochMilli
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v1:updateVideoDataSaverOption'][
            'v1:serviceAgreementReference'] = serviceAgreementReference
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v1:updateVideoDataSaverOption'][
            'v1:transactionReference'] = self._epochMilli
        bodyTemplate_dict['soapenv:Envelope']['soapenv:Body']['v1:updateVideoDataSaverOption'][
            'v1:videoDataSaverOption'] = videoDataSaverOption

        body = xmltodict.unparse(bodyTemplate_dict, pretty=True)
        self._print_wrapper(body, "INPUT")

        # make request
        r = requests.post(url, data=body, headers=header, verify=False)
        output = xmltodict.parse(r.text)
        print(output)
        return output











