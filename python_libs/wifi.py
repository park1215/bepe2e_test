import sys
import argparse
import time
#import pymysql
import requests
from requests.auth import HTTPBasicAuth
import json
from robot.api import logger

SERVICE_INSTANCE_ID_PREFIX="BEPE2E_Service_Id"
BEP_ORDER_ID_PREFIX="BEPE2E_Order_Id"
#CURE_CONFIGURATION_NAME="Beta Test Configuration"
#CURE_CONFIGURATION_NAME="Business Hotspot"
CURE_CONFIGURATION_NAME="Cody and Titus Testing"
CUSTOMER_ID_PREFIX="BEPE2E_Customer_Id"
BOM= [{"model": "MikroTik RB750Gr3", "device_type": "Controller", "count": 1}, {"model": "Ruckus ZoneFlex T300", "device_type": "Access Point", "count": 1}]
BUSINESS_NAME_PREFIX="BEPE2E_Business"
BUSINESS_LOCATION={"label": "bepe2e_beta_Location0308-21", "address1": "3926 Finfeather", "address2": "b", "city": "Bryan", "state": "TX", "postal_code": "77801", "country": "US"}

TOKEN_URL = "https://jwt.us-or.viasat.io/v1/token?stripe=bep-psm-wifi-nonprod&name=bep"
CREATE_URL = "https://bep.cebeta.wfs.viasat.io/order/"
API_USER = 'bepe2e_test'
API_PASSWORD = '22aHKQqYLS1mPzzIHEg9GbzSot6wWMY9o2uN1qwlRpRDqJhT'

ORDER_DB='nnurap2'
CE_BETA_DB_URL='10.59.8.43'
DB_USER = 'stacy.wile'
DB_PW = 'bepe2e'


class WIFI_LIB:
    def  __init__(self):
        r = requests.get(TOKEN_URL, auth=HTTPBasicAuth(API_USER, API_PASSWORD), verify=False);
        try:
            self.headers = {"Authorization":"Bearer "+ r.text,"Accept": "application/json","Content-Type": "application/json"}
        except:
            print("token error: "+str(r.status_code))
    
    def translateRobotDict(self,robotCreateBody):
        suffix = "_" + str(int(time.time()))
        createBody = {}
        if "service_instance_id" not in createBody:
            createBody["service_instance_id"] = SERVICE_INSTANCE_ID_PREFIX + suffix
        else:
            createBody["service_instance_id"] = robotCreateBody["service_instance_id"]
        if "bep_order_id" not in createBody:
            createBody["bep_order_id"] = BEP_ORDER_ID_PREFIX + suffix
        else:
            createBody["bep_order_id"] = robotCreateBody["bep_order_id"]
        if "cure_configuration_name" not in createBody:
            createBody["cure_configuration_name"] = CURE_CONFIGURATION_NAME
        else:
            createBody["cure_configuration_name"] = robotCreateBody["cure_configuration_name"]
        if "bom" not in createBody:
            createBody["bom"] = BOM
        else:
            createBody["bom"] = robotCreateBody["bom"]
        if "customer_id" not in createBody:
            createBody["customer_id"] = CUSTOMER_ID_PREFIX + suffix
        else:
            createBody["customer_id"] = robotCreateBody["customer_id"]
        if "licensee_details" not in createBody:
            createBody["licensee_details"] = {"business_name":BUSINESS_NAME_PREFIX + suffix}
        else:
            createBody["licensee_details"] = robotCreateBody["licensee_details"]
        if "location_details" not in createBody:
            createBody["location_details"] = BUSINESS_LOCATION
            createBody["location_details"]["label"] = "bepe2e_beta_Location_"+suffix[-4:]
            createBody["location_details"]["address1"] = suffix[-4:] + " Finfeather"
        else:
            createBody["location_details"] = robotCreateBody["location_details"]
        logger.console("translated create input = "+str(createBody))
        return createBody
    
    def create(self,createBody={}):
        # form post body
        logger.console("wifi create input = "+str(createBody))
        
        if "robot" in createBody:
            createBody = self.translateRobotDict(createBody)
        else:
            suffix = "_" + str(int(time.time()))
            if "service_instance_id" not in createBody:
                createBody["service_instance_id"] = SERVICE_INSTANCE_ID_PREFIX + suffix
            if "bep_order_id" not in createBody:
                createBody["bep_order_id"] = BEP_ORDER_ID_PREFIX + suffix
            if "cure_configuration_name" not in createBody:
                createBody["cure_configuration_name"] = CURE_CONFIGURATION_NAME
            if "bom" not in createBody:
                createBody["bom"] = BOM
            if "customer_id" not in createBody:
                createBody["customer_id"] = CUSTOMER_ID_PREFIX + suffix
            if "licensee_details" not in createBody:
                createBody["licensee_details"] = {"business_name":BUSINESS_NAME_PREFIX + suffix}
            if "location_details" not in createBody:
                createBody["location_details"] = BUSINESS_LOCATION
                createBody["location_details"]["label"] = "bepe2e_beta_Location_"+suffix[-4:]
                createBody["location_details"]["address1"] = suffix[-4:] + " Finfeather"
         # send https post
        
        logger.console("headers="+str(self.headers))
        logger.console("wifi createBody = "+str(createBody))
        #return 1

        try:
            r = requests.post(CREATE_URL,headers=self.headers,json=createBody,verify=False)
            return r.status_code
        except:
            return 0


def createWifiOrder(configs):
    wifi = WIFI_LIB()
    status = wifi.create(configs)
    return status
    
def connectMySqlDB(tngDB):
    connection = pymysql.connect(host=CE_BETA_DB_URL, user=DB_USER, password=DB_PW, db=tngDB)
    return connection

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", help="API endpoint")
    parser.add_argument("--configfile", help="file with nondefault config parameters",default="")
    parser.add_argument("--customer_id",help="customer id if existing customer",default="")
    args = parser.parse_args()
    
    if args.operation=='testquery':
        dbConnection = connectMySqlDB(ORDER_DB)
        query = 'select * from wda_order where business_name="'+BUSINESS_NAME_PREFIX+'"'
        with dbConnection:
            cursor = dbConnection.cursor()
            cursor.execute(query)
        
            orders = cursor.fetchall()
            for order in orders:
                print(order)
    elif args.operation=='create':
        # get token
        wifiApi = WIFI_LIB()
        if args.configfile != "":           
            try:
                fp = open(args.configfile)
                configs = json.loads(fp.read())               
                status = wifiApi.create(configs)
            except:
                print("config file not present, using defaults")
                exit()
                status = wifiApi.create()
        else:
            status = wifiApi.create()
        print(status)

        
