import sys
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
import requests
from config import *
from artifactory import deploy_to_artifactory
import shutil
from shutil import copytree
from shutil import rmtree
from robot.api import logger
import subprocess
import xml.etree.ElementTree as ET
import argparse
import modem_parameters
import modem_query

TEST_SET_NAME = "status"
VNO = "GBS"

# Run this from the directory it resides in.

def replaceSuiteNames(filename,suffix):
   fpi = open(filename,"r")
   xmlInput = fpi.read()
   match = re.search('name="(.*?)"',xmlInput)
   result = match.groups()[0]
   xmlOutput = re.sub(result,result+"."+suffix,xmlInput)
   fpi.close()
   fpo = open(filename,"w")
   fpo.write(xmlOutput)
   fpo.close()

def replaceSuiteNamesXunit(filename,suffix):
   tree = ET.parse(filename)
   root = tree.getroot()
   testcases = root.findall('testcase')
   for case in testcases:
      newClassname = case.get('classname') + "." + suffix
      case.set('classname',newClassname)
   root.set('name',"")
   tree.write(filename)

# replace failure reason in each test case if suite setup failed
def replaceXunitFailureReason(filename):
   tree = ET.parse(filename)
   root = tree.getroot()
   
   case = root.find('testcase')
   # this will be the first failure encountered
   firstFailure = case.find('failure')
   if firstFailure==None:
       logger.info('no failures in test')
   else:
       newFailure = firstFailure.get('message')
       if newFailure.find("Parent suite setup failed")==0:
           failures = root.findall('.//failure')
           for failure in failures:
               failure.set('message',newFailure)          
           tree.write(filename)

# if test case was not run because it followed a critical test case, delete from xunit file so it is not reported           
def deleteUnrunTestCases(filename):
   tree = ET.parse(filename)
   root = tree.getroot()
   
   cases = root.findall('.//testcase')
   failureCount = int(root.get('failures'))
   if failureCount > 0:
       testCount = int(root.get('tests'))
       deleted = 0
       for case in cases:
           if case.find('failure') != None:
               if case.find('failure').get('message')=='Critical failure occurred and exit-on-failure mode is in use.':
                   root.remove(case)
                   logger.info('removed '+case.get('name'))
                   deleted = deleted + 1
       if deleted > 0:
           failureCount = failureCount - 1
           testCount = testCount - 1
       root.set('tests',str(testCount))
       root.set('failures',str(failureCount))
       tree.write(filename)

def testModem(modem,paramSets,index):
      # Set up a directory to run this modem's tests in
      copytree("../../demo","../../demo_"+str(index))
      
      # extract modemType, eg AB or SB2
      modemType = re.sub(r'^(.*?)[-_].*',r'\1',modem)
      logger.info("modem type = "+modemType)
      # extract mac address from modem if it exists - otherwise find and reserve available modem of the correct type
      pattern = re.compile('.{2}:.{2}:.{2}:.{2}:.{2}:.{2}')
      macFound = pattern.search(modem)
      if macFound == None:
         result = modem_query.pollModemsForReservation(modemType,0)
         print(str(result))
         mac= result['mac']
      else:
         mac = macFound.group(0)
         result = modem_query.reserveModem(modem_parameters.MODEM_IP_MAPPINGS[mac])
         if result != modem_parameters.RESERVATION_SUCCESS:
            mac = None
      if mac==None:
         logger.info("No available modem found for test")
         rmtree("../../demo_"+str(index))
         return    
         
      # perform test suite on modem for each set of parameters in config file   
      for paramSet in paramSets:
         planString = re.sub(r'\s',r'_',paramSet['service_plan'])
         suiteSuffix = modemType+"."+planString
         runDict = {"modem_mac_colon":mac,"modem_type":modemType}
         runDict.update(paramSet)
         # store mac address and service plan in yaml file, to be read by robot 
         dirPrefix = "../../demo_"+str(index)+"/"
         with open(dirPrefix + 'test.yaml', 'w') as outfile:
            yaml.dump(runDict, outfile, default_flow_style=False)
 
         outputFile = dirPrefix+"output_status_"+modem+"_"+planString+".xml"
         xoutputFile = dirPrefix+"x_output_status_"+modem+"_"+planString+".xml"
         vfile = dirPrefix+'test.yaml'
         lfile = dirPrefix+'log_'+str(index)+'.html'
         subprocess.call(["robot","-o", outputFile,"-x",xoutputFile,"-l",lfile,"-V",vfile,"--exitonfailure",dirPrefix+"demo_status.robot"],env = os.environ.copy())
         
         # if suite setup failed, use that failure reason for each test case
         replaceXunitFailureReason(xoutputFile)
         # if test cases were not run because of critical failure, remove them from xunit file so they are not reported
         deleteUnrunTestCases(xoutputFile)
         #replace suite names in output.xml with suite+suffix
         replaceSuiteNamesXunit(xoutputFile,suiteSuffix)
         replaceSuiteNames(outputFile,suiteSuffix)
         shutil.copy(outputFile,".")
         shutil.copy(xoutputFile,".")
         shutil.copy(lfile,".")
      # release modem
      modem_query.freeModem(modem_parameters.MODEM_IP_MAPPINGS[mac])
      # remove temporary directory that this thread ran in
      rmtree("../../demo_"+str(index))
      
def runTest(dirPrefix,testname,index):     
   output = robot.run(dirPrefix+testname,output=dirPrefix+"output"+str(index)+".xml",log=dirPrefix+"log.html",report=dirPrefix+"report.html")         
   shutil.copy(dirPrefix+"output"+str(index)+".xml",".")
   
def main(argv):
   parser = argparse.ArgumentParser()
   parser.add_argument("--config", help="configuration file")
   parser.add_argument("--version", help="version in Jira",default="Unscheduled")
   parser.add_argument("--cycle", help="cycle in Jira",default="Ad hoc")
   parser.add_argument("--archive", help="archive in artifactory",default=True)
   args = parser.parse_args()


   with open(args.config) as jsonFile:  
      configDict = json.load(jsonFile)
   modemSets = configDict['modemSets']
   # delete existing output files
   try:
      os.system("rm log*.html")
      os.system("rm *output*.xml")
      os.system("rm *.png")
      os.system("rm output*.xml")
      os.system("rm x_output*.xml")
   except:
      print("no output files present to delete")
   t = {}
   index = 0

   for modemSet in modemSets:
      t[modemSet['modem']] = Thread(target=testModem, args=(modemSet['modem'],modemSet['paramSets'],index))
      t[modemSet['modem']].start()
      index = index + 1

   # wait for all threads to complete
   running = True
   while running == True:
      time.sleep(10)
      running = False
      for modem in t:
         if t[modem].is_alive():
            running = True

   filename = "log_" + datetime.datetime.now().strftime("%Y-%m-%d_%H_%M_%S")
   if len(glob.glob('./output*.xml')) > 0:
      os.system("rebot --log "+filename+".html output*.xml")
   else:
      print("no files to rebot")
      return

   if args.archive==True:
      os.system(" tar --create --gzip --file "+filename+".tar.gz "+filename+".html" + " report.html *.png")  
      url = ARTIFACTORY_PATH + args.version + "/" + args.cycle + "/" + VNO + "/" + TEST_SET_NAME + "/" + filename + ".tar.gz"
      
      # create a file with the artifactory path for the jenkins zephyr plugin to use as a link in the execution comment
      f = open("../../artifactory_path.txt","w")
      f.write(url)
      f.close()
      
      # deploy to artifactory
      result = deploy_to_artifactory(filename+".tar.gz",url)
   
if __name__ == "__main__":  
   main(sys.argv[1:])
            

