import sys, getopt
sys.path.insert(0, './lib')
import re
import json
import robot
import yaml
import glob
import os
from threading import Thread
import time
import datetime
from config import *
import os
from robot.api import logger
import modem_parameters
import modem_query

def reserveModem(modemType,timeoutDelta=0):
   macs = modem_parameters.MODEM_TYPE_MAPPINGS[modemType]
   reservedMac = None
   timeout = time.time() + timeoutDelta
   while True:
      for mac in macs:
         ip = modem_parameters.MODEM_IP_MAPPINGS[mac]
         result = modem_query.reserveModem(ip)
         logger.info("reservation attempt for ip = "+ip+": "+result)
         if result == modem_parameters.RESERVATION_SUCCESS:
            reservedMac = mac
            break
      # continue searching until timeout
      if reservedMac == None:
         if time.time() > timeout:
            break
      else:
         break
   logger.info("reserveModem result = " + result)
   return reservedMac             

def testModem(modem,paramSets):      
      # extract modemType, eg AB or SB2
      modemType = re.sub(r'^(.*?)_.*',r'\1',modem)
      print("MODEM TYPE = "+modemType)
      # extract mac address from modem if it exists - otherwise find and reserve available modem of the correct type
      pattern = re.compile('.{2}:.{2}:.{2}:.{2}:.{2}:.{2}')
      macFound = pattern.search(modem)
      if macFound == None:
         mac = reserveModem(modemType,0)
      else:
         mac = macFound.group(0)

      logger.info('reservedMac='+str(mac))
      if mac != None:
         time.sleep(5)
         result = modem_query.freeModem(modem_parameters.MODEM_IP_MAPPINGS[mac])
         print("unset modem result = "+str(result))    

def main(argv):
   try:
      opts, args = getopt.getopt(argv,"h",["config=","version=","cycle="])
   except getopt.GetoptError:
      print('python demo_reserve.py --config <config_file>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
        print('python demo_reserve.py --config <config_file>')
        sys.exit()
      elif opt=="--config":
        config = arg

   with open(config) as jsonFile:  
      configDict = json.load(jsonFile)
   modemSets = configDict['modemSets']

   t = {}
   index = 0

   for modemSet in modemSets:
      t[modemSet['modem']] = Thread(target=testModem, args=(modemSet['modem'],modemSet['paramSets']))
      t[modemSet['modem']].start()
      index = index + 1

   # wait for all threads to complete
   running = True
   while running == True:
      time.sleep(2)
      running = False
      for modem in t:
         if t[modem].is_alive():
            running = True


if __name__ == "__main__":  
   main(sys.argv[1:])
            

