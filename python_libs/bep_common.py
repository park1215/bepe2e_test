import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import secrets
import sys
import json
from json import loads, dumps
import os
import time
import bep_parameters
from robot.api import logger
import uuid
from credentials import *
INITIAL_JSON_INDENT=4

class BEP_API:
    #Common Functions that can be used by other domain component focussed API files
    def getBepJwtToken(self, url):
        
        user=BEPE2E_SERVICE_ACCOUNT_USER
        pwd=BEPE2E_SERVICE_ACCOUNT_PWD

        r = requests.get(url, verify=False, auth=(user, pwd))
        return r.status_code, r.text

def logOutput(message,medium):
    if medium=='console':
        logger.console(message)
    else:
        logger.info(message)
def outputJson(jsondata,indent=INITIAL_JSON_INDENT,medium='console'):
    indent = int(indent)
    if indent == INITIAL_JSON_INDENT:
        logOutput('-----',medium)
    keySpaces = ' '
    for i in range(1,indent):
        keySpaces = keySpaces + ' '   
    valueSpaces = keySpaces
    for i in range(0,4):
        valueSpaces = valueSpaces + ' '
    if isinstance(jsondata,list):
        for item in jsondata:
            if isinstance(item,dict) or isinstance(item,list):
                indent2 = indent + INITIAL_JSON_INDENT
                outputJson(item,indent2,medium)           
            else:
                logOutput(keySpaces + str(item),medium)
    else:
        for key in jsondata.keys():
            logOutput(keySpaces + key + ":",medium)
            if isinstance(jsondata[key],dict) or isinstance(jsondata[key],list):
                indent2 = indent + INITIAL_JSON_INDENT
                outputJson(jsondata[key],indent2,medium)           
            else:
                logOutput(valueSpaces + str(jsondata[key]),medium)
    if indent == INITIAL_JSON_INDENT:
        logOutput('-----',medium)
    return

def createBEPHeader(token,extraHeaders={},needsExId=False):
    header = {'Content-type': 'application/json', 'Authorization': 'Bearer %s' %token}
    header = {**extraHeaders,**header}
    if needsExId==True:
        guid = str(uuid.uuid1())
        header['X-BEP-Execution-Id'] = guid
    return header

def logAPI(url, header, payload, info=True, console=False):
    if info==True:
        logger.info("url="+url)
        if header !='': logger.info("header="+header)
        logger.info("payload="+payload)
    if console==True:
        logger.console("url="+url)
        if header !='':logger.console("header="+header)
        logger.console("payload="+payload)       

def AddVariables(*argv):
    logger.info(argv)
    addedValue= sum(argv)
    roundedValue = round(addedValue, 2)
    return roundedValue

'''
    ids = f.read()
    #ids = re.sub("'",'"', ids)
    # convert service plan name as specified in back office to service plan name in edn file
    #logger.info('input service plan = ' + servicePlan)
    if modemType=='DATA' or modemType=='SPOCK' or modemType=='AB':
        #logger.info('data modem')
        if not suspend:
            #logger.info('not suspend')
            servicePlan = "V2 "+servicePlan
            logger.info('service plan1 is:' + servicePlan)
    if "GB" in servicePlan:
        #logger.info('GB in plan')
        servicePlan = servicePlan.replace(" Metered","")
        logger.info('added metered in plan:' + servicePlan)
        servicePlan = servicePlan = servicePlan + " 35 Mbps"
        #logger.info('added 35mb in plan:' + servicePlan)
    logger.info('edn service plan = '+servicePlan)
    return    servicePlan

'''
# recursively converts string into nested lists with different delimiters at each level. Doesn't work if delimiters are same at different levels.
def convertStringToList(inputs,delimiters,index,outputList):
    if hasattr(inputs[0],'decode'):
        inputs[0] = inputs[0].decode()
    index = int(index)       
    for entry in inputs:
        newEntry = entry.split(delimiters[index])
        if index==len(delimiters)-1:
            outputList.append(newEntry)
        else:    
            outputList = convertStringToList(newEntry,delimiters,index+1,outputList)
    return outputList    
        
def createDictionaryFromLists(keys,values):
    newDict = {}
    index = 0
    for key in keys:
        newDict[key] = values[index]
        index = index + 1
    return newDict

def findMatchInListOfLists(inputList,index,matchValue):
    index = int(index)
    for entry in inputList:
        if float(entry[index])==float(matchValue):
            return True
    return False

def waitForInput():
    input("Press Enter to continue...")