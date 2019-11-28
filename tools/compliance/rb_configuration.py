import sys
from bep_parameters import *
import os
import datetime
import dateutil.parser as dateparser
import time
from artifactory import *
from robot.api import logger
import argparse
from new_compliance_config import *
import cx_Oracle
import csv
import json
import filecmp
import re
import random
from jenkins_config import *
from shutil import copyfile

CONNECTION_STRING = 'rac02-qa-scan.test.wdc1.wildblue.net/vsqa1'

def realPath(filename):
    return os.path.join(os.path.dirname(os.path.realpath(__file__)),filename)

class Configuration:
    def  __init__(self):
        try:
            with open(realPath("../../python_libs/credentials.json")) as json_file:
                creds = json.load(json_file)
                rbUser = creds["rb_db_user"]
                rbPassword = creds["rb_db_pass"]
        except FileNotFoundError:
            logger.console(os.getcwd())
            logger.console("credential file not found")
            exit()
        except Exception as e:
            logger.console("Error opening credentials file" + str(e))
            exit()
        
        self.connection = cx_Oracle.connect(rbUser,rbPassword,CONNECTION_STRING)

    def productFamilyIdLookup(self,productFamily):
        cursor = self.connection.cursor()
        query = productFamilyIdQuery + " '" + productFamily + "'"
        cursor.execute(query)
        data=cursor.fetchone()
        return data[0]

    def productIdLookup(self,productName):
        cursor = self.connection.cursor()
        query = productIdQuery + " '" + productName + "'"
        cursor.execute(query)
        data=cursor.fetchone()
        return data[0]
    
    def getConfig(self,vno,archive,nodelete,addErrors = False):
        cursor = self.connection.cursor()
        self.timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H_%M_%S")
        gzFilename = vno + "_config_" + self.timestamp + ".tar.gz"
        filenames = []
        if addErrors == True:
            fe = open("errors.log","w")
        for queryType in configQueries.keys():        
            cursor.execute(configQueries[queryType])   
            filename = queryType + "_" + self.timestamp + ".csv"
            filenames.append(filename)
            fp = open(filename,"w")
            output=csv.writer(fp, dialect='excel')
            if addErrors == True:
               i = 0
               for row in cursor:
                  if random.randint(1,301)==1:
                     position = random.randint(0,len(row)-2)
                     fe.write(str(row[position])+"\n")
                     while row[position]==',':
                                         position = position+1
                     fe.write(queryType+":"+str(i)+":"+str(row[position])+"\n")
                     row = list(row)
                     row[position] = 'WRONG'
                     row = tuple(row)
                  output.writerow(row)
                  i = i + 1
            else:
               output.writerow(configHeaders[queryType])
               for row in cursor:
                  output.writerow(row)
            fp.close()
         
        if addErrors == True:
           fe.close()  
        cursor.close()
        self.connection.close()
        if archive==True:
           os.system(" tar --create --gzip --file " + gzFilename + " *"+self.timestamp+".csv")
           url = ARTIFACTORY_PATH_COMPLIANCE + vno + "/" + gzFilename
           
           # deploy to artifactory
           result = deploy_to_artifactory(gzFilename,url)
           
        if nodelete!=True:
           os.system("rm " + "*" + self.timestamp + "*")
           
        return filenames 
    
   # find differences in 2 csv files, output = 
    def findDifferences(self,file1,file2):
       f1 = open(file1,"r")
       f2 = open(file2,"r")
       before = f1.read()
       after = f2.read()
       # remove timestamp and file extension
       queryType = file1.split("_")[0]
       #print(configHeaders[queryType])
       beforeLines = before.split("\n")
       afterLines = after.split("\n")
       numLines = min(len(beforeLines),len(afterLines))
       errors = []
       for i in range(numLines):
          if beforeLines[i] != afterLines[i]:
             beforeCells = beforeLines[i].split(",")
             afterCells = afterLines[i].split(",")
             for j in range(len(beforeCells)):
                if beforeCells[j] != afterCells[j]:
                   try:
                      error = {"row":i,"column":configHeaders[queryType][j],"before":beforeCells[j],"after":afterCells[j]}
                      errors.append(error)
                   except:
                      logger.console(str(i)+','+str(j))
       if len(beforeLines) != len(afterLines):
          errors.append({"before rows":len(beforeLines),"after_rows":len(afterLines)})
       return errors          
                   
    def regressionCompare(self,vno,updateTime,archive):
       # get files deployed between updateTime-POLL_INTERVAL_MSEC and updateTime
       # updateTime is in msec (unix timestamp)
       # search_artifactory_by_date returns request response
       
       # clean directory of previous results
       localFiles = os.listdir('.')
       for file in localFiles:
          if ".csv" in file or ".tar.gz" in file:
             os.remove(file)
 
       # convert updateTime to timestamp format if in YYYYMMDDHHMMSS format
       logger.console('updateTime='+str(updateTime))
       logger.console("length of update time = "+str(len(updateTime)))
       if len(updateTime)==14:
           updateTime = int(1000*(time.mktime(datetime.datetime.strptime(str(updateTime), "%Y%m%d%H%M%S").timetuple())))
           logger.console('updateTime='+str(updateTime))
       recentDeploys = search_artifactory_by_date(BEP_COMPLIANCE_REPO,int(updateTime)-POLL_INTERVAL_MSEC,updateTime)
       if recentDeploys.status_code==200:
          resultList = json.loads(recentDeploys.text)['results']
          latestTime = 0
          latestUri = None
          for item in resultList:
             if "compliance/polls/"+vno in item['uri']:
                secondsTime = int(dateparser.parse(item['created']).strftime('%s'))
                if secondsTime>latestTime:
                   latestUri = item['uri']
                   latestTime = secondsTime
          if latestUri != None:       
             latestFile = latestUri.split('/')[-1]
             uri = ARTIFACTORY_PATH_COMPLIANCE + vno + "/" + latestFile
             beforeFilenames = get_from_artifactory(uri,True)
             matches = re.search(".*(\d\d\d\d-.*)\.csv",beforeFilenames[0])
             if matches:
                beforeTimestamp = matches.group(1)
                beforeFilenamesDict = createConfigFileDict(beforeFilenames,beforeTimestamp)
                afterFilenames = self.getConfig(vno,False,True)
                afterFilenamesDict = createConfigFileDict(afterFilenames,self.timestamp)
                logger.console('afterFilenamesDict = '+str(afterFilenamesDict))
                results = {"all":"available"}
                failures = {}
                resultFilename = "results_"+self.timestamp+".log"
                fo = open(resultFilename,"w")
                fo.write("Comparing to "+uri+"\n\r")
                for beforeFilename in afterFilenamesDict.keys():
                   beforeLength = getCsvLength(beforeFilenamesDict[beforeFilename])
                   logger.console('beforeLength for '+beforeFilename+' is '+str(beforeLength))
                   truncResult, extraRows = truncateCsvFile(afterFilenamesDict[beforeFilename],beforeLength)
                   if truncResult == "PASS":
                      cmpResult = filecmp.cmp(beforeFilenamesDict[beforeFilename],afterFilenamesDict[beforeFilename])
                      if cmpResult==True:
                         os.remove(beforeFilenamesDict[beforeFilename])
                         os.remove(afterFilenamesDict[beforeFilename])
                         results[beforeFilename] = ["PASS",truncResult,str(extraRows) + " new rows"]
                      else:
                         failure = self.findDifferences(beforeFilenamesDict[beforeFilename],afterFilenamesDict[beforeFilename])
                         results[beforeFilename] = ["FAIL",failure,str(extraRows) + " new rows"]                     
                   else:
                      results[beforeFilename] = ["FAIL","new query has fewer rows than old query"]
                for key in results.keys():
                   fo.write(key+":"+str(results[key])+"\n\r")
                fo.close()
                if archive==True:
                   url = ARTIFACTORY_PATH_COMPLIANCE_COMPARISON + vno + "/" + resultFilename               
                   # deploy to artifactory
                   deployResult = deploy_to_artifactory(resultFilename,url)
                   logger.console("deployResult = "+str(deployResult))
                   if deployResult == 201:
                      logger.console("writing to artifactory")
                      # this assumes that script is running in demo directory - needs to be determined programmatically rather than hard-coded
                      fa = open("../artifactory_path.txt","w")
                      fa.write(url)
                      fa.close()               
                return results
             else:
                return {"all":["FAIL","Artifactory files are missing timestamp in filename"]}
          else:
             return {"all":["FAIL",'no configuration files for ' + vno + ' VNO available in time window prior to update']}
       else:
          return {"all":["FAIL",'artifactory retrieval failed:'+str(recentDeploys.status_code)]}

def createConfigFileDict(names,timestamp):
   nameDict = {}
   for name in names:
      key = name[0:name.find(timestamp)-1]
      nameDict[key] = name
   return nameDict

def compareFiles(file1,file2):
   beforeLength = getCsvLength(file1)
   truncResult = truncateCsvFile(file2,beforeLength)
   print(filecmp.cmp(file1,file2))
   
def getCsvLength(filename):
   f = open(filename,"r")
   csvContents = f.read()
   return csvContents.count("\n")

def truncateCsvFile(filename,length):
   #copyfile(filename,"save_"+filename)
   fi = open(filename,"rb")
   csvContentsBytes = fi.read()
   csvContents = csvContentsBytes.decode()
   fi.close()
   parts= csvContents.split("\n", length)
   #logger.console('length of '+filename+' = '+str(len(csvContents.split("\n"))))
   
   if len(parts)<=length:
      newLength = getCsvLength(filename)
      return "missing " + str(length-newLength) + " rows"
   if len(parts[-1]) > 0:
      truncatedLength = len(csvContents)-len(parts[-1])
      parts[-1] = parts[0] + "\n" + parts[-1]  
      fo = open("additional_"+filename,"ba+")
      fo.write(parts[-1].encode())
      fo.close()
      csvContents = csvContents[0:truncatedLength]
      fo = open(filename,"wb")
      fo.write(csvContents.encode())
      fo.close()
      return "PASS", len(parts[-1].split("\n"))
   else:
      return "PASS", 0

def regressionTest(vno,updateTime):
    conn = Configuration()
    result = conn.regressionCompare(vno,updateTime,False)
    return result
   
if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", dest="archive", help="If present, archive result in artifactory", action='store_true')
    parser.add_argument("--nodelete", dest="nodelete", help="If present, do not delete local result", action='store_true')
    parser.add_argument("--adderrors", dest="addErrors", help="If present, add errors to data before archiving", action='store_true')
    parser.add_argument("--vno", dest="vno", help="VNO to check", default='GBS')
    parser.add_argument("--cmp", dest="cmp", help="If present, get config and compare with most recent",action='store_true')
    parser.add_argument("--updatetime", dest="updateTime",help="time of last config update in unix timestamp(msec), only relevant if cmp=True",default=0)
    parser.add_argument("--project", dest="projectNumber",help="project number associated with config update, only relevant if cmp=True",default=0)
 
    args = parser.parse_args()
    conn = Configuration()
    if args.cmp==True:
       if args.updateTime==0:
          print("update time needed for this action")
          exit()
       result = conn.regressionCompare(args.vno,args.updateTime,args.archive)
       print(result)
    else:
       conn.getConfig(args.vno,args.archive,args.nodelete,args.addErrors)
