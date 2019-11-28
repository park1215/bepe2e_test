from jenkins_config import *
from credentials import *
import requests
import shutil
import tarfile
import sys, os
from robot.api import logger

def deploy_to_artifactory(filename,url):
   auth=(BEP_USERNAME, BEP_PASSWORD)
   with open(filename, 'rb') as fobj:
       res = requests.put(url, auth=auth, data=fobj)
       return res.status_code

def search_artifactory_by_date(repo,start,end):
   url = ARTIFACTORY_SEARCH_DATE_WINDOW.replace('REPO',repo)
   url = url.replace('START_MSEC',str(start))
   url = url.replace('END_MSEC',str(end))
   logger.console('artifactory url = '+url)
   auth=(BEP_USERNAME, BEP_PASSWORD)
   res = requests.get(url, auth=auth)
   return res
  
def get_from_artifactory(url,extract=False):
   auth=(BEP_USERNAME, BEP_PASSWORD)
   local_filename = url.split('/')[-1]
   files = [local_filename]
   r = requests.get(url, auth=auth, stream=True)
   with open(local_filename, 'wb') as f:
      shutil.copyfileobj(r.raw, f)
      f.close()
   if extract==True:
      logger.console('opening '+local_filename)
      tar = tarfile.open(local_filename, "r:gz")
      files = tar.getnames()
      tar.extractall()
      tar.close()
   return files

#use to invoke deploy_to_artifactory    
if __name__ == "__main__":
    print(len(sys.argv))
    print(sys.argv)
    if len(sys.argv) == 3:
        # inputs are 1) subdirectory/job name, 2) result filename
        subdirectory = sys.argv[1]
        resultFilename = os.path.basename(sys.argv[2])
        #url = directory + subdirectory + "/" + resultFilename
        url = ARTIFACTORY_PATH_TESTS + "/" + subdirectory  + "_" +resultFilename
        print('url = ' + url)
        deployResult = deploy_to_artifactory(sys.argv[2], url)
        print("deployResult = " + str(deployResult))
    else:
        # inputs are 1) subdirectory, 2) result filename, 3) base artifactory directory index (eg compliance, demo)
        artifactoryDirectory = {"compliance":ARTIFACTORY_PATH_COMPLIANCE_COMPARISON,"demo":ARTIFACTORY_PATH_DEMO_RESULTS}
        if sys.argv[3] in artifactoryDirectory:
            directory = artifactoryDirectory[sys.argv[3]]
            subdirectory = sys.argv[1]
            resultFilename = os.path.basename(sys.argv[2])
            url = directory + subdirectory + "/" + resultFilename
            print('url = '+url)
            deployResult = deploy_to_artifactory(sys.argv[2],url)
            print("deployResult = "+str(deployResult))
            if deployResult == 201:
               # this assumes that script is running in demo directory - needs to be determined programmatically rather than hard-coded
               fa = open("../artifactory_path.txt","w")
               fa.write(url)
               fa.close()
        else:
            print(sys.argv[3] + ' is not a valid artifactory index')