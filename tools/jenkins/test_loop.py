# this file exists to test jira update scripts
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
import requests
from config import *
from artifactory import deploy_to_artifactory
import jira_lib as jl

TEST_SET_NAME = "test_jenkins"
VNO = "GBS"

# Run this from the directory it resides in.
# run through provision and deprovision of all input parameter combinations

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
   fpi = open(filename,"r")
   xmlInput = fpi.read()

   match = re.search('classname="(.*?)"',xmlInput)
   result = match.groups()[0]
   xmlOutput = re.sub(result,result+"."+suffix,xmlInput)
   match2 = re.search('(testsuite name=".*?")',xmlOutput)
   result2 = match2.groups()[0]
   xmlOutput = re.sub(result2,'testsuite name =""',xmlOutput)   
   
   print(xmlOutput)
   fpi.close()
   fpo = open(filename,"w")
   fpo.write(xmlOutput)
   fpo.close()

def testModem(modem,paramSets):
      # extract modemType, eg AB or SB2    
      modemType = re.sub(r'^(.*?)-.*',r'\1',modem)
      # extract mac address from modem
      mac = re.sub(r'^.*?_(.{2}:.{2}:.{2}:.{2}:.{2}:.{2})$',r'\1',modem)
      for paramSet in paramSets:
         plan = paramSet['plan']
         planString = re.sub(r'\s',r'_',plan)
         suiteSuffix = modemType+"."+planString
         runDict = {"modem_mac_colon":mac,"plan":plan,"modem_type":modemType}
         # store mac address and service plan in yaml file, to be read by robot file
         with open('../../demo/test.yaml', 'w') as outfile:
            yaml.dump(runDict, outfile, default_flow_style=False)

         outputFile = "output_test_"+modem+"_"+planString+".xml"
         output = robot.run("../../demo/demo_stacy.robot",exitonfailure=True,critical="critical",output=outputFile,xunit="x_"+outputFile)
         # replace suite names in output.xml with suite+suffix
         replaceSuiteNamesXunit("x_"+outputFile,suiteSuffix)
         replaceSuiteNames(outputFile,suiteSuffix)
         print("result for "+outputFile+" = "+str(output))
         if output == 1:
            break

def main(argv):
   # remove any existing output files
   os.system("rm log*.html")
   os.system("rm output*.xml")
   try:
      opts, args = getopt.getopt(argv,"h",["config=","version=","cycle="])
   except getopt.GetoptError:
      print('python test_loop.py --config <config_file> --version <versionname> --cycle <cyclename>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
        print('python test_loop.py --config <config_file> --version <versionname> --cycle <cyclename>')
        sys.exit()
      elif opt=="--config":
        config = arg
      elif opt=="--version":
         version = arg
      elif opt=="--cycle":
         cycle = arg


   with open(config) as jsonFile:  
      configDict = json.load(jsonFile)
   modemSets = configDict['modemSets']
   
   # delete existing output files
   try:
      os.system("rm *output*.xml")
      os.system("rm *.png")
   except:
      print("no output files present to delete")
   t = {}
   
   for modemSet in modemSets:
      #testModem(modemSet['modem'],modemSet['paramSets'])
      t[modemSet['modem']] = Thread(target=testModem, args=(modemSet['modem'],modemSet['paramSets'],))
      t[modemSet['modem']].start()
      
   # wait for all threads to complete   
   running = True
   while running == True:
      time.sleep(10)
      running = False
      for modem in t:
         if t[modem].is_alive():
            running = True


   #robot.run("../../demo/demo_stacy.robot",output="output2.xml")
   filename = "log_" + datetime.datetime.now().strftime("%Y-%m-%d_%H_%M_%S")
   os.system("rebot --log "+filename+".html output*.xml")
   #os.system("zip "+filename+".zip "+filename+".html" + " report.html *.png")
   os.system(" tar --create --gzip --file "+filename+".tar.gz "+filename+".html" + " report.html *.png")  
   url = ARTIFACTORY_PATH + version + "/" + cycle + "/" + VNO + "/" + TEST_SET_NAME + "/" + filename + ".tar.gz"
   
   # create a file with the artifactory path for the jenkins zephyr plugin to use as a link in the execution comment
   f = open("../../artifactory_path.txt","w")
   f.write(url)
   f.close()
   
   # deploy to artifactory
   result = deploy_to_artifactory(filename+".tar.gz",url)

if __name__ == "__main__":  
   main(sys.argv[1:])
            

