import urllib3
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys
from bep_parameters import *
import json
from json import loads, dumps
import os
import time
import copy
import bep_common
import re
from fo_common import *
from fo_parameters import *
from robot.api import logger
import xml.etree.ElementTree as ET

class FO_API_LIB:
    def getToken(self):
        comBep = bep_common.BEP_API()
        try:
            token = comBep.getBepJwtToken(FO_JWT_URL)
            if token[0]==200:                
                return True, token[1]
            else:
                return False, "token request status code = " + str(token[0])
        except Exception as e:
            return False, "Unable to retrieve FO API token: "+ str(e)

    def getAvailableAppointments(self,params):
        dates = params['dates']
        COUNTRY_CODE = params['country_code']
        funcName = sys._getframe().f_code.co_name
        address = copy.deepcopy(params['address'])
        if 'beam' in address:
            del address['beam']
        logger.console('address = '+str(address))
        addressInput = buildStringFromDict(address)
        input = {}

        input['serviceAddressInput'] = 'serviceLocation:'+addressInput
        input['orderType'] = 'orderType:"INSTALL"'
        input['fulfillmentPartnerPartyId'] = 'fulfillmentPartnerPartyId:"'+COUNTRY_VARIABLES[COUNTRY_CODE]["FULFILLMENT_PARTNER_ID"]+'"'
        if 'DEALER_ID' in COUNTRY_VARIABLES[COUNTRY_CODE]:
            input['dealerId'] = 'dealerId:"'+COUNTRY_VARIABLES[COUNTRY_CODE]["DEALER_ID"]+'"'
        else:
            input['dealerId'] = 'dealerId:"UNKNOWN"'
        input['from'] = 'from:"'+dates['from']+'"'
        input['to'] = 'to:"'+dates['to']+'"'
        for key in input.keys():
            input[key] = input[key].replace('"','\\"')
            input[key] = input[key].replace("'",'\\"')
        payload = '{"query":"{getAvailableAppointments(input:{'+input['serviceAddressInput']+','+input['orderType']+','+input['fulfillmentPartnerPartyId']+','+input['dealerId']+'} \
        filters:{'+input['from']+','+input['to']+'}){availableAppointments{from,to, availableAppointmentId}}}"}'        
        logger.console("payload = "+payload)

        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        bep_common.logAPI(FO_NP_URL,str(header),payload)

        payload = payload.encode('utf-8')
        try:
            r = requests.post(FO_NP_URL, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                return True, r.json()
            else:
                return False, funcName + " status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling " + funcName + " FO Endpoint, Error --> "+str(e)

    def upsertWorkOrder(self,payloadDict):
        funcName = sys._getframe().f_code.co_name
        payload = buildStringFromDict(payloadDict)
        payload = payload.replace('"','\\"')
        
        payload = '{"query":"mutation{upsertWorkOrder(input:'+payload+'){fulfillmentPartnerId dealerId workOrder{internalWorkOrderId}}}"}'
        
        tokenResponse = self.getToken()
        if tokenResponse[0] == False:
            return False, funcName + ":" + tokenResponse[1]
        header = bep_common.createBEPHeader(tokenResponse[1],{},True)
        bep_common.logAPI(FO_NP_URL,str(header),payload)

        payload = payload.encode('utf-8')

        try:
            r = requests.post(FO_NP_URL, headers=header, verify=False, data=payload)
            if r.status_code == 200:
                return True, r.json()
            else:
                return False, funcName + " status code = "+str(r.status_code)
        except Exception as e:
            return False, funcName+":Error calling " + funcName + " FO Endpoint, Error --> "+str(e)


    def getWorkOrder(self,externalWorkOrderId):
            funcName = sys._getframe().f_code.co_name
            payload = '{"query":"{getWorkOrder(input:{externalWorkOrderId:\\"'+externalWorkOrderId+'\\"}){workOrder{internalWorkOrderId,status,products{id,equipment{name,kind}}}}}"}'        
            tokenResponse = self.getToken()
            if tokenResponse[0] == False:
                return False, funcName + ":" + tokenResponse[1]
            header = bep_common.createBEPHeader(tokenResponse[1],{},True)
            bep_common.logAPI(FO_NP_URL,str(header),payload)
            try:
                r = requests.post(FO_NP_URL, headers=header, verify=False, data=payload)
                if r.status_code == 200:
                    return True, r.json()
                else:
                    return False, funcName + " status code = "+str(r.status_code)
            except Exception as e:
                return False, funcName+":Error calling " + funcName + " FO Endpoint, Error --> "+str(e)

    
#  def scheduleWorkOrder(availableAppointmentId):
    
 
def useFOApi(apiMethod,*argv):
    funcName = sys._getframe().f_code.co_name
    foApi = FO_API_LIB()
    result = getattr(foApi,apiMethod)(argv[0])
    return result

def xmlToJson(input):
    # put xml input into dictionary structure
    output = {}
    for child in input:
        try:
            output[child.tag] = child.text
        except:
            output[child.tag] = ''
    return output

def parseWorkOrder(input):
    workOrder = ET.fromstring(input)
    fields = ['externalOrderId','orderType','orderStatus','customerToken','notes']
    woJson = xmlToJson(workOrder)
    logger.console(woJson)
    return(woJson)
    # why do I have the rest of this?
    workOrderInfo = {}   
    for field in fields:
        try:
            workOrderInfo[field] = workOrder.find(field).text
        except:
            pass
    logger.console(workOrderInfo)
    structures = [{"name":"workOrderCustomer"},{"name":"serviceAddress","parent":"workOrderCustomer","dest":'workOrderCustomer'},\
                {"name":"scheduleDate"},{"name":"siteInformation"}]
    child = {}
    for item in structures:
        name = item['name']
        if 'parent' in item:
            child[name] = child[item['parent']].find(name)
        else:
            child[name] = workOrder.find(name)
        if 'dest' in item:
            workOrderInfo[item['dest']][name] = xmlToJson(child[name])
        else:
            workOrderInfo[name] = xmlToJson(child[name])
          
    try:
        services = workOrder.find('services')
        workOrderInfo['services'] = {}
        try:
            serviceUponCompletion = services.find('serviceUponCompletion')
            workOrderInfo['services']['serviceUponCompletion'] = xmlToJson(serviceUponCompletion)
        except:
            pass
    except:
        pass

    return workOrderInfo

def getWorkOrderFromFSM(workOrderId):
    funcName = sys._getframe().f_code.co_name
    url = FSM_WORKORDER_URL + workOrderId
    try:
        r = requests.get(url, verify=False)
        if r.status_code == 200:
            result = parseWorkOrder(r.text)
            return True, result
        else:
            return False, funcName + " status code = "+str(r.status_code)
    except Exception as e:
        return False, funcName+":Error calling " + funcName + " FSM Endpoint, Error --> "+str(e)   


if __name__ == "__main__":
    #result = getWorkOrderFromFSM('a854fa32-a3a5-405a-89b9-29986e87b17d')
    #print(str(result))

    foApi = FO_API_LIB()
    #address = {"address":{"addressLine":["Aramen 500"],"municipality":"Morelia","region":"MIC","postalCode":"58000","countryCode":"MX"},"coordinates":{"latitude": 19.683294, "longitude": -101.185577}}
    #address = {"address":{"addressLine":["Aramen 500"],"municipality":"Madrid","region":"MD","postalCode":"28013","countryCode":"ES"}}

    #dates = {"from":"2019-10-26T00:00:00.000","to":"2019-10-30T00:00:00.000"}
    #result = foApi.getAvailableAppointments(address,dates)
    #result = buildStringFromDict({'fulfillmentPartnerId': 'MEXICO_RETAIL', 'serviceLocation': {'address': {'addressLine': ['Adolfo Ruiz Cortines 3495 46'], 'municipality': 'Boca Del Rio', 'region': 'VE', 'postalCode': '94298', 'countryCode': 'MX'}, 'coordinates': {'latitude': 19.139552, 'longitude': -96.106214}}, 'customer': {'firstName': 'ppthydu', 'lastName': 'rrvpp', 'emailAddress': 'swile_EnDyZ@viasat.com', 'primaryPhoneNumber': '+525134927316'}, 'partySummary': {'name': 'custRelnId', 'value': '72dd6563-7fdf-4202-9cc7-f80b1da2ad90'}, 'workOrder': {'foProductId': '5ea9067e-815c-4cb9-aca7-fd15af7deff6', 'products': [{'characteristics': [{'name': 'SPB:billingAccountId', 'value': '5000013047'}, {'name': 'SERVICE_DELIVERY_PARTNER', 'value': 'bbbc0a5f-c056-4151-a1bd-36dcc5c66710'}, {'name': 'PSM_PRODUCT_KIND', 'value': 'FIXED_SATELLITE_INTERNET'}, {'name': 'DATA_CAP_GB', 'value': '80'}, {'name': 'OFFER_NAME', 'value': 'Viasat 12 Mbps Pro'}, {'name': 'UPLOAD_RATE_UNIT', 'value': 'Mbps'}, {'name': 'CONTRACT_TERM_UNIT', 'value': 'Meses'}, {'name': 'VIDEO_OPTIMIZATION', 'value': 'Transmisión de video en calidad HD (típicamente 720p). La Extension de Datos de Video guarda sus datos transmitiendo video en calidad DVD, optimizado para 480p.'}, {'name': 'UNMETERED_PERIOD_TEXT', 'value': 'Zona libre 2 am - 7 am'}, {'name': 'ROUTER_TEXT', 'value': 'Router wifi incluido'}, {'name': 'DOWNLOAD_SPEED_TEXT', 'value': 'Descarga hasta'}, {'name': 'OFFER_DESCRIPTION', 'value': 'Viasat 12 Mbps Pro'}, {'name': 'CONTRACT_TERM', 'value': '12'}, {'name': 'DATA_CAP_UNIT', 'value': 'GB'}, {'name': 'UPLOAD_RATE', 'value': '3'}, {'name': 'FEE_TEXT', 'value': 'Incluye la cuota mensual de alquiler e impuestos.'}, {'name': 'DOWNLOAD_RATE_UNIT', 'value': 'Mbps'}, {'name': 'DATA_POLICY_DESCRIPTION', 'value': 'Navegación por la web y chateo a toda velocidad después del límite'}, {'name': 'ELECTRONIC_CONTRACT_PROVIDER', 'value': 'Sertifi'}, {'name': 'DATA_ALLOWANCE_TEXT', 'value': 'Asignación de datos'}, {'name': 'DOWNLOAD_RATE', 'value': '12'}, {'name': 'PRICE_TEXT', 'value': '1,981.90/mes'}, {'name': 'CONFIGURE_SPB:billingAccountId', 'value': '5000013047'}, {'name': 'CONFIGURE_PSM_PRODUCT_KIND', 'value': 'NONE'}, {'name': 'CONFIGURE_PSM_PRODUCT_RELATIONSHIP', 'value': 'CONFIGURES'}, {'name': 'CONFIGURE_SISM_PRODUCT_ID', 'value': '079c37ff-98cd-4ba5-b8e4-b43e4f329fdd'}, {'name': 'SPB:serviceFileLocationId', 'value': '3'}, {'name': 'SERVICE_ACTIVATION_CODE', 'value': '01301B23'}, {'name': 'IDU_EQUIPMENT', 'value': 'AB_SPK_WIFI_IDU'}, {'name': 'ODU_EQUIPMENT', 'value': 'AB_ODU_PTRIA'}, {'name': 'SERVICE_AREA_ID', 'value': '711'}, {'name': 'SATELLITE_NAME', 'value': 'ViaSat-2-Small'}, {'name': 'POLARIZATION', 'value': 'RIGHT'}, {'name': 'MODEM_INSTALL_CODE', 'value': 'C7PH-XLPN-9SMB-C8D4-852V-XCDK'}, {'name': 'AZIMUTH', 'value': '124.27'}, {'name': 'ELEVATION', 'value': '31.59'}, {'name': 'SKEW', 'value': '124.66'}, {'name': 'BOOM_ARM_ANGLE', 'value': '12.190000000000001'}, {'name': 'ANTENNA_POINTING_AID', 'value': '1'}, {'name': 'GATEWAY_ID', 'value': '161'}, {'name': 'GATEWAY_NAME', 'value': 'Not Applicable'}, {'name': 'MODEM_MAC_ADDRESS', 'value': '00:A0:BC:6E:B2:9C'}], 'kind': 'FIXED_SATELLITE_INTERNET', 'name': 'Viasat 12 Mbps Pro', 'state': 'DEACTIVATED', 'id': '5f212ade-7e3d-4967-bba0-4ddd274cf9a9', 'equipment': [{'kind': 'IDU_EQUIPMENT', 'name': 'AB_SPK_WIFI_IDU'}, {'kind': 'ODU_EQUIPMENT', 'name': 'AB_ODU_PTRIA'}]}], 'externalWorkOrderId': '2960e4b0-f6ae-11e9-92c8-0255a063ea42'}})
    #print(str(result))
    result = getWorkOrderFromFSM('b75c9bcf-5947-419d-8d1b-ba3ed9deb96d')
