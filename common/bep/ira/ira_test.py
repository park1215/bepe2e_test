import os,sys, random
import logging
import ira_api
import ira_parameters
import bep_common
import json
from json import loads, dumps
from requests.packages.urllib3.exceptions import InsecureRequestWarning
#import wifi_params as wifi_params

def run():

    iraApi = ira_api.IRA_API_LIB()
    comBep = bep_common.BEP_API()
    url = ira_parameters.IRA_JWT_URL
    #token = comBep.getBepJwtToken(url)
    fullName = "BEP TEST 05032019-1"
    newFullName = "BEPE2E TEST 1"
    groups = ira_parameters.IRA_TEST_GROUPS
    email = "bepe2e_may_03_01@viasat.io"
    phoneNumber="+559196078953"
    #partyId = "1bf3b634-e0f6-4844-b9e8-b849b64fc087"
    addressLines = ["349 Inverness Dr S", "Building D11", "Office 3060"]
    municipality = "Englewood"
    region = "Colorado"
    postalCode = "80112"
    countryCode = "US"
    #partyId = '75b6fbdc-7a55-4ffe-9183-98f57d54bafb'
    #partyId = 'b99bd094-036b-430f-b3e1-17034bc40a81'
#    partyId = '2fce5627-0b7f-4e74-9dde-df6622ecb18d'
#    relnId = "49d1baed-ace2-4bdf-9f48-d446986c23f7"
    relnId = "8c064a89-ede0-4aaf-9fa5-c67f7d6a2a0e"

    ### Add Individual ####
    status, response = iraApi.addIndividual(fullName, groups)
    print(response)
    partyId = response['data']['addIndividual']['partyId']
    print(partyId)

    '''
    ### Get Party ####
    status, response = iraApi.getParty(partyId)
    print(response)
    '''

    ### Add and get Email ###
    email = "bepe2e" + str(random.randint(1, 999999)) + "@viasat.io"
    print(email)
    status, response = iraApi.addEmailContactMethod(partyId,email)
    print(response)
    status, response = iraApi.getEmailContactMethodFromParty(partyId)
    print(response)

    ### Add and get phone ####
    phoneNumber = "+" + "55" + str(random.randint(1000000000, 9999999999))
    print(phoneNumber)
    status, response = iraApi.addPhoneContactMethod(partyId,phoneNumber)
    status, response = iraApi.getPhoneContactMethodFromParty(partyId)
    status, response = iraApi.getPartyVersion(partyId)
    print(response)

    ### Add and get address ###
    status, response = iraApi.addAddressContactMethod(partyId, json.dumps(addressLines), municipality, region, postalCode, countryCode)
    print(response)
    status, response = iraApi.getAddressContactMethodFromParty(partyId)
    print(response)

    ### Get Party ###
    status, response = iraApi.getParty(partyId)
    print(response)
    contactMethods = response['data']['getParty']['contactMethods']
    contactMethodIds = []
    for contactMethod in contactMethods:
        contactMethodId = contactMethod["contactMethodId"]
        contactMethodIds.append(contactMethodId)

    print("final list of contact method ids is:")
    print(contactMethodIds)


    '''
#    status, response = iraApi.addCustomerRelationship(partyId, ira_parameters.IRA_MEX_PROVIDER_GROUP, ira_parameters.IRA_MEX_PROVIDER_ID)
    #status, response = iraApi.addPayerRole(partyId, relnId)
    #status, response = iraApi.getRelationship(relnId)
    #print(response)
    '''

    '''
    ### Test getPartyByExternalId ###
    externalId = "beptest_5fce"
    typeName ="viasat_my_sso_ldap"
    status, response = iraApi.getPartyByExternalId(externalId, typeName)
    print(status)
    print(response)
    '''
    
    '''
    ### Test addExternalId ###
    partyId = "43c447f7-7f37-4a97-bf5e-48b268f95fce"
    typeName ="viasat_my_sso_ldap"
    value = "beptest_" + str(random.randint(1,999999))
    status, response = iraApi.addExternalId(partyId, typeName, value)
    print(status)
    print(response)
    '''

    ### Test deleteContactMethod ###
    for contactMethodId in contactMethodIds:
        status, response = iraApi.deleteContactMethod(contactMethodId)
        print(status)
        print(response)






run()
