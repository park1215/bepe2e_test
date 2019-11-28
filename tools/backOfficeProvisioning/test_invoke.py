# Backoffice 
# Written by Azeem Dingankar leveraging scripts/libraries by Charles Hu
import time, datetime
import os,sys
import logging
#sys.path.insert(0, '../lib/backofficeProvisioningAutomation')
import backofficeLibrary as bo_lib
import backofficeAPI as bo_api
import xmltodict
import params as test_params
# Reads in parameters  from file

def createAccount():
    boApi = bo_api.BO_API_Lib()
    serviceAgrNum = bo_lib.createAccount(test_params.servicePlan, test_params.address, test_params.city, test_params.state, test_params.zipcode, test_params.salesChannel, test_params.requestor, test_params.orderSoldBy, test_params.orderEnteredBy, test_params.customerType, test_params.systemID)
    if not serviceAgrNum:
        logging.info("Account creation failed, exiting")
        return False

# Resolve Installation is call through which we associate modemMac to new Account

    apiOut = boApi.findSubscriberBySearchCriteria("WildBlue", "devteamall", serviceAgrNum)
    print(xmltodict.unparse(apiOut, pretty=True))
    #check if returned error and grab data
    try:
        if apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:errorsOccured'] != 'false':
            print("Call returned 'errorsOccured'")
            return False
        intAccRef = apiOut['soap:Envelope']['soap:Body']['ns2:findSubscribersBySearchCriteriaResponse']['ns2:subscriber']['ns2:account']['ns2:internalAccountReference']
        return True, intAccRef
    except Exception as e:
        print("An Error Occurred")
        print(e)
        return False

def provisionModem(macAddr, intAccRef):
    boApi = bo_api.BO_API_Lib()
    apiOut = boApi.resolveInstallation(macAddr, intAccRef)
    print(xmltodict.unparse(apiOut, pretty=True))
   #check if returned error and grab data
    try:
        if not apiOut['soap:Envelope']['soap:Body']['ns3:resolveInstallationResponse']['ns3:status']:
            print("Call returned 'errorsOccured'")
            errorCode = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:code']
            errorReason = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:reason']
            errorDetail = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:Detail']
            errorNode = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:node']
            errorTrackingKey = apiOut['soap:Envelope']['soap:Body']['soap:Fault:']['detail']['ns4:ExceptionDetail']['ns4:trackingKey']
        else:
            print("Modem successfully Provisioned")
            return True
    except Exception as e:
        print("An Error Occured")
        print(e.message)
        return False    

def cleanUpLogicalBeamId(macAddr):
    boApi = bo_api.BO_API_Lib()
    apiOut = boApi.cmtApiLogicalBeamDeletion(macAddr)
    print (apiOut)
    #print(xmltodict.unparse(apiOut, pretty=True))
    try:
       print("Got Id from Device : ",(apiOut))
    except Exception as e:
       print("Get Device command did not return an Id")
       print(e.message)
       return False

def disconnectAccount(macAddr):
#Disconnect Account
    completeStat = bo_lib.disconnectAccount(macAddr)
    if not completeStat:
        logging.info("Account creation failed, exiting")
        return False
    #logging.info("============Starting provisioning for %s============" % modem)
    print("##############Disconnect Account Process Complete##############")
    #MAC Cleanup for disconnected account
    completeStat = bo_lib.macCleanUp(macAddr)
    if not completeStat:
        logging.info("Unable to provision modem with account")
        return False
    print("##############Modem MAC Clean-Up Process Complete##############")
    return True

def checkOpenet(sprSubsId):
    boApi = bo_api.BO_API_Lib()
    openetSubInfo = boApi.getOpenetSubBalReq(sprSubsId)
    print("\n============OPENET Sub Attributes Status for============")
    print(xmltodict.unparse(openetSubInfo, pretty=True))

def getSDPStatus(macAddr):
    boApi = bo_api.BO_API_Lib()
    deviceStatus = boApi.sdpApiGetDevice(macAddr)
    print("============Device Status for ============\n" )
    print(xmltodict.unparse(deviceStatus, pretty=True))
    if "FixedNTD" in deviceStatus['Devices']:
        if "id" in deviceStatus['Devices']['FixedNTD']:
            serviceAgr = deviceStatus['Devices']['FixedNTD']['id']
            serviceStatus = boApi.sdpApiGetService(serviceAgr)
            print ("\n============Service Status for============")
            print("Disconnect Account Status", (completeStat))
            print(xmltodict.unparse(serviceStatus, pretty=True))
    
def run():
    #initialize api class
    boApi = bo_api.BO_API_Lib()
#    modem = "00A0BC7646A8"
#    modem_colon = "00:A0:BC:76:46:A8"
#    testType = "DOWNLOAD"
#    modem = "00A0BC6C7D6A"
#    modem_colon = "00:A0:BC:6C:7D:EE"
    #modem_colon = "00:A0:BC:6E:B2:9C"
    intAccRef = '302783153'
    #ntd_id = '403002604'
#    ntd_id = '403003824'
#    jobId = "3955"
#    modem = '00A0BC46FDEE'
    #modem_colon = '00:A0:BC:6E:B2:F4'
#    modem_colon = '00A0BC6C:7D:6A' 
    #Get Device Status
    #bo_lib.checkOpenet(modem_colon)
#    systemID = 'WB_DIRECT'
#    orderReference = '01546835575128'
#    apiOut = boApi.queryWBA(systemID, orderReference)
#    print(apiOut)
#    serviceAgreementId = '403008142'
#    apiOut = boApi.queryFSMCustomer(serviceAgreementId)
#    print(apiOut)
    #fsmCustomerToken = 'f6ErpAwSPz85xb3ahnESyA'
#    status = bo_lib.getFsmWorkOrderServices(ntd_id)
    #apiOut = boApi.getFSMWorkOrderByCustomerToken(fsmCustomerToken)
    #dbCall = boApi.queryWBAforInternalAccountReference('BEPE2E1560296123','BEPE2E1560296123')
    #dbCall = boApi.queryWBAforInternalAccountReference('de8c08e7-b535-4968-8ba1-f9212e7e9d97','de8c08e7-b535-4968-8ba1-f9212e7e9d97')
    #print(dbCall)
    #print(apiOut)
#    fsmStatus = bo_lib.checkFSM(serviceAgreementId)
#    createStatus, intAccRef = createAccount()
#    provstatus = provisionModem(modem_colon,intAccRef)
#    provstatus = bo_lib.provisionModem2Account(modem_colon,intAccRef,'WB_DIRECT','23844463371831')
#    logicalStatus = cleanUpLogicalBeamId('00:A0:BC:4D:B8:A4')
#    cmtExecStatus = boApi.cmtApiCmdExecStatus(jobId)
#    cmtExecStatus = bo_lib.clearLogicalBeamId(modem)
#    speedTestExecutionStatus, speedMB = bo_lib.runModemSpeedTest(modem_colon,testType)
#    print("speedMB",(speedMB))
#    cleanUpStatus = bo_lib.macCleanUp(modem_colon)
#    deviceState = bo_lib.getDeviceState(modem_colon)
#    serviceState = bo_lib.getDeviceService(deviceState[1])
#    print("ntdId",(deviceState[1]))
#    print("deviceState",(deviceState[0]))
#    print("csaId",(deviceState[2]))
#    print("serviceId",(serviceState[0]))
#    print("serviceState",(serviceState[1]))
#    print("serviceCatalogId",(serviceState[2]))
#    sprPackage, sprStatus, sprSatellite, sprBillReset  = bo_lib.checkSPR(modem_colon)
#    print(sprPackage, sprStatus, sprSatellite, sprBillReset)
#    openetStatus = bo_lib.checkOpenet(sprSubInfo)      
#    sdpStatus = getSDPStatus(modem) 
#    disconnectStatus = bo_lib.disconnectAccount(modem_colon)
#    extSysName = "WB_DIRECT"
#    orderRef = "50963501252145"
#    try:
#        returnObj = boApi.queryWBA(extSysName, orderRef)
#    except Exception as e:
#        print("An Error Occurred with queryWBA call")
#        print(e.message)
#        return False
#    if not returnObj:
#        print("queryWBA returned empty")
#        return False
#    serviceAgreeNum = int(returnObj[0][11])
#    print(serviceAgreeNum)
#    print("============End of queryWBA============\n")
#    addServiceCallToAccounAPI = boApi.getServiceCallTypesByAccount(accountReference)
#    username = 'bepe2e_testapiqa'
#    print("Username: " + username)
#    application = int(round(time.time() * 1000))
#    application = str(application)
#    print("Application: " + application)
#    print("STARTING")
#    accountReference="302783145"
#    print("Account Reference: " + accountReference)
#    externalSystem = 'WB_DIRECT'
#    print('External Sytem: ' + externalSystem)
#    externalTransactionReference = str('BEP'+application)
#    print("External Transaction Reference: " + externalTransactionReference)
#    internalServiceAgreementReference = "403035754"
#    print('Service Agreement Reference: ' + internalServiceAgreementReference)
#    serviceCallType = "COMMERCIAL_SERVICE_CALL"
#    print("Service Call Type: " + serviceCallType)
#    externalAccountReference = "BEPE2E1553156416"
#    print("External Account Reference: " + externalAccountReference)
#    notes = application
#    print("Notes: " + str(notes))
#    soldBy = username
#    print("Sold By: " + soldBy)
#    enteredBy = username
#    print("Entered By: " + enteredBy)
#    workOrderReference = "WB_DIRECT/BEP1556138344412"
#    print("Work Order Reference: " + workOrderReference)
#    victimTransactionRef = "BEP1556138833254"
#    print("Victim Transaction Reference: " + victimTransactionRef)
#    status, response = bo_lib.addServiceCallToAccount(username, application, accountReference, externalSystem, externalTransactionReference, internalServiceAgreementReference, serviceCallType, notes, soldBy, enteredBy, externalAccountReference)
#    status, response = bo_lib.closeServiceCall('username', 'application', workOrderReference, externalTransactionReference, externalSystem, externalAccountReference)
    #status, response = bo_lib.cancelServiceCall(username, application, externalSystem, externalTransactionReference, victimTransactionRef, externalAccountReference)
#   print(response)
#    status, response = bo_lib.getVideoDataSaver('403045348')
#    print(response)
#    status, response = bo_lib.updateVideoDataSaver('403045348', 'TRUE')
#    boApi.updateVideoDataSaverOption('403045348', 'TRUE')
#    output = boApi.deactivateFixedNTD('403048527')
#    output = boApi.deleteOpenetSubscriber('100002072268268')
#    output = boApi.policyDeleteSubscriber('403048527')
    output = bo_lib.macCleanUp('00:A0:BC:6E:B2:F4', '4030490011')
    print(output)

run()

