import urllib3
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import secrets
import sys
import json
from json import loads, dumps
import os
import time
from robot.api import logger

class TNG_API_Lib:
    # Reads in credentials from file
    def _readCreds(self):
        try:
            with open(self._realPath("tng_credentials.json")) as json_file:
                creds_json = json.load(json_file)
        except FileNotFoundError:
            print(os.getcwd())
            print("credential file not found")
            return False
        except Exception as e:
            print("Error, need to take a look:"+ str(e))
            return False
        return creds_json

    # returns filename (which should include relative path from this file) preceded by path of this file
    def _realPath(self,filename):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)),filename)

    # At initialization generates information needed for security header
    def __init__(self, inputLog=False):
        #reads in credentials from credential file, if any of the passwords are not supplied, kill object
        creds_json = self._readCreds()
        if not creds_json:
            print("Error getting creds, killing and returning False")
            del self
            return
        # Initialize username and password used in Add Device Requests
        self._user = creds_json["tngDistributor"]
        self._password = creds_json["tngDistributorPass"]

        # Generate Nonce
        generatedNonce = secrets.token_urlsafe(16)
        self._completeNonce = generatedNonce + "=="

        # Generate TimestampID
        idTimestamp = secrets.token_hex(17)
        idTimestamp = idTimestamp[:-1]
        self._idTimestamp = "TS-" + idTimestamp.upper()

        # Generate epoch time in milliseconds
        epoch = time.time()
        self._epochMilli = int(round(epoch*1000))

        # Suppress error message for insecurerequestwarning
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)   
     
        # Generate UserTokenID
        idUserToken = hex(int(idTimestamp, base=16) + 1)
        idUserToken = idUserToken[2:35]
        self._idUserToken = "UsernameToken-" + idUserToken.upper()

        # Holds TNG Auth  token for sdp calls
        self._tngToken = ""

    def getTngToken(self, user, password):
        #initialize url
        url = "http://auth.trackosng.qa.vws.co:8888/login"

        header = {'content-type': 'application/json'}
    
        payload = {"user_type": "Admin", "username": user, "password": password, "token_lifetime": 90, "audience": "TNG", "claims": {"claimant": "me"}, "info_request": {"tng_tasks": {}}}
        try:
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            if r.status_code == 200:
                responseJson = json.loads(r.text)
                token = responseJson['token'] 
        except Exception as e:
            return False, funcName+":Error calling TNG Authorizer For Token, Error --> "+str(e)
        
        return True, token

#This function is passed the auth token as well as the exact set of equipment in a JSON that has to be looped thru and added
    def bulkAddDevices(self, token,  wifiSetX):
        #initialise URL
        url = "https://api.admin.qa.vws.co:9001/api/models.sysconfig.wda_bulk_add"

        header = {'content-type': 'application/json'}
        
        devicesJsonObject = json.loads(wifiSetX)
        for item in devicesJsonObject:
            for key in item:
                if key == "model":
                    model = item[key]
                elif key == "mac":
                    mac = item[key]
                else:
                    serial = item[key]
            payLoad = {"authToken": token, "args": {"systems": [{"model": model, "mac": mac, "serial": serial}]}}
            #print(payLoad)
            try:
                #r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                #if r.status_code == 200:
                #responseJson = json.loads(r.text)
                print(payLoad)
                #print(wifiSetX)
            except Exception as e:
                return False, funcName+":Error calling TNG Bulk Add API for "+var+", Error --> "+str(e)    


