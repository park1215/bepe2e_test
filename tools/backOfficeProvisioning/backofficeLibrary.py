import backofficeAPI as bo_api
import random
import time, datetime
from datetime import datetime
from datetime import timedelta
import xmltodict
import xml.etree.ElementTree as ET
import json
from json import loads, dumps
from robot.api import logger
import os
import sys


# provisionModem
# \brief Function provisions a specific modem with a given account
# \params: macAddr - MAC address of modem to be provisioned
#         serviceAgrRef - Service Agreement number of account
# \return: True is successfully provisioned, False is errored out somewhere

# method to call from robot to test other python methods
def testrobot():
    logger.console('in testrobot')
    boApi = bo_api.BO_API_Lib()
    # words = boApi.doNothing()
    # words = boApi.getServiceAvailability("92009", "CARLSBAD", "CA", "6155 EL CAMINO REAL", "B2B_PARTNERS", "US")
    # ids = boApi.queryWBAforDeviceStatus('106058790')
    # logger.console(ids)
    # ids = boApi.getRbCustomerFromAccount('106606950')
    # logger.console(ids)
    ids = boApi.getAccountStatusFromCustomerRef('C40134669')
    return ids


def getModemPtriaStatus(serviceAgreementId):
    boApi = bo_api.BO_API_Lib()
    response = boApi.queryWBAforDeviceStatus(serviceAgreementId)
    logger.info('\n Modem & PTRIA State in WB Device is ' + str(response))
    return response


def getBillingProductStatusFromAccountReference(accountReferenceId):
    boApi = bo_api.BO_API_Lib()
    customerReferenceId = boApi.getRbCustomerFromAccount(accountReferenceId)
    logger.console('\n customer reference = ' + str(customerReferenceId))
    response = boApi.getAccountStatusFromCustomerRef(customerReferenceId)
    return response


def getBillingProductStatusFromCustomerReferenceId(customerReferenceId):
    boApi = bo_api.BO_API_Lib()
    response = boApi.getAccountStatusFromCustomerRef(customerReferenceId)
    return response


def getActiveAccountReference(systemID, salesChannel, extAcctStatsWith, modemType, no_of_days_active_account, plan):
    boApi = bo_api.BO_API_Lib()
    response = boApi.queryWBAforActiveAccountReference(systemID, salesChannel, extAcctStatsWith, modemType,
                                                       no_of_days_active_account, plan)
    logger.info('\n Account Reference # and business plan is ' + str(response))
    return response

def getVolubillAccountStatus(serviceAgreementId):
    boApi = bo_api.BO_API_Lib()
    response = boApi.queryVolubillAccountStatus(serviceAgreementId)
    logger.info('\n Volubill Account Status is ' + str(response))
    return response

def getVolubillProductStatus(serviceAgreementId):
    boApi = bo_api.BO_API_Lib()
    response = boApi.queryVolubillProductStatus(serviceAgreementId)
    logger.info('\n Volubill Product Status is ' + str(response))
    return response

def getSuspendedAccountReference(systemID, salesChannel, extAcctStatsWith, modemType, no_of_days_active_account, plan):
    boApi = bo_api.BO_API_Lib()
    response = boApi.queryWBAforSuspendedAccountReference(systemID, salesChannel, extAcctStatsWith, modemType,
                                                       no_of_days_active_account, plan)
    logger.info('\n Account Reference # and business plan is ' + str(response))
    return response

"""
def clearLogicalBeamId(macAddr):
    # takes macAddr as input and deletes logicalBeamId Association if it exists
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    print("\n============Checking LDAP for beamId association============")
    try:
        ldapResponse = boApi.ldapQuery(macAddr)
        ldapResponseJson = json.loads(ldapResponse)
    except Exception as e:
        return False, funcName + ":error querying ldap for mac addr=" + macAddr + ", error = " + str(e)
    if "beam_id" in ldapResponseJson['ldap']:
        print("beam_id exists, removing")
        data = {"volubill": [], "tr069": [],
                "options": [{"operation": "", "name": "reset", "value": "false", "format": ""},
                            {"operation": "", "name": "thread_limit", "value": "25", "format": ""}],
                "filters": [{"operation": "", "name": "beam_id", "value": "MAC", "format": ""},
                            {"operation": "", "name": "smts_ip", "value": "MAC", "format": ""},
                            {"operation": "", "name": "mac_address", "value": [macAddr], "format": ""}], "ldap": [
                {"name": "beam_id", "operation": "delete", "value": str(ldapResponseJson['ldap']['beam_id']),
                 "format": "encoded"}]}
        try:
            beamDeletionJobId = boApi.cmtApiLogicalBeamDeletion(macAddr, data)
        except Exception as e:
            return False, funcName + ":error deleting logical beam for mac addr = " + macAddr + ", error = " + str(e)
        try:
            cmdExecStatus = boApi.cmtApiCmdExecStatus(beamDeletionJobId)
            return True
        except Exception as e:
            return False, funcName + ":error checking beam deletion job id for mac addr = " + macAddr + ", error = " + str(
                e)
    else:
        print("Beam ID not associated for modem in LDAP")
        return False, funcName + ":error in ldap query for beam id, not found in ldap query response, mac addr = " + macAddr
"""

def getCurrentRealm(macAddr):
    # takes macAddr as input and returns current realm modem on
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    try:
        status, getRealmResponse = boApi.getRealm(macAddr)
        logger.info(getRealmResponse)
        if status:
            getRealm = json.loads(getRealmResponse)
            realm = getRealm['realm']
            return True, realm
        else:
            return False, getRealmResponse
    except Exception as e:
        return False, funcName + ":error getting realm for mac addr=" + macAddr + ", error = " + str(e)

def changeRealmOnModem(macAddr, newRealm):
    # takes macAddr as input and returns current realm modem on
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    try:
        status, changeRealmResponse = boApi.changeRealm(macAddr, newRealm)
        if status:
            return True, changeRealmResponse
        else:
            return False, changeRealmResponse
    except Exception as e:
        return False, funcName + ":error changing realm for mac addr=" + macAddr + ", error = " + str(e)

def clearLogicalBeamId(targetId, latitude, longitude):
    # takes macAddr as input and deletes the csaId Association if it exists
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    #macAddrMod = macAddr.replace(":", "") 
    try:
        apiOut = boApi.newConfigureFixedNTD(targetId, latitude, longitude)
        logger.info(apiOut)
        id = apiOut['ConfigureFixedNTD']['id']
        state = apiOut['ConfigureFixedNTD']['state'] 
        if state == 'RUNNING':
                try:
                    status, state = boApi.sdpConfigureFixedNTDCommandStatus(id)
                    #id = apiOut['ConfigureFixedNTD']['id']
                    #state = apiOut['ConfigureFixedNTD']['state']
                    logger.info("Command ID: " + " Has status: " + state)
                    if state == 'SUCCEEDED':
                        return True, state
                except Exception as e:
                    logger.console(str(e))
                    return False, funcName + ":error checking beam deletion job id for Target Id = " + targetId + ", error = " + str(e)
        elif state == 'SUCCEEDED':
            logger.info("Command ID: " + " Has status: " + state)
            return True, state    
        else:
            logger.console(str(e))
            print("Beam ID not associated for modem in SDP")
            return False, funcName + ":error in ldap query for beam id, not found in ldap query response, Target Id = " + targetId
    except Exception as e:
        logger.console(str(e))
        return False, funcName + ":error deleting logical beam for Target Id = " + targetId + ", error = " + str(e)


def provisionModem(macAddr, serviceAgrRef):
    # default values set for this automation
    installerId = "99072761"  # installer id used for test
    timezone = "UTC-6"
    qoiStatus = "green"
    triaSerialNum = "999999999"
    device = "abSpockModem"
    internalRef = 12000  # hardcoded reference numbers used for subservice IDing
    transactionReference = ""  # "2500"

    # initialize api class
    boApi = bo_api.BO_API_Lib()

    print("\n============Running findSubscriberBySearchCriteria============")
    apiOut = boApi.findSubscriberBySearchCriteria("WildBlue", "devteamall", serviceAgrRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error and grab data
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse'][
            'ns2:errorsOccured'] != 'false':
            print("Call returned 'errorsOccured'")
            return False
        intAccRef = \
        apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:internalAccountReference']
        extAccRef = \
        apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:externalAccountReference']
        extSysName = \
        apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:externalSystemName']
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of findSubscriberBySearchCriteria============\n")

    print("\n============Running getSoaTransactionsByExtAccRef============")
    print(extAccRef)
    print(extSysName)
    apiOut = boApi.getSoaTransactionsByExtAccRef(extSysName, extAccRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error and grab data
    try:
        transactionReference = \
        apiOut['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
            'soaTransaction']['soaTransactionReference']
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of getSoaTransactionsByExtAccRef============\n")

    print("\n============Running getAccountHierarchy_SDP=============")
    apiOut = boApi.getAccountHierarchy_SDP(intAccRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # extracting needed info
    try:
        beamNumber = apiOut['soap:Envelope']['soap:Body']['ns4:getAccountHierarchyResponse']['ns4:accountHierarchy'][
            'ns4:serviceAgreementHierarchy'] \
            ['ns4:serviceAgreement']['ns4:beamInfo']['beamTechnicalInfo']['beamNumber']
        satName = apiOut['soap:Envelope']['soap:Body']['ns4:getAccountHierarchyResponse']['ns4:accountHierarchy'][
            'ns4:serviceAgreementHierarchy'] \
            ['ns4:serviceAgreement']['ns4:beamInfo']['beamTechnicalInfo']['satelliteName']
        lat = apiOut['soap:Envelope']['soap:Body']['ns4:getAccountHierarchyResponse']['ns4:accountHierarchy'][
            'ns4:serviceAgreementHierarchy']['ns4:serviceAgreement'] \
            ['ns4:serviceContact']['contactInfo']['location']['GeoPosition']['latitude']
        long = apiOut['soap:Envelope']['soap:Body']['ns4:getAccountHierarchyResponse']['ns4:accountHierarchy'][
            'ns4:serviceAgreementHierarchy']['ns4:serviceAgreement'] \
            ['ns4:serviceContact']['contactInfo']['location']['GeoPosition']['longitude']
        modemType = apiOut['soap:Envelope']['soap:Body']['ns4:getAccountHierarchyResponse']['ns4:accountHierarchy'][
            'ns4:serviceAgreementHierarchy'] \
            ['ns4:serviceAgreement']['ns4:beamInfo']['beamTechnicalInfo']['equipmentType']['modemType']
        triaType = apiOut['soap:Envelope']['soap:Body']['ns4:getAccountHierarchyResponse']['ns4:accountHierarchy'][
            'ns4:serviceAgreementHierarchy'] \
            ['ns4:serviceAgreement']['ns4:beamInfo']['beamTechnicalInfo']['equipmentType']['triaType']
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of getAccountHierarchy_SDP============\n")

    print("\n============Running registerModem=============")
    apiOut = boApi.registerModem(transactionReference, serviceAgrRef, beamNumber, satName, macAddr, lat, long,
                                 installerId, timezone)
    print("\n %s" % xmltodict.unparse(apiOut, pretty=True))
    # check if returned error
    try:
        if "soap:Fault" in apiOut['soap:Envelope']['soap:Body']:
            print("Response returned a fault error")
            return False
        elif apiOut['soap:Envelope']['soap:Body']['ns3:registerModemResponse']['ns3:status'] != "SUCCESS":
            print("Response did not return 'SUCCESS'")
            return False
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return
    print("============End of registerModem============\n")

    print("\n============Running updateQoiResults=============")
    apiOut = boApi.updateQoiResults(transactionReference, serviceAgrRef, qoiStatus, triaSerialNum)
    print("\n %s" % xmltodict.unparse(apiOut, pretty=True))
    # check if returned error
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns3:updateQOIResultsResponse']['ns3:status'] != "SUCCESS":
            print("Response did not return 'SUCCESS'")
            return False
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of updateQoiResults============\n")

    print("\n============Running activateISP=============")
    apiOut = boApi.activateISP(transactionReference, serviceAgrRef)
    print("\n %s" % xmltodict.unparse(apiOut, pretty=True))
    # check if returned error
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns3:activateISPResponse']['ns3:status'] != "SUCCESS":
            print("Response did not return 'SUCCESS'")
            return False
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of activateISP============\n")

    print("\n============Running activateModemAccess=============")
    apiOut = boApi.activateModemAccess(transactionReference, serviceAgrRef, device)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns3:activateModemAccessResponse']['ns3:status'] != "SUCCESS":
            print("Response did not return 'SUCCESS'")
            return False
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of activateModemAccess============\n")

    print("\n============Running provisioningComplete=============")
    apiOut = boApi.provisioningComplete(transactionReference, serviceAgrRef, str(internalRef), modemType, "MODEM",
                                        "ACTIVE", str(internalRef + 1), triaType, "TRIA", "ACTIVE")
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns3:provisioningCompleteResponse']['ns3:status'] != "SUCCESS":
            print("Response did not return 'SUCCESS'")
            return False
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of provisioningComplete============\n")

    print("Finished provisioning modem")
    return True

def queryWBAforInternalAccountRef(customerRelnId, productInstanceId):
    funcName = sys._getframe().f_code.co_name
    boApi = bo_api.BO_API_Lib()
    try:
        apiOut = boApi.queryWBAforInternalAccountReference(customerRelnId, productInstanceId)
        return apiOut
    except Exception as e:
        logger.error("An Error Occurred:" + str(e))
        return False, funcName + ":Error in looking up InternalAccountReference in WB-DATA" +  str(e)

def provisionModem2Account(macAddr, intAccRef, extSysName, orderRef):
    logger.info('in provisionModem2Account')
    logger.info(extSysName)
    
    boApi = bo_api.BO_API_Lib()
    apiOut = boApi.resolveInstallation(macAddr, intAccRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error and grab data
    try:
        if not apiOut['soap:Envelope']['soap:Body']['ns3:resolveInstallationResponse']['ns3:status']:
            logger.error("Call returned 'Error Occurred'")
            errorCode = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:code']
            errorReason = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail'][
                'ns4:reason']
            errorDetail = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail'][
                'ns4:Detail']
            errorNode = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:node']
            errorTrackingKey = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail'][
                'ns4:trackingKey']
            return [False, "error resolving modem installation: " + errorReason]
        else:
            print("Modem successfully Provisioned")
            count = 0  # give 5 mins to go to dispatched
            while count < 120:
                print("Running call: " + str(count))
                logger.info(extSysName)
                returnObj = boApi.getSoaTransactionsByExtAccRef(extSysName, orderRef)
                print(xmltodict.unparse(returnObj, pretty=True) + "\n")
                try:
                    if returnObj['soap:Envelope']['soap:Body'][
                        'ns4:getSoaTransactionsByExternalAccountReferenceResponse']['soaTransaction'][
                        'transactionStatusName'] == "COMPLETE":
                        return [True]
                except Exception as e:
                    print("An Error Occurred checking transaction status")
                    logger.error("An Error Occurred !")
                    print(e)
                    return [False, "An Error Occurred checking provisioning transaction status: " + str(e)]
                count += 1
                time.sleep(5)
            logger.error("Modem Provisioning / NewConnnect  did not go through within 120 seconds")
            return [False, "timeout waiting for modem provisioning"]

    except Exception as e:
        errorMessage = loads(dumps(apiOut))
        logger.error(errorMessage)
        return [False, 'An Error Occurred trying to read installation response:' + str(
            errorMessage['soap:Envelope']['soap:Body']['soap:Fault']['faultstring'])]
            
    


def getUserOrganization(username):
    # Instantiate API Class
    boApi = bo_api.BO_API_Lib()
    apiOut = boApi.getUserOrganization(username)
    organization = ""
    # grab data if it is there, if nothing is returned, then fail
    try:
        organization = apiOut['getUserOrganizationResponse']['organization']
        logger.console('\nOrganization -- ' + organization)
        return organization
    except Exception as e:
        logger.error("The Authorization service did not contain " + str(e) + " index for organization=" + organization)
        return False, sys.getFrame().f_code.co_name + ":The Authorization service did not contain " + str(
            e) + " indes for organization=" + organization


def modemSwap(macAddr, serv_agree_id, extServiceAgrRef, systemID, transactionTypeName, salesChannel, transactionStatusName):
    serviceAgrRef = int(serv_agree_id)
    boApi = bo_api.BO_API_Lib()
    logger.console('modem Swap inputs:')
    funcName = sys._getframe().f_code.co_name
    # getMacHistory
    logger.console('\nRunning getMacHistory')
    logger.info("Running getMacHistory")
    print("\n============Running =============")
    returnObj = boApi.getMacHistory(serviceAgrRef)
    if "error" in returnObj:
        return False, funcName + ":" + returnObj["error"]
    print("mac history = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error and grab data
    try:

        output = returnObj['soap:Envelope']['soap:Body']['ns4:getMacHistoryResponse']['ns4:macHistory']
        second_output = returnObj['soap:Envelope']['soap:Body']['ns4:getMacHistoryResponse']
        output_len = len(output)
        logger.info("Response mac history length:" + str(output_len))
        logger.info("Response mac history output:" + str(output))
        second_output_len = len(second_output)
        logger.info("Response mac history second output length:" + str(second_output_len))
        logger.info("Response mac history second output:" + str(second_output))
        if output_len >=2 :
            oldMacAddress = \
            returnObj['soap:Envelope']['soap:Body']['ns4:getMacHistoryResponse']['ns4:macHistory']['ns4:macAddress']
        else:
            date_list = []
            mac_date_mapping = {}
            #prev_prov_time = datetime.utcnow()
            for key, history in enumerate(returnObj['soap:Envelope']['soap:Body']['ns4:getMacHistoryResponse']['ns4:macHistory']):
                # grab mac address
                get_prov_time = (history['ns4:provisionedUTCDateTime'])
                prov_time = datetime.datetime.strptime(get_prov_time, "%Y-%m-%dT%H:%M:%S.%fZ")

                date_list.append(prov_time)
                mac_address = (history['ns4:macAddress'])
                mac_date_mapping[prov_time] = mac_address
            recent_date = max(date_list)
            oldMacAddress = mac_date_mapping.get(recent_date)


    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error in ggetMacHistoryResponse " +  str(e)
    print("============End of getMacHistory============\n")
    logger.console('\nFinished getMacHistory')
    logger.info("Finished getMacHistory")

    # addSoaRequest
    print("\n============Running addSoaRequest=============")
    logger.console('\nRunning addSoaRequest')
    logger.info("Running addSoaRequest")
    externalTransactionReference = int(time.time())
    returnObj = boApi.addSoaRequest(systemID, transactionTypeName, externalTransactionReference)
    logger.info('returnObj in addSoaRequest: ' + str(returnObj))
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        soaRequestId = \
        returnObj['soap:Envelope']['soap:Body']['ns4:addSoaRequestResponse']['soaRequestId']
        logger.console('soaRequestId: ' + soaRequestId)
        logger.info('soaRequestId: ' + soaRequestId)
    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error in addSoaResponse " +  str(e)
    print("============End of addSoaRequest============\n")
    logger.console('\nFinished addSoaRequest')
    logger.info("Finished addSoaRequest")

    # addSoaTransaction
    print("\n============Running addSoaTransaction=============")
    logger.console('\nRunning addSoaTransaction')
    logger.info("Running addSoaTransaction")
    returnObj = boApi.addSoaTransaction(transactionTypeName, systemID, salesChannel, soaRequestId, externalTransactionReference, extServiceAgrRef)
    logger.info('returnObj in addSoaTransaction: ' + str(returnObj))
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        soaTransactionReference = \
        returnObj['soap:Envelope']['soap:Body']['ns4:addSoaTransactionResponse']['soaTransactionReference']
        logger.console('soaTransactionReference: ' + soaTransactionReference)
        logger.info('soaTransactionReference: ' + soaTransactionReference)
    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error in addSoaTransactionResponse " +  str(e)


    # updateSoaTransaction
    print("\n============Running updateSoaTransaction=============")
    logger.console('\nRunning updateSoaTransaction')
    logger.info("Running updateSoaTransaction")
    returnObj = boApi.updateSoaTransaction(soaTransactionReference, transactionStatusName)
    logger.info('returnObj in updateSoaTransaction: ' + str(returnObj))
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        status = \
        returnObj['soap:Envelope']['soap:Body']['ns4:updateSoaTransactionResponse']['result']
        logger.console('updateSoaTransactionResponse: ' + status)
        logger.info('updateSoaTransactionResponse: ' + status)
    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error in updateSoaTransactionResponse " +  str(e)

    # updateSubscriberProfile
    print("\n============Running updateSubscriberProfile=============")
    logger.console('\nRunning updateSubscriberProfile')
    logger.info("Running updateSubscriberProfile")
    returnObj = boApi.updateSubscriberProfile(soaTransactionReference, serviceAgrRef, oldMacAddress, macAddr)
    logger.info('returnObj in updateSubscriberProfile: ' + str(returnObj))
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        result = \
        returnObj['soap:Envelope']['soap:Body']['ns3:updateSubscriberProfileResponse']['result']
        logger.console('updateSubscriberProfile result: ' + result)
        logger.info('updateSubscriberProfile result: ' + result)
    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error in addSoaTransactionResponse " + str(e)

    # modemSwap
    print("\n============Running modemSwap=============")
    logger.console('\nRunning modemSwap')
    logger.info("Running modemSwap")
    returnObj = boApi.modemSwap(soaTransactionReference, serviceAgrRef, oldMacAddress, macAddr)
    logger.info('returnObj in modemSwap: ' + str(returnObj))
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        modemSwapStatus = \
        returnObj['soap:Envelope']['soap:Body']['ns3:modemSwapResponse']['ns3:status']
        logger.console('modemSwapStatus: ' + modemSwapStatus)
        logger.info('modemSwapStatus: ' + modemSwapStatus)
    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error in modemSwapResponse " +  str(e)

    # equipmentSwap
    print("\n============Running equipmentSwap=============")
    logger.console('\nRunning equipmentSwap')
    logger.info("Running equipmentSwap")
    returnObj = boApi.equipmentSwap(soaTransactionReference, soaRequestId, serviceAgrRef, oldMacAddress, macAddr)
    logger.info('returnObj in equipmentSwap: ' + str(returnObj))
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        messageID = \
        returnObj['env:Envelope']['env:Header']['wsa:MessageID']
        logger.console('equipmentSwapResponse: ' + messageID)
        logger.info('equipmentSwapResponse: ' + messageID)
    except Exception as e:
        logger.error = str(dict(returnObj['env:Envelope']['env:Body']['env:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['env:Envelope']['env:Body']['env:Fault'])['faultstring'])
        return False, funcName + ":Error in equipmentSwapResponse " + str(e)

    return True, messageID

def addAccount(servicePlan, streetAddress, city, state, zipcode, countryCode, user, salesChannel, requestor, orderSoldBy,
               orderEnteredBy, customerType, systemID):
    boApi = bo_api.BO_API_Lib()

    createAccountResponse = []
    createAccountResponse = createAccount(servicePlan, streetAddress, city, state, zipcode, countryCode, salesChannel, requestor,
                                          orderSoldBy, orderEnteredBy, customerType, systemID)
    if createAccountResponse[0] == False:
        logger.info("Account creation failed, exiting")
        return False, sys._getframe().f_code.co_name + ":" + createAccountResponse[1]
    serviceAgrNum, extSysName, orderRef, lat, long  = createAccountResponse

    # Fetch correct organization For the User
    getOrganizationResponse = []
    getOrganizationResponse = getUserOrganization(user)
    if getOrganizationResponse[0] == False:
        logger.info("Organization Name Retrieval failed, exiting")
        return False, sys._getframe().f_code.co_name + ":" + getOrganizationResponse[1]
    organization = getOrganizationResponse

    logger.console('\nRunning findSubscriberBySearchCriteria')
    logger.info("Running findSubscriberBySearchCriteria")
    apiOut = boApi.findSubscriberBySearchCriteria(organization, user, serviceAgrNum)
    if "error" in apiOut:
        return False, sys._getframe().f_code.co_name + ":error in findSubscriberBySearchCriteria:" + str(
            apiOut["error"])
    logger.info("subscriber search output = " + str(xmltodict.unparse(apiOut, pretty=True)))
    # check if returned error and grab data
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse'][
            'ns2:errorsOccured'] != 'false':
            return False, sys._getframe().f_code.co_name + ":errors occurred in findSubscribersBySearchCriteriaResponse"
        intAccRef = \
        apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:internalAccountReference']
        return True, intAccRef, extSysName, orderRef, serviceAgrNum, lat, long

    except Exception as e:
        logger.error("An Error Occurred:" + str(e))
        return False, sys._getframe().f_code.co_name + ":error occurred reading findSubscribersBySearchCriteriaResponse response:" + str(
            e)


# createAccount
# \brief Creates a service account through Back Office. The packages available are only limited to those
#       that are allowed from Back Office catalog, which vary based on physical location, sales channel,
#       and customer type. The order management support gui can be used to find where the desired package
#       can be found: https://ordermgmt.test.exede.net/PublicGUI-SupportGUI/v1/login.xhtml
# \param: servicePlan - Name of service plan/package for the account to be created with
#        address, city, state, zipcode - Physical address information for account to be created in
#        salesChannel, customerType, systemID - Input data that will dictate availability of service plans
# \return: False if an error occurs. If accout creation is successfull then the service agreement number will
#         be returned
def createAccount(servicePlan, address, city, state, zipcode, countryCode, salesChannel, requestor, orderSoldBy, orderEnteredBy,
                  customerType, systemID):
    # initialize api class
    boApi = bo_api.BO_API_Lib()
    logger.console('create Account inputs:')
    funcName = sys._getframe().f_code.co_name
    # getServiceAvailability
    logger.console('\nRunning getServiceAvailability')
    logger.info("Running getServiceAvailability")
    print("\n============Running getServiceAvailability=============")
    returnObj = boApi.getServiceAvailability(zipcode, city, state, address, salesChannel, countryCode)
    if "error" in returnObj:
        return False, funcName + ":" + returnObj["error"]
    print("service availability = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error and grab data
    try:
        if returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse'][
            'ns2:isServiceAvailable'] == 'no':
            logger.error("Error at getServiceAvailability call, area not serviceable")
            logger.console("Error at getServiceAvailability call, area not serviceable")
            return False, funcName + ":Area not serviceable"
        beamNumber = \
        returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:siteInfo']['beam'][
            'beamTechnicalInfo']['beamNumber']
        satName = returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:siteInfo']['beam'][
            'beamTechnicalInfo']['satelliteName']
        lat = returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:siteInfo']['location'][
            'GeoPosition']['latitude']
        long = \
        returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:siteInfo']['location'][
            'GeoPosition']['longitude']
        protocol = returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:protocol']
        logger.console('Beam Number: ' + beamNumber)
        logger.console('Satellite: ' + satName)
        logger.console('Protocol: ' + protocol)
        logger.info('Beam Number: ' + beamNumber)
        logger.info('Satelite: ' + satName)
        logger.info('Protocol: ' + protocol)
    except Exception as e:
        logger.error = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        logger.console = str(dict(returnObj['soap:Envelope']['soap:Body']['soap:Fault'])['faultstring'])
        return False, funcName + ":Error checking for service available " + str(e)
    print("============End of getServiceAvailability============\n")
    logger.console('\nFinished getServiceAvailability')
    logger.info("Finished getServiceAvailability")
    # getPackages
    print("\n============Running getPackages=============")
    logger.console('\nRunning getPackages')
    logger.info("Running getPackages")
    returnObj = boApi.getPackages(salesChannel, customerType, "newConnect", beamNumber, satName, lat, long, countryCode)
    print("packages = " + str(xmltodict.unparse(returnObj, pretty=True)))
    # check if returned error
    try:
        if not "ns4:package" in returnObj['soap:Envelope']['soap:Body']['ns4:getPackagesResponse']:
            print('No package found in Response')
            return False, funcName + ":No package found in getPackage responsefuncName+"
    except Exception as e:
        logger.error("An Error Occurred verifying ns4:package:")
        return False, funcName + ":exception reading getPackagesResponse: " + str(e)

    # parse through packages and grab needed info
    randNum = ""  # generate random number used for name and id
    for x in range(0, 14):
        randNum += str(random.randint(0, 9))
    print(randNum)
    randID = randNum

    unix_ts = int(time.time())
    print(unix_ts)
    # randID = randNum
    ext_acct_ref = "BEPE2E" + str(unix_ts)
    logger.console("ext acct ref is: " + ext_acct_ref)
    packRefList = []
    serviceItemReference = ""
    packageReference = ""
    otc = 0.00
    totalOTC = ""
    serviceList = []
    count = 0
    for key, pack in enumerate(returnObj['soap:Envelope']['soap:Body']['ns4:getPackagesResponse']['ns4:package']):
        # grab service information and packageReference number
        print(pack['ns4:displayName'])
        # logger.console('\nPackages are -->' +  pack['ns4:displayName'])
        if pack['ns4:displayName'] == servicePlan:
            logger.console("found desired package: " + servicePlan)
            packRefList.append(pack['ns4:packageReference'])  # for getComponent
            optionGroups = pack['ns4:optionGroup']
            # check if return is list of multiple dict or just one dict, so does not crash
            # might need to be optimized
            print(isinstance(optionGroups, list))
            if isinstance(pack['ns4:optionGroup'], list):
                optionGroups = pack['ns4:optionGroup']
            else:
                optionGroups = []
                optionGroups.append(pack['ns4:optionGroup'])
            for opG in optionGroups:
                randID += "1"
                if isinstance(opG['ns4:packageItem'], list):
                    packitemList = opG['ns4:packageItem']
                else:
                    packitemList = []
                    packitemList.append(opG['ns4:packageItem'])
                # print("packitemList: ", packitemList)
                displayName = packitemList[0]['ns4:displayName']
                packItemRef = packitemList[0]['ns4:packageItemReference']
                itemType = packitemList[0]['ns4:itemType']
                priceType = packitemList[0]['ns4:priceType']
                price = float(packitemList[0]['ns4:packageItemPrice']['ns4:price'])
                service = "<Service><ServiceReference>" + randID + "</ServiceReference><Name>" + displayName + "</Name><Type>" + itemType \
                          + "</Type><CatalogNumber>" + packItemRef + "</CatalogNumber></Service>"
                # print("service: ", service)
                serviceList.append(service)
                if servicePlan == displayName:
                    serviceItemReference = randID
                if itemType == 'INTERNET_ACCESS_SERVICE' or itemType == 'Internet Access Service':
                    packageReference = packItemRef
                if priceType == "One-Time":
                    otc += float(price)
                    totalOTC = str(otc)
            break
        else:
            logger.console("did not find package with service " + servicePlan)
            count += 1
    if count >= len(returnObj['soap:Envelope']['soap:Body']['ns4:getPackagesResponse']['ns4:package']):
        logger.error("Entered package with service plan " + servicePlan + " was not found in this service area")
        return False, funcName + ":Package with service plan " + servicePlan + " was not found in requested service area"
    print("serviceList:")
    print(serviceList)
    print("============End of getPackages============\n")
    logger.console('\nFinished getPackages')
    logger.info("Finished getPackages")
    # getComponents
    print("\n============Running getComponents=============")
    returnObj = boApi.getComponents(packRefList)
    print(xmltodict.unparse(returnObj, pretty=True))
    # check if component exists for desired service plan
    try:
        if returnObj['soap:Envelope']['soap:Body']['ns4:getComponentsResponse']['ns4:component'][
            'ns4:displayName'] == servicePlan:
            logger.console("found component for desired package")
        else:
            logger.console("component for desired service plan " + servicePlan + " not found")
            return False, funcName + ":servicePlan " + servicePlan + " not found in component"
    except Exception as e:
        logger.console("An Error Occurred verifying service plan:")
        print(e)
        return False, funcName + ":error reading components: " + str(e)
    print("============End of getComponents============\n")

    # addCustomerRequest
    logger.console('\nRunning addCustomerRequest')
    logger.info("Running addCustomerRequest")
    print("\n============Running addCustomerRequest=============")
    # set up time and name input
    epochMilli = int(round(time.time() * 1000))
    curtime = time.localtime()
    curDate = time.strftime("%Y-%m-%d", time.localtime())
    firstName = "FN" + str(randNum)
    lastName = "LN" + str(randNum)
    returnObj = boApi.addCustomerRequest(serviceList, requestor, systemID, systemID, ext_acct_ref, epochMilli,
                                         orderSoldBy, orderEnteredBy, curDate, ext_acct_ref, \
                                         firstName, lastName, "760-476-2200", countryCode, address, "", city, state, zipcode, "", "",
                                         "WILDBLUE", ext_acct_ref, \
                                         customerType, salesChannel, totalOTC)
    print(xmltodict.unparse(returnObj, pretty=True))
    try:
        if returnObj['Response']['ResponseStatus']['ErrorCode']['#text'] != 'SUCCESS' or \
                        returnObj['Response']['Transaction']['OrderStatus']['OrderStatus'] != 'ACCEPTED':
            logger.console('addCustomer call failed')
            return False, funcName + ":addCustomer failed, customer = " + firstName + " " + lastName
    except Exception as e:
        logger.console("Expected Response Not Found, error = " + str(e))
        # checks for if returns Exception Servlet timeout error
        try:
            if returnObj['html']['head']['title'] == "Exception Servlet":
                print('Timeout returned')
                return False, funcName + ":Timeout in addCustomer"
        except Exception as e:
            return False, funcName + ":Unexpected response from addCustomer: " + str(e)
    orderRef = returnObj['Response']['Transaction']['OrderStatus']['OrderReference']
    extSysName = returnObj['Response']['Transaction']['SystemID']
    print("============End of addCustomerRequest============\n")
    logger.console('\nFinished addCustomerRequest')
    logger.info("Finished addCustomerRequest")
    # getSoaTransactionsByExtAccRef
    print("\n============Running getSoaTransactionsByExtAccRef=============")
    logger.console('\nFinished addCustomerRequest')
    logger.info("Finished addCustomerRequest")
    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running call: " + str(count))
        returnObj = boApi.getSoaTransactionsByExtAccRef(extSysName, orderRef)
        print(xmltodict.unparse(returnObj, pretty=True) + "\n")
        # print(returnObj)
        try:
            if returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "DISPATCHED":
                break
            elif returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "ERROR":
                logger.console("Transaction State in Error")
                return False, funcName + ":SOA Transaction state in error"
        except Exception as e:
            return False, funcName + ":Error reading SOA transactionStatusName:" + str(e)
        count += 1
        time.sleep(5)
    if count >= 60:
        return False, funcName + ":Created customer account not in dispatch"
    else:
        logger.console("Customer account in dispatch")

    print("============End of getSoaTransactionsByExtAccRef============\n")

    # queryWBA
    print("\n============Running queryWBA=============")
    try:
        returnObj = boApi.queryWBA(extSysName, orderRef)
    except Exception as e:
        return False, funcName + ":An Error Occurred with queryWBA call: " + str(e)
    if not returnObj:
        logger.console("queryWBA returned empty")
        return [False, "queryWBA returned null value"]
    serviceAgreeNum = int(returnObj[0][11])
    print("============End of queryWBA============\n")

    # assuming that don't need to schedule installation
    if False:
        # getAvailableInstallDates
        # for test
        curEpoch = time.time()
        curDate = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.localtime(curEpoch))
        # don't forget to remove
        futureTime = curEpoch + 60 * 60 * 24 * 15  # go 15 days into the future
        futureDate = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.localtime(futureTime))
        print(curDate)
        print(futureDate)
        # for testing
        beamNumber = \
        returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:siteInfo']['beam'][
            'beamTechnicalInfo']['beamNumber']
        satName = returnObj['soap:Envelope']['soap:Body']['ns2:getServiceAvailabilityResponse']['ns2:siteInfo']['beam'][
            'beamTechnicalInfo']['satelliteName']
        lat = "33.0957"
        long = "-117.259986"
        retCountryCode = ""  # todo
        retPostalCode = ""
        retRegion = ""
        retMunicipality = ""
        returnObj = boApi.getAvailableInstallDates(curDate, futureDate, lat, long, retCountryCode, retPostalCode,
                                                   retRegion, retMunicipality, address, salesChannel, customerType)
        # scheduleFSM_SalesChannel

    logger.console("Finished Account Creation, Service Agreement Number: %s" % str(serviceAgreeNum))
    return serviceAgreeNum, extSysName, orderRef, lat, long


def resumeAccount(acctReference, requestor, orderSoldBy, systemID):
    # initialize api class
    boApi = bo_api.BO_API_Lib()
    logger.console('resume Account inputs:')
    funcName = sys._getframe().f_code.co_name
    # parse through packages and grab needed info
    randNum = ""  # generate random number used for name and id
    for x in range(0, 14):
        randNum += str(random.randint(0, 9))
    print(randNum)
    # randID = randNum

    # resumeAccountRequest
    logger.console('\nRunning resumeAccountRequest')
    logger.info("Running resumeAccountRequest")
    print("\n============Running resumeAccountRequest=============")
    # set up time for the state date
    curDate = time.strftime("%Y-%m-%d", time.localtime())

    returnObj = boApi.resumeAccountRequest(requestor, systemID, systemID, randNum, orderSoldBy, curDate, acctReference)
    logger.console("returnObj: %s" % str(returnObj))
    print(xmltodict.unparse(returnObj, pretty=True))
    try:
        if returnObj['Response']['ResponseStatus']['ErrorCode']['#text'] != 'SUCCESS' or \
                        returnObj['Response']['Transaction']['OrderStatus']['OrderStatus'] != 'ACCEPTED':
            logger.console('resumeAccount call failed')
            return False, funcName + ":resumeAccount failed, account_reference = " + acctReference
    except Exception as e:
        logger.console("Expected Response Not Found, error = " + str(e))
        # checks for if returns Exception Servlet timeout error
        try:
            if returnObj['html']['head']['title'] == "Exception Servlet":
                print('Timeout returned')
                return False, funcName + ":Timeout in resumeAccount"
        except Exception as e:
            return False, funcName + ":Unexpected response from resumeAccount: " + str(e)
    orderRef = returnObj['Response']['Transaction']['OrderStatus']['OrderReference']
    extSysName = returnObj['Response']['Transaction']['SystemID']
    orderStatus = returnObj['Response']['Transaction']['OrderStatus']['OrderStatus']
    print("============End of resumeAccountRequest============\n")
    logger.console('\nFinished resumeAccountRequest')
    logger.info("Finished resumeAccountRequest")

    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running call: " + str(count))
        returnObj = boApi.getSoaTransactionsByExtAccRef(extSysName, acctReference)
        print(xmltodict.unparse(returnObj, pretty=True) + "\n")
        # print(returnObj)
        try:
            if returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "COMPLETE":
                print("============ order status response is COMPLETE============\n")
                return True, extSysName, orderRef
                # break
            elif returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "ERROR":
                logger.console("Transaction State in Error")
                return False, funcName + ":SOA Transaction state in error"
        except Exception as e:
            return False, funcName + ":Error reading SOA transactionStatusName:" + str(e)
        count += 1
        time.sleep(5)
    if count >= 60:
        return False, funcName + ":Resumed customer account not in complete"
    else:
        logger.console("Resumed account in complete")

    print("============End of getSoaTransactionsByExtAccRef============\n")


def suspendAccount(acctReference, requestor, orderSoldBy, systemID):
    # initialize api class
    boApi = bo_api.BO_API_Lib()
    logger.console('suspend Account inputs:')
    funcName = sys._getframe().f_code.co_name
    # parse through packages and grab needed info
    randNum = ""  # generate random number used for name and id
    for x in range(0, 14):
        randNum += str(random.randint(0, 9))
    print(randNum)
    # randID = randNum

    # suspendAccountRequest
    logger.console('\nRunning suspendAccountRequest')
    logger.info("Running suspendAccountRequest")
    print("\n============Running suspendAccountRequest=============")
    # set up time for the state date
    curDate = time.strftime("%Y-%m-%d", time.localtime())

    returnObj = boApi.suspendAccountRequest(requestor, systemID, systemID, randNum, orderSoldBy, curDate, acctReference)
    logger.console("returnObj: %s" % str(returnObj))
    print(xmltodict.unparse(returnObj, pretty=True))
    try:
        if returnObj['Response']['ResponseStatus']['ErrorCode']['#text'] != 'SUCCESS' or \
                        returnObj['Response']['Transaction']['OrderStatus']['OrderStatus'] != 'ACCEPTED':
            logger.console('suspendAccount call failed')
            return False, funcName + ":suspendAccount failed, account_reference = " + acctReference
    except Exception as e:
        logger.console("Expected Response Not Found, error = " + str(e))
        # checks for if returns Exception Servlet timeout error
        try:
            if returnObj['html']['head']['title'] == "Exception Servlet":
                print('Timeout returned')
                return False, funcName + ":Timeout in suspendAccount"
        except Exception as e:
            return False, funcName + ":Unexpected response from suspendAccount: " + str(e)
    orderRef = returnObj['Response']['Transaction']['OrderStatus']['OrderReference']
    extSysName = returnObj['Response']['Transaction']['SystemID']
    orderStatus = returnObj['Response']['Transaction']['OrderStatus']['OrderStatus']
    print("============End of suspendAccountRequest============\n")
    logger.console('\nFinished suspendAccountRequest')
    logger.info("Finished suspendAccountRequest")

    '''
    # queryWBA
    print("\n============Running queryWBA=============")
    try:
        returnObj = boApi.queryWBA(extSysName, orderRef)
    except Exception as e:
        return False, funcName + ":An Error Occurred with queryWBA call: " + str(e)
    if not returnObj:
        logger.console("queryWBA returned empty")
        return [False, "queryWBA returned null value"]
    serviceAgreeNum = int(returnObj[0][11])
    print("============End of queryWBA============\n")
    logger.console("Finished Suspend Account, Confirmation Number: %s" % str(serviceAgreeNum))
    return serviceAgreeNum, extSysName, orderRef
    '''

    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running call: " + str(count))
        returnObj = boApi.getSoaTransactionsByExtAccRef(extSysName, acctReference)
        print(xmltodict.unparse(returnObj, pretty=True) + "\n")
        # print(returnObj)
        try:
            if returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "COMPLETE":
                print("============ order status response is COMPLETE============\n")
                return True, extSysName, orderRef
                # break
            elif returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "ERROR":
                logger.console("Transaction State in Error")
                return False, funcName + ":SOA Transaction state in error"
        except Exception as e:
            return False, funcName + ":Error reading SOA transactionStatusName:" + str(e)
        count += 1
        time.sleep(5)
    if count >= 60:
        return False, funcName + ":Suspended customer account not in complete"
    else:
        logger.console("Suspended account in complete")

    print("============End of getSoaTransactionsByExtAccRef============\n")


# disconnectAccount
# \brief Dissconnects account from modem and unprovisions it. Also deactivates the account. MAC clean up could also be needed to
#       completely clear the modem from all subservices
# \param: macAddr - MAC address of modem to be unprovisioned
#        serviceAgrRef - Service agreement number of account to be disconnected and deactivated
# \return True if disconnect successfully executes, False if an error occurred
def runModemSpeedTest(macAddr, testType):
    boApi = bo_api.BO_API_Lib()
    macAddrMod = macAddr.replace(":", "")

    print("\n============Running HTTP SPEED Test on Modem============")
    try:
        sdpResponse = boApi.sdpApiTestHttpPerformance(macAddrMod, testType)
        # sdpResponseJson = json.loads(sdpResponse)
    except Exception as e:
        return False, sys._getframe().f_code.co_name + ": sdpApiTestHttpPerformance errored out with " + str(e)

    if sdpResponse['TestHttpPerformance']['id']:
        sdpJobId = sdpResponse['TestHttpPerformance']['id']
        print("JobId is :" + str(sdpJobId))
        try:
            sdpCmdExecStatus, speed = boApi.sdpApiCmdExecStatus(sdpJobId)
            return sdpCmdExecStatus, speed
        except Exception as e:
            return False, sys._getframe().f_code.co_name + ": sdpApiCmdExecStatus errored out with " + str(e)

    else:
        print("JobId not present in SDP response")
        logger.error("JobId not present in SDP response")
        return False, sys._getframe().f_code.co_name + ":JobId is not present in SDP response"


def getDeviceService(ntdId):
    boApi = bo_api.BO_API_Lib()
    apiOut = boApi.sdpApiGetService(ntdId)
    # print(xmltodict.unparse(apiOut, pretty=True))
    logger.info("get device service status is:")
    logger.info(apiOut)
    serviceId = serviceState = serviceCatalogId = ""
    # grab data if it is there, if nothing is returned, then fail
    try:
        serviceId = apiOut['Services']['Layer3Service']['id']
        serviceState = apiOut['Services']['Layer3Service']['state']
        serviceCatalogId = apiOut['Services']['Layer3Service']['configuration']['serviceCatalogId']
        logger.console(
            '\nServiceId -- ' + serviceId + '  serviceState --' + serviceState + '  serviceCatalogId --' + serviceCatalogId)
        return serviceId, serviceState, serviceCatalogId
    except Exception as e:
        logger.error("SDP services query response did not contain " + str(e) + " index for ntd id=" + ntdId)
        return False, sys._getframe().f_code.co_name + ":SDP services query response did not contain " + str(
            e) + " index for ntd id=" + ntdId


def getDeviceState(macAddr, name=''):
    boApi = bo_api.BO_API_Lib()
    macAddrMod = macAddr.replace(":", "")
    status, apiOut = boApi.sdpApiGetDevice(macAddrMod, name)
    logger.info("SDP device state is:")
    logger.info(apiOut)
    ntdId = deviceState = latitude = longitude = "" #removed csaId
    # grab data if it is there, if nothing is returned, then fail
    # Need to add conditional logic ? What if deviceMac returns nothing ?
    if status:
        try:
            deviceState = apiOut['Devices']['FixedNTD']['state']
            ntdId = apiOut['Devices']['FixedNTD']['id']
            latitude = apiOut['Devices']['FixedNTD']['configuration']['latitude']
            longitude = apiOut['Devices']['FixedNTD']['configuration']['longitude']
            logger.info(deviceState)
            logger.info(ntdId)
            logger.info(latitude)
            logger.info(longitude)
            return True, deviceState, ntdId, latitude, longitude #removed csaId
        except Exception as e:
            return True, False, False, False, False  # removed csaId
    else:
        logger.console('got exception in reading device state')
        return False, sys._getframe().f_code.co_name + ":Index " + str(
            e) + " not present for mac address " + macAddrMod + " when retrieving SDP device status", False, False, False

def getDeviceStateBasedOnId(productInstanceId, jwtName):
    boApi = bo_api.BO_API_Lib()
   # macAddrMod = macAddr.replace(":", "")
    apiOut = boApi.sdpApiGetDeviceBasedOnId(productInstanceId, jwtName)
    logger.info("SDP device state is:")
    logger.info(apiOut)
    ntdId = deviceState = latitude = longitude = "" #removed csaId
    # grab data if it is there, if nothing is returned, then fail
    # Need to add conditional logic ? What if deviceMac returns nothing ?
    try:
        deviceState = apiOut['Devices']['FixedNTD']['state']
        ntdId = apiOut['Devices']['FixedNTD']['id']
        #csaId = apiOut['Devices']['FixedNTD']['configuration']['csaId']
        latitude = apiOut['Devices']['FixedNTD']['configuration']['latitude']
        longitude = apiOut['Devices']['FixedNTD']['configuration']['longitude']

        return deviceState, ntdId, latitude, longitude #removed csaId
    except Exception as e:
        logger.console('got exception in reading device state')
        return False, sys._getframe().f_code.co_name + ":Index " + str(
            e) + " not present for product instance id " + productInstanceId + " when retrieving SDP device status"

def disconnectAccount(macAddr, user):
    # initialize api class
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    print("\n============Running sdpApiGetDevice=============")
    # get mac without colons
    macAddrMod = macAddr.replace(":", "")
    apiOut = boApi.sdpApiGetDevice(macAddrMod)
    logger.console("returned from sdpApiGetDevice")
    print(xmltodict.unparse(apiOut, pretty=True))

    serviceAgrRef = ""
    # grab data if it is there, if nothing is returned, then fail
    try:
        serviceAgrRef = apiOut['Devices']['FixedNTD']['id']
    except Exception as e:
        return False, funcName + ":sdpApiGetDevice command did not return an Id, error = " + str(e)
    print("============End of sdpApiGetDevice============\n")

    logger.console("Running getUserOrganization")
    print("\n============Running getUserOrganization=============")
    getOrganizationResponse = []
    getOrganizationResponse = getUserOrganization(user)
    if getOrganizationResponse[0] == False:
        logger.info("Organization Name Retrieval failed, exiting")
        return False, sys._getframe().f_code.co_name + ":" + getOrganizationResponse[1]
    organization = getOrganizationResponse
    logger.console("returned from getUserOrganization")

    logger.console("Running findSubscriberBySearchCriteria")
    print("\n============Running findSubscriberBySearchCriteria=============")
    returnObj = boApi.findSubscriberBySearchCriteria(organization, user, serviceAgrRef)
    logger.console("returned from findSubscriberBySearchCriteria")
    print(xmltodict.unparse(returnObj, pretty=True))
    # check if returned error and grab data
    try:
        if returnObj['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse'][
            'ns2:errorsOccured'] != 'false':
            return False, funcName + ":findSubscribersBySearchCriteriaResponse returned errorsOccured=true"
        extSysName = \
        returnObj['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:externalSystemName']
        extAcctRef = \
        returnObj['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:externalAccountReference']
        intAccRef = \
        returnObj['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:internalAccountReference']
        salesChannel = \
        returnObj['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:currentAccountOwner']
    except Exception as e:
        return False, funcName + ":An error occurred reading response of findSubscriberBySearchCriteria, error = " + str(
            e)
    print("============End of findSubscriberBySearchCriteria============")
    logger.console("Running disconnectReasons")
    print("\n============Running disconnectReasons=============\n")
    try:
        returnObj = boApi.disconnectReasons(salesChannel)
    except Exception as e:
        return False, funcName + ": An error occurred during disconnectReasons call:" + str(e)
    if not returnObj:
        return False, funcName + ":no returnObj from disconnectReasons"
    discoReason = returnObj[0][0]
    print("Disconnect Reason: " + discoReason)
    print("============End of diconnectReasons============\n")
    logger.console("Running disconnectRequest")
    print("\n============Running disconnectRequest=============")
    randNum = ""  # generate random number used for name and id
    for x in range(0, 14):
        randNum += str(random.randint(0, 9))
    curDate = time.strftime("%Y-%m-%d", time.localtime())
    orderRefPrefix = "Disconnect_"
    prefixCounter = 0
    # loops in case of conflicts with order ref ids being different
    while True:
        # needs to be unique for each request, also needs to be different from external system id and external transaction reference
        orderRef = orderRefPrefix + extAcctRef
        print(orderRef)
        returnObj = boApi.disconnectRequest(randNum, "qaadmin", extSysName, orderRef, "qaadmin", curDate, extAcctRef,
                                            discoReason)
        print(xmltodict.unparse(returnObj, pretty=True))
        # check if returned error

        try:
            if returnObj['Response']['ResponseStatus']['ErrorCode']["#text"] != "SUCCESS":
                print("Disconnect Request was not sent successful")
                logger.console("disconnect request failed")
                return False, funcName + ":disconnect request failed with result = " + \
                       returnObj['Response']['ResponseStatus']['ErrorCode']["#text"]

            else:
                if returnObj['Response']['Transaction']['OrderStatus']['OrderStatus'] != "ACCEPTED":
                    print("Disconnect Request was not accepted")
                    if returnObj['Response']['Transaction']['OrderStatus']['OrderErrorDetail']['ErrorStack'][
                        'ErrorCode']['#text'] == 'DATA_CONFLICT_ERROR':
                        return False, funcName + ":OrderStatus was not ACCEPTED in disconnect request because order ref was not unique"
                    else:
                        return False, funcName + ":OrderStatus was not ACCEPTED in disconnect request"
                else:
                    break

        except Exception as e:
            return False, funcName + ":An error occurred reading response of disconnectRequest:" + str(e)
        # modify prefix so next order ref number is unique to one that just tried
        orderRefPrefix = orderRefPrefix[0:len(orderRefPrefix) - 2] + str(prefixCounter)
        prefixCounter += 1
    print("============End of disconnectRquest============\n")
    logger.console("Running getSoaTransactionsByExtRef")
    # getSoaTransactionsByExtRef
    print("\n============Running getSoaTransactionsByExtRef=============")
    # run multiple cause might take some time for information to propogate through
    # orderRef = "Disconnect_" + extAcctRef # temp
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running Call: " + str(count))
        returnObj = boApi.getSoaTransactionsByExtRef(extSysName, orderRef)
        print(xmltodict.unparse(returnObj, pretty=True))
        try:
            if returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionByExternalReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "COMPLETE":
                break
            elif returnObj['soap:Envelope']['soap:Body']['ns4:getSoaTransactionByExternalReferenceResponse'][
                'soaTransaction']['transactionStatusName'] == "ERROR":
                return False, funcName + ": SOA transaction in error state"
        except Exception as e:
            return False, funcName + ": An error occurred reading response of getSoaTransactionsByExtRef:" + str(e)
        count += 1
        time.sleep(5)
    print(count)
    logger.console("count = " + str(count))
    if count >= 60:
        return False, funcName + ": Disconnect Customer Request Not in Successful state after 60 tries"
    else:
        print("customer disconnected successfully")
    print("============End of getSoaTransactionsByExtRef============\n")

    print("Finished disconnecting account")
    return True, intAccRef


# macCleanUp
# \brief Checks a few subservices for a MAC and deletes/deactivates information of MAC from subservices (RB, SDP, SPR)
# \param: macAddr - MAC address of modem
# \return: True if finishes running, False if error occured
def macCleanUp(macAddr, ntdID):
    # initialize api class
    boApi = bo_api.BO_API_Lib()

    # checking RB for event sources on mac, if found then delete
    print("\n============Running queryRBEventSource=============")
    apiOut = boApi.queryRBEventSource(macAddr)
    if not apiOut:
        logger.warn("no event source in RB")
    else:
        print("event source found in RB, deleting")
        # delete event source
        apiOut = boApi.deleteEventSource(macAddr)
        print(apiOut)
    print("============End of queryRBEventSource============\n")

    # checking VB for records of mac, if found then delete
    #    print("\n============Running queryVBModem=============")
    #    apiOut = boApi.queryVBModem(macAddr)
    #    print(apiOut)
    #    if not apiOut:
    #        print("no mac in VB")
    #    else:
    #        print("found mac in VB")
    # issue with deleting rn
    #    print("============End of queryVBModem============\n")

    # get mac without colons
    macAddrMod = macAddr.replace(":", "")
    # print(macAddrMod)

    # check SDP for mac association, if found then deactivate
    print("\n============Running SDP API Check for MAC=============")
    apiOut = boApi.sdpApiGetDevice(macAddrMod)
    print(xmltodict.unparse(apiOut, pretty=True))

    serviceAgr = ""
    if "FixedNTD" in apiOut['Devices']:
        if "id" in apiOut['Devices']['FixedNTD']:
            serviceAgr = apiOut['Devices']['FixedNTD']['id']
            apiOut = boApi.deactivateFixedNTD(serviceAgr)
            print(xmltodict.unparse(apiOut, pretty=True))
        else:
            logger.warn("id is not in response from sdpApiGetDevice")
    else:
        logger.warn("FixedNTD is not in response from sdpApiGetDevice")
    print("============End of SDP API Check============\n")

    # check SPR for mac, if found then delete
    print("\n============Running getSprSubs=============")
    apiOut = boApi.getSprSubs("1", macAddrMod)
    print(xmltodict.unparse(apiOut, pretty=True))
    try:
        if not "totalsubscribers" in apiOut['soap:Envelope']['soap:Body']['getSubscribersResponse']:
            return False, sys._getframe().f_code.co_name + ": totalsubscribers field not in getSprSubs response for this mac address"
    except Exception as e:
        return False, sys._getframe().f_code.co_name + ": exception in getSprSubs query: " + str(e)
    if apiOut['soap:Envelope']['soap:Body']['getSubscribersResponse']['totalsubscribers'] == "0":
        logger.warn("totalsubscribers = 0 in getSprSubs query")
    else:
        sprAcctNum = apiOut['soap:Envelope']['soap:Body']['getSubscribersResponse']['subscribers']['subscriber'][
            'subscriberid']
        logger.info("Modem Subscriber found in SPR, deleting")
        # delete Subscriber from SPR
        apiOut = boApi.policyDeleteSubscriber(sprAcctNum)
        logger.info(xmltodict.unparse(apiOut, pretty=True))


    # check openet for mac association, if found then deactivate
    print("\n============Running Openet API Check for MAC=============")
    apiOut = boApi.getOpenetSubscribers(ntdID)
    print(xmltodict.unparse(apiOut, pretty=True))
    logger.console(xmltodict.unparse(apiOut, pretty=True))
    logger.info(xmltodict.unparse(apiOut, pretty=True))


    try:
        if not "totalsubscribers" in apiOut['soap:Envelope']['soap:Body']['getSubscribersResponse']:
            return False, sys._getframe().f_code.co_name + ": totalsubscribers field not in getSprSubs response for this mac address"
    except Exception as e:
        return False, sys._getframe().f_code.co_name + ": exception in getSprSubs query: " + str(e)
    if apiOut['soap:Envelope']['soap:Body']['getSubscribersResponse']['totalsubscribers'] == "0":
        logger.warn("totalsubscribers = 0 in getSprSubs query")
    else:
        subscriberkey = apiOut['soap:Envelope']['soap:Body']['getSubscribersResponse']['subscribers']['subscriber'][
            'subscriberkey']
        logger.info("Modem Subscriber found in openet, deleting")
        # delete Subscriber from openet
        apiOut = boApi.deleteOpenetSubscriber(subscriberkey)
        logger.info(xmltodict.unparse(apiOut, pretty=True))

        try:
            if apiOut['soap:Envelope']['soap:Body']['deleteSubscriberResponse']['status'] == "SUCCESS":
                print("delete subscriber returned  successfully")
            else:
                print("Order was not accepted by system")
                return False

        except Exception as e:
            print('An Error Occured')
            print(e.message)
            return False

    print("============End of Openet API Check for MAC============\n")


    logger.info("Finished Mac Cleanup")
    return True, True


def checkOpenet(ntdId):
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    try:
        openetSubInfo = boApi.getOpenetSubBalReq(ntdId)
        print("\n============OPENET Sub Attributes Status for============")
        # print(openetSubInfo)
        print(xmltodict.unparse(openetSubInfo, pretty=True))

        for key, val in enumerate(
                openetSubInfo['soap:Envelope']['soap:Body']['ns2:GetSubscriberBalancesResponse']['customAvpList'][
                    'item']):
            if val['attribute'] == 'message':
                customAvpListMessage = val['value']
                if customAvpListMessage == 'Subcriber does not exists in SPR':
                    return False, funcName + ':Subscriber with NTD ID = ' + ntdId + ' not found in Openet'

                elif customAvpListMessage == 'Success':
                    for key, val in enumerate(
                            openetSubInfo['soap:Envelope']['soap:Body']['ns2:GetSubscriberBalancesResponse'][
                                'balances']['item']):
                        if val['balanceType'] == 'Monthly':
                            monthlyBalance = val['balanceAvailable']
                            effectiveDate = val['effectiveDate']
                            expiryDate = val['expiryDate']
                            print('The Monthly Balance is --> ', monthlyBalance)
                            print('Balance effective from --> ', effectiveDate)
                            print('Balance expires --> ', expiryDate)
                            return monthlyBalance, effectiveDate, expiryDate

    except Exception as e:
        logger.error('An Error Occurred while checking OPENET:' + str(e))
        return False, funcName + ":" + str(e)


def checkSPR(macAddr):
    # Check SPR
    boApi = bo_api.BO_API_Lib()
    macAddrMod = macAddr.replace(":", "")
    sprSubs = boApi.getSprSubs("1", macAddrMod)
    funcName = sys._getframe().f_code.co_name
    try:
        if not "totalsubscribers" in sprSubs['soap:Envelope']['soap:Body']['getSubscribersResponse']:
            error = funcName + ":Return object from 'get spr subs' query does not have totalsubscribers field for mac address " + macAddr
            logger.error(error)
            return False, error
    except Exception as e:
        logger.error('An Error Occurred while retrieving totalSubscribers:' + str(e))
        return False, funcName + ":" + str(e)
    if sprSubs['soap:Envelope']['soap:Body']['getSubscribersResponse']['totalsubscribers'] == "0":
        print("no Subscribers found in SPR for given modem")
        error = funcName + ':No Subscribers found in SPR for given modem MAC ' + macAddr
        return False, error
    else:
        sprSubsId = sprSubs['soap:Envelope']['soap:Body']['getSubscribersResponse']['subscribers']['subscriber'][
            'subscriberid']
        print("SubscriberId Found in SPR", (sprSubsId))
        sprSubKey = sprSubs['soap:Envelope']['soap:Body']['getSubscribersResponse']['subscribers']['subscriber'][
            'subscriberkey']
        print("SubscriberKey Found in SPR", (sprSubKey))

    try:
        sprSubAttr = boApi.getSprSubAttr("1", sprSubKey)
        print ("\n============SPR Sub Attributes Status for============")
        print(sprSubAttr)
        for key, val in enumerate(
                sprSubAttr['soap:Envelope']['soap:Body']['getSubscriberResponse']['subscriber']['sprattributes'][
                    'sprattribute']):
            if val['name'] == 'packageId':
                sprSubAttrPackageId = val['value']
            elif val['name'] == 'status':
                sprSubAttrStatus = val['value']
            elif val['name'] == 'serviceProvider':
                sprSubAttrSatellite = val['value']
            elif val['name'] == 'billReset':
                sprSubAttrBillReset = val['value']
            elif val['name'] == 'videoDataSaverOption':
                sprSubAttrVDE = val['value']

        return sprSubAttrPackageId, sprSubAttrStatus, sprSubAttrSatellite, sprSubAttrBillReset, sprSubAttrVDE
    except Exception as e:
        error = funcName + ":An Error Occurred while retrieving SPR Attributes: " + str(e)
        return False, error


def getFsmWorkOrderServices(ntdId):
    boApi = bo_api.BO_API_Lib()
    # fsmCustomerToken = boApi.queryFSMCustomer(ntdId)
    services = {}
    fsmCustomerToken = 'f6ErpAwSPz85xb3ahnESyA'
    try:
        fsmWorkOrderByCustomerTokenInfo = boApi.getFSMWorkOrderByCustomerToken(fsmCustomerToken)
        print("\n============FSM WorkOrder============")
        # print(openetSubInfo)
        print(xmltodict.unparse(fsmWorkOrderByCustomerTokenInfo, pretty=True))

        for key, val in enumerate(fsmWorkOrderByCustomerTokenInfo['ns2:customerWorkOrders']['workOrder']['services'][
                                      'serviceUponCompletion']):
            print("boom")
            print(key, '=', val)
            return True
            #            if val['attribute'] == 'message':
            #                customAvpListMessage = val['value']
            #                if customAvpListMessage == 'Subcriber does not exists in SPR':
            #                    logger.info('Subscriber not found in Openet !')
            #                    logger.console('\nSubscriber not found in Openet !')
            #                    return False

            #                elif customAvpListMessage == 'Success':
            #                    for key, val in enumerate(openetSubInfo['soap:Envelope']['soap:Body']['ns2:GetSubscriberBalancesResponse']['balances']['item']):
            #                        if val['balanceType'] == 'Monthly':
            #                            monthlyBalance = val['balanceAvailable']
            #                            effectiveDate = val['effectiveDate']
            #                            expiryDate = val['expiryDate']
            #                            print('The Monthly Balance is --> ',monthlyBalance)
            #                            print('Balance effective from --> ',effectiveDate)
            #                            print('Balance expires --> ',expiryDate)
            #                            return monthlyBalance, effectiveDate, expiryDate

    except Exception as e:
        # print("An Error Occurred")
        logger.error('An Error Occurred while checking FSM')
        logger.error(e.message)
        return False


# transitionService
# \brief Changes service plan of given account to another service plan that is available. Available beams are dictated
#       by the physical location of the account. The address of the account is not changed in this so the only plans
#       available are those in beam of the account's location
# \param: serviceAgrRef - Service agreement number of account
#        targetPackage - Name of package/plan to change to
# \return: True if successfully executes, False if error occured
def transitionService(macAddr, targetPackage, user):
    # initialize api class
    boApi = bo_api.BO_API_Lib()

    print("\n============Running sdpApiGetDevice=============")
    # get mac without colons
    macAddrMod = macAddr.replace(":", "")
    apiOut = boApi.sdpApiGetDevice(macAddrMod)
    print(xmltodict.unparse(apiOut, pretty=True))

    serviceAgrRef = ""
    # grab data if it is there, if nothing is returned, then fail
    try:
        serviceAgrRef = apiOut['Devices']['FixedNTD']['id']
        print("Got Id from Device")
    except Exception as e:
        print("Get Device command did not return an Id")
        print(e.message)
        return False
    print("============End of sdpApiGetDevice============\n")

    logger.console("Running getUserOrganization")
    print("\n============Running getUserOrganization=============")
    getOrganizationResponse = []
    getOrganizationResponse = getUserOrganization(user)
    if getOrganizationResponse[0] == False:
        logger.info("Organization Name Retrieval failed, exiting")
        return False, sys._getframe().f_code.co_name + ":" + getOrganizationResponse[1]
    organization = getOrganizationResponse
    logger.console("returned from getUserOrganization")

    print("\n============Running findSubscriberBySearchCriteria=============")
    apiOut = boApi.findSubscriberBySearchCriteria("WildBlue", "devteamall", serviceAgrRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error and grab data
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse'][
            'ns2:errorsOccured'] != 'false':
            print("Call returned 'errorsOccured'")
            return False
        extSysName = \
        apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:externalSystemName']
        extAcctRef = \
        apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber'][
            'ns2:account']['ns2:externalAccountReference']
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False
    print("============End of findSubscriberBySearchCriteria============\n")

    print("\n============Running getAllAccountServicesAndReferences=============")
    apiOut = boApi.getAllAccountServicesAndReferences(extSysName, extAcctRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error and grab data
    try:
        if not "ns2:accountServiceAndReference" in apiOut['soap:Envelope']['soap:Body'][
            'ns2:getAllAccountServicesAndReferencesResponse']:
            print("Return object is empty")
            return False
    except Exception as e:
        print("An Error Occurred")
        print(e.message)
        return False
    pack = ""
    acctID = ""
    servItemRef = ""

    # check if return is list of multiple dict or just one dict, so does not crash
    # might need to be optimized
    if isinstance(apiOut['soap:Envelope']['soap:Body']['ns2:getAllAccountServicesAndReferencesResponse'][
                      'ns2:accountServiceAndReference'], list):
        acctServRef = apiOut['soap:Envelope']['soap:Body']['ns2:getAllAccountServicesAndReferencesResponse'][
            'ns2:accountServiceAndReference']
    else:
        acctServRef = []
        acctServRef.append(apiOut['soap:Envelope']['soap:Body']['ns2:getAllAccountServicesAndReferencesResponse'][
                               'ns2:accountServiceAndReference'])

    for ref in acctServRef:
        if ref['ns2:accountService']['ns2:type'] == "INTERNET_ACCESS_SERVICE" and ref['ns2:accountService'][
            'ns2:status'] == "ACTIVE":
            pack = ref['ns2:accountService']['ns2:name']
            acctID = ref['ns2:accountService']['ns2:id']
            servItemRef = ref['ns2:serviceItemReference']
            break
    # package to change to not same as current package
    if pack == targetPackage:
        print("please choose different package than already active package")
        return False
    print("Current service info:")
    print(pack)
    print(acctID)
    print(servItemRef)
    print("============End of getAllAccountServicesAndReferences============\n")

    print("\n============Running getTransitionPackages=============")
    apiOut = boApi.getTransitionPackages(extSysName, extAcctRef)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error and grab data
    try:
        if not "ns4:package" in apiOut['soap:Envelope']['soap:Body']['ns4:getTransitionPackagesResponse']:
            print("Return object did not return expected field")
            return False
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False

    # parse through to get service information for desired package
    randNum = ""  # generate random number used for name and id
    for x in range(0, 9):
        randNum += str(random.randint(0, 9))
    print(randNum)
    randID = "3" + randNum + "1"
    count = 0
    service = ""
    for pack in apiOut['soap:Envelope']['soap:Body']['ns4:getTransitionPackagesResponse']['ns4:package']:
        print(pack['ns4:displayName'])
        if pack['ns4:displayName'] == targetPackage:
            print("found desired package")
            for opt in pack['ns4:optionGroup']:
                packageItemType = opt['ns4:packageItem']['ns4:itemType']
                if packageItemType == "INTERNET_ACCESS_SERVICE":
                    print("GOT HERE")
                    packageItemName = opt['ns4:packageItem']['ns4:displayName']
                    packageItemPriceType = opt['ns4:packageItem']['ns4:priceType']
                    packageItemRef = opt['ns4:packageItem']['ns4:packageItemReference']
                    price = opt['ns4:packageItem']['ns4:packageItemPrice']['ns4:price']
                    service = "<To><ServiceReference>" + randID + "</ServiceReference><Name>" + packageItemName + "</Name><Type>" + packageItemType + "</Type><CatalogNumber>" + packageItemRef + "</CatalogNumber></To>"
                    randID += "1"
    print(service)
    print("============End of getTransitionPackages============\n")

    print("\n============Running updateService=============")
    curDate = time.strftime("%Y-%m-%dZ", time.localtime())
    print("Target Service Input: " + service)
    apiOut = boApi.updateService(extSysName, extSysName, randNum, "QAADMIN", "QAADMIN", curDate, extAcctRef,
                                 servItemRef, service)
    print(xmltodict.unparse(apiOut, pretty=True))
    # check if returned error
    try:
        if apiOut['Response']['ResponseStatus']['ErrorCode']['#text'] != "SUCCESS":
            print("ResponseStatus returned non successfully")
            return False
        elif apiOut['Response']['Transaction']['OrderStatus']['OrderStatus'] != "ACCEPTED":
            print("Order was not accepted by system")
            return False
    except Exception as e:
        print('An Error Occured')
        print(e.message)
        return False
    print("============End of updateService============\n")

    print("\n============Running getSoaTransactionsByExtAccRef=============")
    # getSoaTransactionsByExtAccRef
    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running Call: " + str(count))
        apiOut = boApi.getSoaTransactionsByExtAccRef(extSysName, extAcctRef)
        print(xmltodict.unparse(apiOut, pretty=True))
        try:
            transitionStatus = \
            apiOut['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse'][
                'soaTransaction']['transactionStatusName']
        except Exception as e:
            print("An Error Occured")
            print(e.message)
            return False
        print("current transition status " + transitionStatus)
        if transitionStatus == "DISPATCHED" or transitionStatus == "COMPLETE":
            print("transition status is in dispatch or complete")
            break
        elif transitionStatus == "ERROR":
            print("Transition status is in ERROR")
            return False
        count += 1
        time.sleep(5)
    if count >= 60:
        print("created customer account not in dispatch or complete status")
        return False
    else:
        print("customer account in dispactch or complete status")
    print("============End of getSoaTransactionsByExtAccRef============\n")

    print("Finished Running Transition Service")
    return True


def checkFSM(ntdId):
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    fsmOrderToken = boApi.queryFSMCustomer(ntdId)
    logger.console('\nFSM WorkOrder Token Retrieved from DB --> ' + str(fsmOrderToken))
    # fsmOrderToken = 'f6ErpAwSPz85xb3ahnESyB'
    fsmOrderInfo = boApi.getFSMWorkOrderByCustomerToken(fsmOrderToken)
    logger.info('response is:')
    logger.info(fsmOrderInfo)
    if "ns2:validationFailures" in fsmOrderInfo:
        validationFailureMessage = fsmOrderInfo['ns2:validationFailures']['failure']
        logger.info('FSM WorkOrder Not Found !\nGot Response --> ' + str(validationFailureMessage))
        logger.console('\nFSM WorkOrder Not Found !\nGot Response --> ' + str(validationFailureMessage))
        return False, funcName + "FSM WorkOrder Not Found !\nGot Response --> " + str(validationFailureMessage)
    elif fsmOrderInfo['ns2:customerWorkorders']['workOrder'] != '':
        orderStatus = fsmOrderInfo['ns2:customerWorkorders']['workOrder']['orderStatus']
        externalOrderId = fsmOrderInfo['ns2:customerWorkorders']['workOrder']['externalOrderId']
        services = fsmOrderInfo['ns2:customerWorkorders']['workOrder']['services']
        equipment = fsmOrderInfo['ns2:customerWorkorders']['workOrder']['equipment']
        logger.info('Order Status -->' + str(orderStatus) + '\n' + 'ExternalOrderId -->' + str(
            externalOrderId) + '\n' + 'List of Services -->' + str(services) + '\n' + 'List of Equipment -->' + str(
            equipment))
        logger.console('Order Status -->' + str(orderStatus) + '\n' + 'ExternalOrderId -->' + str(
            externalOrderId) + '\n' + 'List of Services -->' + str(services) + '\n' + 'List of Equipment -->' + str(
            equipment))
        return True, orderStatus, externalOrderId, services, equipment



def addServiceCallToAccount(username, application, accountReference, externalSystem, externalTransactionReference, internalServiceAgreementReference, serviceCallType, notes, soldBy, enteredBy, externalAccountReference):
    print("\n============Running addServiceCallToAccount============")
    print("Using Account: " + accountReference)
    # initialize api class
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    print("\n============Running getServiceCallTypesByAccount============")
    apiOut = boApi.getServiceCallTypesByAccount(username, application,  accountReference)
    print(xmltodict.unparse(apiOut, pretty=True))
    print('------------------getServiceCallTypesByAccountResponse--------------------')
    print("============End of getServiceCallTypesByAccount============\n")
    # check if returned error and grab data
    # Validate that the given service call type is returned in the getServiceCallTypesByAccountResponse
    print('\n============Running addServiceCall============')
    try:
        for key, value in enumerate(apiOut['soap:Envelope']['soap:Body']['ns4:getServiceCallTypesByAccountResponse']['ns4:serviceCallType']):
            #print("Looking for " + serviceCallType + " in response")
            if serviceCallType == value['ns4:name']:
                print("Using Service Call Type: " + serviceCallType)
                apiOut = boApi.addServiceCall(username, application, externalSystem, externalTransactionReference, internalServiceAgreementReference, serviceCallType, notes, soldBy, enteredBy)
                print(xmltodict.unparse(apiOut, pretty=True))
                print('------------------addServiceCallResponse--------------------')
                compositeInstanceCreatedTime = apiOut['env:Envelope']['env:Header']['wsa:FaultTo']['wsa:ReferenceParameters']['instra:tracking.compositeInstanceCreatedTime']
                logger.console(compositeInstanceCreatedTime)


    except Exception as e:
        print("----------EXCEPTION----------")
        return False, funcName + " An Exception Occurred: " + str(e)

    print("\n============Running getSoaTransactionsByExtAccRef=============")
    # getSoaTransactionsByExtAccRef
    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running Call: " + str(count))
        apiOut = boApi.getSoaTransactionsByExtAccRef(externalSystem, externalAccountReference)
        print(xmltodict.unparse(apiOut, pretty=True))
        try:
            print("----------Try getSoaTransactionsByExtAccRef----------")
            print(externalAccountReference)
            serviceCallStatus = apiOut['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse']['soaTransaction']['transactionStatusName']
        except Exception as e:
            print("An Error Occured")
            print(e.message)
            return False, funcName + " An Exception Occurred: " + str(e)
        print("Current Service Call Status " + serviceCallStatus)
        if serviceCallStatus == "DISPATCHED":
            logger.console("Service Call status is in Complete Status")
            print("============End of getSoaTransactionsByExtAccRef============\n")
            return True, compositeInstanceCreatedTime
        elif serviceCallStatus == "ERROR":
            print("Service Call status is in ERROR")
            return False, funcName + " Service Call status is in Error: "
        count += 1
        time.sleep(5)
    if count >= 60:
        print("service call status not in complete status")
        return False, funcName + " Service Call Exceeded 5 min count"
    else:
        print("service call in dispactch status")

def getRecentPlan(productList):
    """
    Method Name :  getRecentPlan
    Parameters  :  productList
    Description :  Finds out the recent plan
    return      :  recentProduct
    """
    oldestTs= datetime.now() - timedelta(days=3650)
    for product in productList:
        #print (product)
        #print ("field date is")
        #print (product.get('date'))
        parsedDate = product.get('date')
        if parsedDate > str(oldestTs):
            mostRecentDate = parsedDate
            oldestTs = parsedDate
            #print ("mostrecentdate is:")
            #print (mostRecentDate)
            recentProduct = product
            #print ("oldestTs is:")
            #print (oldestTs)

    print ("most recent product is:")
    print (recentProduct)
    return recentProduct

def closeServiceCall(username, application, workOrderReference, externalTransactionReference, externalSystem, externalAccountReference):
    print("\n-----------Running closeServiceCall----------")
    # initiate api class
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    try:
        print("----------LIB TRY----------")
        apiOut = boApi.closeServiceCall(username, application, workOrderReference, externalTransactionReference)
        print("----------LIB APIOUT----------")
        print(xmltodict.unparse(apiOut, pretty=True))
        print("----------closeServiceCallResponse----------")
        compositeInstanceCreatedTime = apiOut['env:Envelope']['env:Header']['wsa:FaultTo']['wsa:ReferenceParameters']['instra:tracking.compositeInstanceCreatedTime']
        logger.console(compositeInstanceCreatedTime)

    except Exception as e:
        print("----------EXCEPTION----------")
        return False, funcName + " An Exception Occurred: " + str(e)

    print("\n============Running getSoaTransactionsByExtAccRef=============")
    # getSoaTransactionsByExtAccRef
    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running Call: " + str(count))
        apiOut = boApi.getSoaTransactionsByExtAccRef(externalSystem, externalAccountReference)
        print(xmltodict.unparse(apiOut, pretty=True))
        try:
            print("----------Try getSoaTransactionsByExtAccRef----------")
            print(externalAccountReference)
            serviceCallStatus = apiOut['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse']['soaTransaction']['transactionStatusName']
        except Exception as e:
            print("An Error Occured")
            print(e.message)
            return False, funcName + " An Exception Occurred: " + str(e)
        print("Current Service Call Status " + serviceCallStatus)
        if serviceCallStatus == "COMPLETE":
            logger.console("Service Call status is in Complete Status")
            print("============End of getSoaTransactionsByExtAccRef============\n")
            return True, compositeInstanceCreatedTime
        elif serviceCallStatus == "ERROR":
            print("Service Call status is in ERROR")
            return False, funcName + " Service Call status is in Error: "
        count += 1
        time.sleep(5)
    if count >= 60:
        print("service call status not in complete status")
        return False, funcName + " Service Call Exceeded 5 min count"
    else:
        print("service call in complete status")


def cancelServiceCall(username, application, externalSystem, externalTransactionReference, victimTransactionRef, externalAccountReference):
    print("\n-----------Running cancelServiceCall----------")
    #initiate api class
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    try:
        print("----------TRY----------")
        apiOut = boApi.cancelServiceCall(username, application, externalSystem, externalTransactionReference, victimTransactionRef)
        print("----------APIOUT----------")
        print(xmltodict.unparse(apiOut, pretty=True))
        print("----------cancelServiceCallResponse----------")
        compositeInstanceCreatedTime = apiOut['env:Envelope']['env:Header']['wsa:FaultTo']['wsa:ReferenceParameters']['instra:tracking.compositeInstanceCreatedTime']
        logger.console(compositeInstanceCreatedTime)

    except Exception as e:
        print("----------EXCEPTION----------")
        return False, funcName + " An Exception Occurred: " + str(e)

    print("\n============Running getSoaTransactionsByExtAccRef=============")
    # getSoaTransactionsByExtAccRef
    # run multiple cause might take some time for information to propogate through
    count = 0  # give 5 mins to go to dispatched
    while count < 60:
        print("Running Call: " + str(count))
        apiOut = boApi.getSoaTransactionsByExtAccRef(externalSystem, externalAccountReference)
        print(xmltodict.unparse(apiOut, pretty=True))
        try:
            print("----------Try getSoaTransactionsByExtAccRef----------")
            print(externalAccountReference)
            serviceCallStatus = apiOut['soap:Envelope']['soap:Body']['ns4:getSoaTransactionsByExternalAccountReferenceResponse']['soaTransaction']['transactionStatusName']
        except Exception as e:
            print("An Error Occurred")
            print(e.message)
            return False, funcName + " An Exception Occurred: " + str(e)
        print("Current Service Call Status " + serviceCallStatus)
        if serviceCallStatus == "COMPLETE":
            logger.console("Service Call status is in Complete Status")
            print("============End of getSoaTransactionsByExtAccRef============\n")
            return True, compositeInstanceCreatedTime
        elif serviceCallStatus == "ERROR":
            print("Service Call status is in ERROR")
            return False, funcName + " Service Call status is in Error: "
        count += 1
        time.sleep(5)
    if count >= 60:
        print("service call status not in complete status")
        return False, funcName + " Service Call Exceeded 5 min count"
    else:
        print("service call in dispatch or complete status")
        
        

def getVideoDataSaver(serviceAgreementReference):
    print("\n===========Running Get Video Data Saver Option===========")
    # initiate api class
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    logger.info("Running Get Video Data Saver Option")
    try:
        returnObj = boApi.getVideoDataSaverOption(serviceAgreementReference)
        videoDataSaverOption = returnObj['soap:Envelope']['soap:Body']['ns4:getVideoDataSaverOptionResponse']['ns4:videoDataSaverOption']
        logger.console('Video Data Saver Option = ' + videoDataSaverOption)
        logger.info('Video Data Saver Option = ' + videoDataSaverOption)
        return True, videoDataSaverOption
    except Exception as e:
        logger.console('Fault Occurred')
        logger.error('Fault Occurred')
        node = returnObj['soap:Envelope']['soap:Body']['soap:Fault']['detail']['ns3:faultDetail']['ns3:node']
        logger.console('Node: ' + node)
        logger.error('Node: ' + node)
        trackingKey = returnObj['soap:Envelope']['soap:Body']['soap:Fault']['detail']['ns3:faultDetail']['ns3:trackingKey']
        logger.console('Tracking Key: ' + trackingKey)
        logger.error('Tracking Key: ' + trackingKey)
        message = returnObj['soap:Envelope']['soap:Body']['soap:Fault']['detail']['ns3:faultDetail']['ns3:message']
        logger.console('Error Message: ' + message)
        logger.error('Error Message: ' + message)
        return False, funcName + ' Error in fetching video data saver option ' + str(e)

def updateVideoDataSaver(serviceAgreementReference, videoDataSaverOption):
    print("\n===========Running Update Video Data Saver Option===========")
    # Initiate api class
    boApi = bo_api.BO_API_Lib()
    funcName = sys._getframe().f_code.co_name
    logger.info("Running Update Video Data Saver Option")
    try:
        print('Trying Update Option')
        returnObj = boApi.updateVideoDataSaverOption(serviceAgreementReference, videoDataSaverOption)
        updateVideoDataSaverOptionResult = returnObj['soap:Envelope']['soap:Body']['ns4:updateVideoDataSaverOptionResponse']['ns4:result']
        logger.console('The update returned ' + updateVideoDataSaverOptionResult)
        logger.info('The Video Data Saver Option was updated ' + updateVideoDataSaverOptionResult)
        return True, updateVideoDataSaverOptionResult
    except Exception as e:
        logger.console('Fault Occurred')
        logger.error('Fault Occurred')
        node = returnObj['soap:Envelope']['soap:Body']['soap:Fault']['detail']['ns3:faultDetail']['ns3:node']
        logger.console('Node: ' + node)
        logger.error('Node: ' + node)
        trackingKey = returnObj['soap:Envelope']['soap:Body']['soap:Fault']['detail']['ns3:faultDetail']['ns3:trackingKey']
        logger.console('Tracking Key: ' + trackingKey)
        logger.error('Tracking Key: ' + trackingKey)
        message = returnObj['soap:Envelope']['soap:Body']['soap:Fault']['detail']['ns3:faultDetail']['ns3:message']
        logger.console('Error Message: ' + message)
        logger.error('Error Message: ' + message)
        return False, funcName + ' Error in fetching video data saver option ' + str(e)
