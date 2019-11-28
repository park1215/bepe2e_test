from robot.api import logger
import os
import json
import re

def getSDFIDList(utstatWOutput):
    copy = False
    line = ""
    sdfids = []
    for character in utstatWOutput:
        if character == '\n':
            if copy:
                if "|" not in line:
                    break   
                columns= line.split("|")
                try:
                    result = columns[9].strip()
                except Exception as e:
                    logger.error('problem with split: '+str(e))
                sdfids.append(int(result))
            elif "SDFID" in line:               
                copy = True        
            line = ""
        else:
            line += character
    return sdfids

def compareSDFIDs(modemSDFIDs,servicePlan,modemType,suspend=False):
    result = True
    f = open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'../service_catalog.json'),"r")
    ids = f.read()
    ids = re.sub("'",'"', ids)
    servicePlanSDFIDs = json.loads(ids)
    # convert service plan name as specified in back office to service plan name in edn file
    if modemType=='DATA' or modemType=='SPOCK':
        if not suspend:
            servicePlan = "V2 "+servicePlan
    if "GB" in servicePlan:
        servicePlan = servicePlan.replace(" Metered","")
        servicePlan = servicePlan = servicePlan + " 35 Mbps"
    expectedSDFIDs = servicePlanSDFIDs[servicePlan]
    logger.info('edn service plan = '+servicePlan)
    logger.info('bpsdfids = '+str(expectedSDFIDs))
    error = ''
    for id in expectedSDFIDs:
        if id not in modemSDFIDs:
            error = error + '\n' + str(id) + ' is missing from modem SDFID'
            result = False
    for id in modemSDFIDs:
        if id not in expectedSDFIDs:
            error = error + '\n' + str(id) + ' is unexpectedly present in modem SDFID'
            result = False
    return  result, error
           
def getPlanName(servicePlan,modemType,suspend=False):
    logger.console('getPlanName input servicePlan is:' + servicePlan)
    result = True
    f = open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'../service_catalog.json'),"r")
    ids = f.read()
    ids = re.sub("'",'"', ids)
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

