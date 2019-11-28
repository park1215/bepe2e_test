import xml.etree.ElementTree as ET
from robot.api import logger
import sys
import argparse
import time
import glob
import re
import json
from credentials import *
from jenkins_config import *
from jira import JIRA

class JIRA_LIB:
    jira = None
    def  __init__(self,project=None):
        if project==None:
            self.project=JIRA_PROJECT
        else:
            self.project=project
        self.jira = JIRA(basic_auth=(BEP_USERNAME, BEP_PASSWORD), options={'server': 'https://jira.viasat.com','agile_rest_path': 'agile'})

    def find_issue_key_from_summary(self,proj,summary):
        testcase = self.jira.search_issues('project="'+proj+'" and summary~"'+summary+'"')
        if len(testcase)>0:
            return testcase[0]
        else:
            return None
    
    def add_link_to_log_comment(self,issue_key,execution_name,url,failure_reason):
        comments = self.jira.comments(issue_key)
        found = False
        newContent = LOG_COMMENT_HEADER + "\n" + "["+execution_name+"|"+url+"]" + failure_reason
        for comment in comments:
            allComment = self.jira.comment(issue_key,comment.id)
            if allComment.body.find(LOG_COMMENT_HEADER)==0:
                newComment = newContent + "\n" + allComment.body[len(LOG_COMMENT_HEADER)+1:]
                allComment.update(body=newComment)
                found = True
                break
        if found == False:
            self.jira.add_comment(issue_key, newContent)
            print("not found")

    # this will not change issue status from "done" - will have to create separate method or add more conditions to this one     
    def update_issue_status(self,issue_keys,new_status='In Progress'):
        '''
        boards = self.jira.boards(startAt=0,maxResults=1,type='scrum',name='BEP E2E Test Sprint')
        for board in boards:
            if board.name=='BEP E2E Test Sprint':
                board_id = board.id
                print('board id = ' + str(board_id))
                break

        sprints = self.jira.sprints(board_id,extended=True,startAt=0,maxResults=5,state='active')
        for sprint in sprints:
            print(str(sprint))
            print(sprint.id)
            break
        
        self.jira.add_issues_to_sprint(sprint.id,issue_keys)
        '''
        transition_list = self.jira.transitions(issue_keys[0])
        logger.console("transition list = "+str(transition_list))
        transition_id = self.jira.find_transitionid_by_name(issue_keys[0],new_status)
        logger.console("transition_id="+str(transition_id))
        for issue_key in issue_keys:
            issue = self.jira.issue(issue_key,fields='status')
            if str(issue.fields.status) != "Done":
                try:
                    print("updating status of "+str(issue_key)+" to " + new_status)
                    self.jira.transition_issue(issue_key,transition_id)
                except:
                    print('could not transition ' + issue_key + ' to ' + new_status)
            else:
                print("issue status is 'Done', do not change")

    def get_linked_test_cases(self,issue_key,newStatus):
        issue = self.jira.issue(issue_key)
        tests = []
        for link in issue.fields.issuelinks:
            if hasattr(link, "inwardIssue") and link.type.name=='Test':
                tests.append(link.inwardIssue.key)
        if newStatus!=None:
            print('updating' + str(tests) + ' to ' + newStatus)
            self.update_issue_status(tests,newStatus)

        return tests

    def update_testcases(self,xunit_path,cycle,url,update_status=True,new_status="In Progress"):
       # add link to log file in a comment field of each test case
       # first get all test case names from xunit output file
        logger.console(xunit_path)
        xunitList = glob.glob(xunit_path + "x_output*.xml")
        logger.console("xunitList="+str(xunitList))
        issues = []
        for xunitFile in xunitList:
            tree = ET.parse(xunitFile)
            root = tree.getroot()
            for item in root.findall('./testcase'):            
                testCaseSummary = item.attrib['classname'] + "." + item.attrib['name']
                logger.console(testCaseSummary)
                issue_key = self.find_issue_key_from_summary(self.project,testCaseSummary)
                failure = item.findall("failure")
                if failure:
                    failure_reason = "\n *Failure Reason*: "+failure[0].attrib['message']
                else:
                   failure_reason = ""
                self.add_link_to_log_comment(issue_key,cycle,url,failure_reason)
                issues.append(str(issue_key))
                logger.console("adding "+str(issue_key))
        # move tests to in progress
        if update_status == True:
            logger.console("update_status = true")
            logger.console("updating issues: "+str(issues))
            self.update_issue_status(issues,new_status)
        
    def map_issues_to_epics(self,xmlFilename,jsonFilename=''):
        # get tags per test from xml output file, searching for epics
        epics = {}
        cases = {}
        fileList = glob.glob(xmlFilename)
        for file in fileList:
            tree = ET.parse(file)
            root = tree.getroot()            
            for suite in root.findall(".//suite"):
                for test in suite.findall(".//test"):
                    tags = test.find("tags")
                    if tags:
                        for tag in tags.findall("tag"):
                            match = re.search('epic_(.*)',tag.text,re.IGNORECASE)
                            if match:
                                cases[suite.attrib['name']+'.'+test.attrib['name']] = match.group(1).upper()
        print("test cases with epic tags:")
        print(cases)
        # get list of newly added test cases and match with tests in epics dictionary
        with open(jsonFilename, 'r') as f:
            newCasesList = json.load(f)['issueUpdates']
            for newCaseTop in newCasesList:
                newCase = newCaseTop['fields']
                print("new case: "+newCase['summary'])
                if newCase['summary'] in cases:                   
                    epic = cases[newCase['summary']]
                    if epic in epics:
                        epics[epic].append(newCase['summary'])
                    else:
                        epics[epic] = [newCase['summary']]
        print(epics)
        # for each epic, get issue id given summary of test case
        for epic, testCaseArray in epics.items():
            issueKeyList = []
            for testCaseSummary in testCaseArray:
                issueKey = self.find_issue_key_from_summary(self.project,testCaseSummary)
                issueKeyList.append(issueKey.raw['key'])
            epicId = self.jira.issue(epic).raw['id']
            print(epicId)
            print(issueKeyList)
            self.jira.add_issues_to_epic(epicId, issueKeyList)
 
    # this method looks at the tags for each test case in the output.xml file to see which issues the associated zephyr test case should link to..
    # then it goes through each test case in a json file (which are a subset of the test cases in output.xml) and does the linking
    def reference_issue_to_issues(self,xmlFilename,jsonFilename=''):
        # get tags per test from xml output file, searching for references
        refs = {}
        cases = {}
        fileList = glob.glob(xmlFilename)
        for file in fileList:
            tree = ET.parse(file)
            root = tree.getroot()            
            for suite in root.findall(".//suite"):
                for test in suite.findall(".//test"):
                    tags = test.find("tags")
                    if tags:
                        for tag in tags.findall("tag"):
                            match = re.search('ref_(.*)',tag.text,re.IGNORECASE)
                            if match:
                                cases[suite.attrib['name']+'.'+test.attrib['name']] = match.group(1).upper()
        print("test cases with ref tags:")
        print(cases)
        # get list of newly added test cases and match with tests in epics dictionary
        with open(jsonFilename, 'r') as f:
            newCasesList = json.load(f)['issueUpdates']
            for newCaseTop in newCasesList:
                newCase = newCaseTop['fields']
                print("new case: "+newCase['summary'])
                if newCase['summary'] in cases:                   
                    ref = cases[newCase['summary']]
                    if ref in refs:
                        refs[ref].append(newCase['summary'])
                    else:
                        refs[ref] = [newCase['summary']]
        print(refs)
        # for each epic, get issue id given summary of test case
        for ref, testCaseArray in refs.items():
            issueKeyList = []
            for testCaseSummary in testCaseArray:
                issueKey = self.find_issue_key_from_summary(JIRA_PROJECT,testCaseSummary)
                issueKeyList.append(issueKey.raw['key'])
            print(ref)
            print(issueKeyList)
            self.link_issues_to_issue(issueKeyList,ref,"Reference")
    
    # links test cases from the json file to the provided parent issue 
    def link_test_cases_to_issue(self,jsonfile,sourceIssueKey,jiraProject='Finance'):
        testCaseSummaries = []
        issueKeyList = []
        with open(jsonfile, 'r') as f:
            newCasesList = json.load(f)['issueUpdates']
            for newCaseTop in newCasesList:
                testCaseSummaries.append(newCaseTop['fields']['summary'])
        for summary in testCaseSummaries:
            issueKey = self.find_issue_key_from_summary(jiraProject,summary)
            try:
                issueKeyList.append(issueKey.raw['key'])
            except:
                logger.console("no issueKey found for project "+jiraProject+" and issue summary "+summary)
        if len(issueKeyList) > 0:
            self.link_issues_to_issue(issueKeyList,sourceIssueKey,'Test')
            
    def link_issues_to_issue(self,linkedIssueKeys,issueKey,linkType):
        issue = self.jira.issue(issueKey)
        for key in linkedIssueKeys:
            linkedIssue = self.jira.issue(key)
            self.jira.create_issue_link(linkType,linkedIssue,issue)
    
    def find_issues_in_epic(self,epic):
        issues = self.jira.search_issues('project="'+JIRA_PROJECT+'" and "Epic Link"="'+epic+'"')
        for issue in issues:
            print(issue.id)
            
def get_jira_lib_instance():
    jl = JIRA_LIB()
    return jl

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("method", help="jira lib method to invoke")
    parser.add_argument("--path", help="path to xunit files",default="")
    parser.add_argument("--cycle", help="cycle name")
    parser.add_argument("--url", help="url of log file")
    parser.add_argument("--summary", help="issue summary")
    parser.add_argument("--filename", help="file name")
    parser.add_argument("--json", help="json file name")
    parser.add_argument("--keys", help="comma-separated issue keys")
    parser.add_argument("--key", help="single issue key")
    parser.add_argument("--status", help="new status")
    parser.add_argument("--epic", help="epic")
    parser.add_argument("--project", help="jira project")
    parser.add_argument("--no_update_status", dest="no_update", help="If present, do not update workflow status of test case", action='store_true')
    args = parser.parse_args()

    if args.project==None:
        jl = JIRA_LIB()
    else:
        jl = JIRA_LIB(args.project)
                       
    if (args.method == "update_testcases"):
        if args.cycle==None or args.url==None:
            print("update_testcases requires path, cycle, timestamp, and url")
            exit(1)
        else:
            jl.update_testcases(args.path,args.cycle,args.url,not args.no_update,args.status)
    elif (args.method == "find_issue_by_summary"):
        if args.summary==None:
            print("find_issue_by_summary requires summary")
            exit(1)
        else:
            jl.find_issue_by_summary(args.summary)
    elif (args.method == "map_issues_to_epics"):
        if args.filename==None or args.json==None:
            print("map_issues_to_epics requires an xml filename input and a json filename input")
            exit(1)
        else:
            jl.map_issues_to_epics(args.filename,args.json)
    elif (args.method == "reference_issue_to_issues"):
        if args.filename==None or args.json==None:
            print("reference_issue_to_issues requires an xml filename input and a json filename input")
            exit(1)
        else:
            jl.reference_issue_to_issues(args.filename,args.json)
    elif (args.method=="link_test_cases_to_issue"):
        if args.json==None or args.key==None:
            print("link_test_cases_to_issue requires a json filename, a project, and an issue key")
        else:
            jl.link_test_cases_to_issue(args.json,args.key,args.project)
    elif (args.method == "update_issue_status"):
        if args.keys==None:
            print("update_issue_status requires at least one issue key")
        else:
            key_list = args.keys.split(",")
            if args.status==None:
                jl.update_issue_status(key_list)
            else:
                jl.update_issue_status(key_list,args.status)
    elif (args.method == "reference_issue_to_issues"):
        key_list = args.keys.split(",")
        jl.reference_issue_to_issues(key_list,args.key,args.status)
    elif (args.method == "find_issues_in_epic"):
        jl.find_issues_in_epic(args.epic)
    elif (args.method == "get_linked_test_cases"):
        if args.key==None:
            print("get_linked_test_cases requires an issue key")
        else:
            tests = jl.get_linked_test_cases(args.key,args.status)
            print(str(tests))
