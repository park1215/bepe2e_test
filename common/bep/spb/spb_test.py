import os,sys
import logging
import spb_api
import spb_parameters
import bep_common
import json
from json import loads, dumps
from requests.packages.urllib3.exceptions import InsecureRequestWarning
#import wifi_params as wifi_params

def run():

    spbApi = spb_api.SPB_API_LIB()
    #comBep = bep_common.BEP_API()
    url = spb_parameters.SPB_JWT_URL
    PID = "33412439-d681-44ec-b62c-666ac00b8f58"
    #status, response = spbApi.getProductInstance(PID)
    #print(response)

    status, response = spbApi.upsertProductInstance(PID)
    print(response)
run() 
