import os,sys
import logging
import psm_api
import psm_parameters
import bep_common
import json
from json import loads, dumps
from requests.packages.urllib3.exceptions import InsecureRequestWarning
#import wifi_params as wifi_params

def run():

    psmApi = psm_api.PSM_API_LIB()
    #comBep = bep_common.BEP_API()
    url = psm_parameters.PSM_JWT_URL
    #PID = "acdb0b63-cee9-45fd-8917-94d6858a1048"
    PID = "e61a70be-2b46-40ec-8baa-ecb4a1795408"
    #PRID = "455d9732-05ea-4f36-b928-21f4805de070"
    #status, response = psmApi.upsertProductInstance(PRID)
    #PID = response['data']['UpsertProductInstance']['productInstanceId']
    #print(PID)
    status, response = psmApi.getProductInstance(PID)
    #print(response)
    response = psmApi.createPom2PsmDict(response)
    print(response)

run()
