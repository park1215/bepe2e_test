from robot.api import logger
import argparse
import glob,os
import csv
from datetime import datetime
from new_compliance_config import *
import rb_configuration
from datetime import date
import time
import re
from dateutil.relativedelta import relativedelta
'''
QUERIES = ['productConfig','tariffConfig']
REQTS_HEADINGS =['Product_Family','Product_Name','Child_Price_Plan_Desc','Child_Price_Plan',
                'Charge_Type','Provisioning_Name_(VB/SDP)','Recurring_Rate','Min_Charge', 'Max_Charge','Rev_Code',               
                'Tax_Category_ID','Tax_Category_Description','Tax_Code_ID','Tax_Code_Description']
PRODUCT_CONFIG_HEADINGS = ["Product_Family_ID","Product_Family","Product_ID","Product_Name","Sales_Start_Date","Sales_End_Date","Tax_Category_Description","Tax_Code_Description"]
PRODUCT_ATTRIBUTES_HEADINGS = ['Product_Family_ID','Product_Family','Product_ID','Product_Name','Display_Position','Attribute_UA_Name','Attribute_Bill_Name','Mandatory']
'''
PRODUCT_ATTRIBUTES_UA_NAMES = {1:'PRODUCT_TYPE',2:'SERVICE_ITEM_REFERENCE',3:'MASTER_CATALOG_REFERENCE',4:'OLD_SERVICE_ITEM_REFERENCE'}
PRODUCT_ATTRIBUTES_BILL_NAMES = {1:'PRODUCT_TYPE',2:'SERVICE_ITEM_REFERENCE',3:'MASTER_CATALOG_REFERENCE',4:'OLD_SERVICE_ITEM_REFERENCE'}
#TARIFF_CONFIG_HEADINGS = ['Current_Catalog_Id','Market_Segment_name','Product_Family','Product_ID','Product_Name','Parent_Tariff_Id','Child_Tariff_Id','Child_Price_Plan',\
#                          'Child_Price_Plan_Desc','Tax_Category_Description','Tax_Code_Description','Charge_Period','Charge_Period_Units','Billed_In_Advance','Proratable','Refundable',\
#                          'Marginal_Price_Plan','Has_Contract','Contract_Term','Contract_Term_Units','Init_Rev_code','One_Time_Charge','Rev_Code','Recurring_Rate',\
#                          'Min_Override_Price','Max_Override_Price','Suspend_Rate','Suspend_Rev_Code','Suspend_Recurring_Rate','Suspend_Recur_Rev_Code','Term_Rev_Code','Term_Charge',\
#                          'ETF_Rev_Code', 'Early_Term_Fee','ETF_Proratable']
TARIFF_CONFIG_DEFAULTS = {'Market_Segment_Name':'Retail','Charge_Period':1,'Charge_Period_Units':'M','Billed_In_Advance':'T','Proratable':'T','Refundable':'T',\
                          'Marginal_Price_Plan':'F','Has_Contract':'F','Contract_Term':'','Contract_Term_Units':'','Init_Rev_code':'Undefined','One_Time_Charge':0, \
                          'Min_Override_Price':'','Max_Override_Price':'','Suspend_Rate':0,'Suspend_Rev_Code':'Undefined','Suspend_Recurring_Rate':0,'Term_Rev_Code':'Undefined',\
                          'Term_Charge':0,\
                          'ETF_Rev_Code':'', 'Early_Term_Fee':'','ETF_Proratable':'F'}
#OTC_CHARGES_HEADINGS = ['Market_Segment_Name','OTC','OTC_Type_Name','OTC_Tariff_Name','Min_Charge','Max_Charge','Rev_Code','Tax_Category_ID','Tax_Category_Description','Tax_Code_ID',\
#                        'Tax_Code_Description']
#OTC_ATTRIBUTES_HEADINGS = ['Market_Segment_Name','OTC','OTC_ID','OTC_Attribute_Name','Display_Position','Mandatory']
OTC_ATTRIBUTE_NAMES = {1:'ONE_TIME_CHARGE_REFERENCE',2:'MASTER_CATALOG_REFERENCE',3:'OLD_ONE_TIME_CHARGE_REFERENCE',4:'ONE_TIME_CHARGE_TYPE'}
OTC_CHARGES_DEFAULTS = {'OTC':'Child_Price_Plan_Desc','OTC_Type_Name':'Child_Price_Plan_Desc','OTC_Tariff_Name':'Child_Price_Plan_Desc'}
#TAX_CODE_HEADINGS = ['Product_Family_ID','Product_Family','Product_ID','Product_Name','Tax_Category_ID','Tax_Category_Description','Tax_Code_ID','Tax_Code_Description',"Sales_Start_Date","Sales_End_Date"]
# ASK ABOUT THIS ONE - IS SUSPEND = UNLESS OVERRIDDEN IN REQUIREMENTS?
TARIFF_CONFIG_DUPLICATES = {'Suspend_Recur_Rev_Code':'Rev_Code'}

class verifyNewRequirements():
    def __init__(self):
        self.reqtHeaders = []
        self.productRequirements = []
        self.otcRequirements = []
        self.config = rb_configuration.Configuration()

    def getHeadings(self,row):
        headers = []
        for entry in row:
            header = entry.strip()
            headers.append(header)
        return headers
        
    def extractRequirements(self,reqtsFilename):
        self.requirements=[]
        addStartDate = False
        addEndDate = False
        with open(reqtsFilename) as csvfile:
            reader = csv.reader(csvfile)
            i =0
            for row in reader:
                if i==0:
                    self.reqtHeaders = self.getHeadings(row)
                    if 'Sales_Start_Date' not in self.reqtHeaders:
                        today = date.today()
                        today = today.replace(day=1)
                        salesStartDate = today + relativedelta(months=1)
                        salesStartTimestamp = time.mktime(datetime.strptime(str(salesStartDate), "%Y-%m-%d").timetuple())
                        addStartDate = True
                    if 'Sales_End_Date' not in self.reqtHeaders:
                        salesEndDate = ''
                        addEndDate = True
                else:
                    requirement = {}
                    index = 0
                    # convert row to dictionary
                    for input in row:
                        input = input.strip()
                        if input == "-": input=0
                        if (self.reqtHeaders[index] == 'Min_Charge' or self.reqtHeaders[index] == 'Max_Charge'):
                            if input != 'N/A':
                                #convert parentheses format for negative number to minus sign
                                if isinstance(input,str):                                
                                    if input[0]=="(" and input[-1]==")":
                                        input = input.replace("(","-")
                                        input = input.replace(")","")
                                    try:
                                        input = float(input.replace(",",""))
                                        input = input*1000
                                    except:
                                        pass
                                elif isinstance(input,int):
                                    input = float(input)
                            else:
                                input = 0.0
                        if self.reqtHeaders[index] == 'Recurring_Rate':
                            try:
                                input = float(input)
                                input = int(input*1000)
                            except:
                                pass
                        if self.reqtHeaders[index] == 'Sales_Start_Date' or self.reqtHeaders[index] == 'Sales_End_Date':
                            input = time.mktime(datetime.strptime(str(input), "%Y-%m-%d").timetuple())
                            
                        requirement[self.reqtHeaders[index]]=input
                        index = index + 1
                        # there are extra columns that we don't use
                        if index==len(self.reqtHeaders):
                            break
                    if requirement['Charge_Type']=='Product/Tariff':
                        if addStartDate:
                            requirement['Sales_Start_Date'] = salesStartTimestamp
                        if addEndDate:
                            requirement['Sales_End_Date'] = salesEndDate
                        self.productRequirements.append(requirement)
                        for key,value in TARIFF_CONFIG_DEFAULTS.items():
                           if key not in requirement:
                               requirement[key] = value
                        self.productRequirements.append(requirement)      
                    elif requirement['Charge_Type']=='OTC':
                        for key,value in OTC_CHARGES_DEFAULTS.items():
                            if key not in requirement:
                                requirement[key] = requirement[value]
                        self.otcRequirements.append(requirement)                     
                i = i + 1

    def verify_productConfig(self,queryFilename):
        self.productConfigQuery = []
        query = {}
        finalResult = []
        with open(realPath("./"+queryFilename)) as csvfile:
            reader = csv.reader(csvfile)
            i = 0
            for row in reader:
                if i==0:
                    self.productConfigHeaders = self.getHeadings(row)
                    logger.console(str(self.productConfigHeaders))
                else:
                    index = 0
                    query = {}
                    for input in row:
                        if self.productConfigHeaders[index]=='Sales_Start_Date':
                            #input = re.sub(r"^([1-9])(-.*)",r"0\1\2",input)
                            input = re.sub(r"([0-9\-]*)\s.*",r"\1",input)
                            input = time.mktime(datetime.strptime(str(input), "%Y-%m-%d").timetuple())
                            logger.console(input)
                        query[self.productConfigHeaders[index]]=input                        
                        index = index + 1
                    self.productConfigQuery.append(query)
                i = i + 1
        # track the query rows that matched a requirement (note that more than one requirement may map to the same query row)
        matched = {}
        # i-1 because first row is header. After checking all requirements, all queries should have matched at least one requirement
        for j in range(0,i-1):
            matched[j]=False
        
        # loop through values for all queries and just get the relevant ones
        # "row" contains requirement values for a new product
        for row in self.productRequirements:
            # find matching row in actual query results
            result, rowIndex, matchedRow = self.findMatch(row,self.productConfigQuery)
            if result==True:
                matched[rowIndex] = True
                row['Product_Family_ID'] = matchedRow['Product_Family_ID']
                row['Product_ID'] = matchedRow['Product_ID']
            else:
                failure = "FAILURE: requirement "+str(row)+" does not have a matching product configuration query row"
                finalResult.append(failure)
                logger.console(failure)
                       
        for key,value in matched.items():
            if value==False:
                failure = "FAILURE: product configuration query row "+str(key)+" does not have a matching requirement"
                finalResult.append(failure)
                logger.console(failure)
             
        return finalResult

    def verify_tariffConfig(self,queryFilename):
        self.tariffConfigQuery = []
        query = {}
        finalResult = []
        with open(realPath("./"+queryFilename)) as csvfile:
            reader = csv.reader(csvfile)
            i = 0
            for row in reader:
                if i==0:
                    self.tariffConfigHeaders = self.getHeadings(row)
                else:
                    index = 0
                    query = {}
                    for input in row:
                        query[self.tariffConfigHeaders[index]]=input                        
                        index = index + 1
                    self.tariffConfigQuery.append(query)
                i = i + 1
                
        for header in TARIFF_CONFIG_DEFAULTS.keys():
            if header not in self.reqtHeaders:
                for row in self.productRequirements:
                    row[header] = TARIFF_CONFIG_DEFAULTS[header]
                    break

        # track the query rows that matched a requirement (note that more than one requirement may map to the same query row)
        matched = {}
        # i-1 because first row is header. After checking all requirements, all queries should have matched at least one requirement
        for j in range(0,i-1):
            matched[j]=False
        
        # loop through values for all queries and just get the relevant ones
        # "row" contains requirement values for a new product
        for row in self.productRequirements:
            # find matching row in actual query results
            result, rowIndex, matchedRow = self.findMatch(row,self.tariffConfigQuery)
            if result==True:
                matched[rowIndex] = True
            else:
                failure = "FAILURE: requirement "+str(row)+" does not have a matching tariff configuration query row"
                finalResult.append(failure)
                logger.console(failure)
                
        for key,value in matched.items():
            if value==False:
                failure = "FAILURE: tariff configuration query row "+str(key)+" does not have a matching requirement"
                finalResult.append(failure)
                logger.console(failure)
                
        return finalResult
                
    def verify_productAttribute(self,queryFilename):
        self.productAttributesQuery = []
        query = {}
        finalResult = []
        with open(realPath("./"+queryFilename)) as csvfile:
            reader = csv.reader(csvfile)
            i = 0
            for row in reader:
                if i==0:
                    self.productAttributeHeaders = self.getHeadings(row)
                else:
                    index = 0
                    query = {}
                    for input in row:
                        query[self.productAttributeHeaders[index]]=input                        
                        index = index + 1
                    self.productAttributesQuery.append(query)
                i = i + 1        
        # track the query rows that matched a requirement (note that more than one requirement may map to the same query row)
        matched = {}
        # i-1 because first row is header. After checking all requirements, all queries should have matched at least one requirement
        for j in range(0,i-1):
            matched[j]=False
        
        # loop through values for all queries and just get the relevant ones
        # "row" contains requirement values for a new product
        for row in self.productRequirements:
            # find matching rows in actual query results
            result, rowIndexes, matchedRows = self.findMatch(row,self.productAttributesQuery,True)
            if result==True:
                for index in rowIndexes:
                    matched[index] = True
                matchIndex = 0
                bills = PRODUCT_ATTRIBUTES_BILL_NAMES.copy()
                uas= PRODUCT_ATTRIBUTES_UA_NAMES.copy()
                if len(matchedRows)!=len(PRODUCT_ATTRIBUTES_UA_NAMES):
                    failure = "FAILURE:number of product attribute rows with product id = "+row['Product_ID']+" is "+str(len(matchedRows) )
                    finalResult.append(failure)
                    logger.console(failure)
                # matched rows should have each of the values in ...BILL... and ...UA...dictionaries
                for matchedRow in matchedRows: 
                    for key,value in PRODUCT_ATTRIBUTES_UA_NAMES.items():
                        if matchedRow['Display_Position']==str(key) and matchedRow['Attribute_UA_Name']==value and matchedRow['Attribute_Bill_Name']==PRODUCT_ATTRIBUTES_BILL_NAMES[key]:
                            del bills[key]
                            del uas[key]
                if len(bills.keys()) != 0 or len(uas.keys()) !=0:
                    missingBills = ''
                    for key,bill in bills.items():
                        missingBills = missingBills + "," + bill
                    missingBills = missingBills[1:]
                    missingUas = ''
                    for key,ua in uas.items():
                        missingUas = missingUas + "," + ua
                    missingUas = missingUas[1:]
                    failure = "FAILURE: product attributes for product id = "+row['Product_ID']+" are missing Attribute_Bill_Name(s) = " + missingBills+ ' and Attribute_Ua_Name(s) = ' + missingUas
                    finalResult.append(failure)
                    logger.console(failure)
            else:
                failure = "FAILURE: requirement "+str(row)+" does not have a matching product attribute query row"
                finalResult.append(failure)
                logger.console(failure)

        for key,value in matched.items():
            if value==False:
                failure = "FAILURE: product attribute query row "+str(key)+" does not have a matching requirement"
                finalResult.append(failure)
                logger.console(failure)
                
        return finalResult

    def verify_otcCharge(self,queryFilename):
        self.otcChargesQuery = []
        query = {}
        finalResult = []
        with open(realPath("./"+queryFilename)) as csvfile:
            reader = csv.reader(csvfile)
            i = 0
            for row in reader:
                if i==0:
                    self.otcChargesHeaders = self.getHeadings(row)
                    #logger.console(str(self.productConfigHeaders))
                else:
                    index = 0
                    query = {}
                    for input in row:
                        input = input.strip()
                        if self.otcChargesHeaders[index]=='Max_Charge' or self.otcChargesHeaders[index]=='Min_Charge':
                            if input=='-':
                                input=0.0
                            elif input=='':
                                input=0.0
                            else:
                                try:
                                    input = float(input.replace(",",""))
                                except:
                                    pass
                        query[self.otcChargesHeaders[index]]=input                        
                        index = index + 1
                    self.otcChargesQuery.append(query)
                i = i + 1
        # track the query rows that matched a requirement (note that more than one requirement may map to the same query row)
        matched = {}
        # i-1 because first row is header. After checking all requirements, all queries should have matched at least one requirement
        for j in range(0,i-1):
            matched[j]=False
        
        # loop through values for all queries and just get the relevant ones
        # "row" contains requirement values for a new product

        for row in self.otcRequirements:
            # find matching row in actual query results
            result, rowIndex, matchedRow = self.findMatch(row,self.otcChargesQuery)
            if result==True:
                matched[rowIndex] = True
                row['OTC_ID'] = matchedRow['OTC_ID']
            else:
                failure = "FAILURE: requirement "+str(row)+" does not have a matching otc query row"
                finalResult.append(failure)
                logger.console(failure)
                       
        for key,value in matched.items():
            if value==False:
                failure = "FAILURE: OTC charges query row "+str(key)+" does not have a matching requirement"
                finalResult.append(failure)
                logger.console(failure)
                
        return finalResult

    def verify_otcAttribute(self,queryFilename):
        self.otcAttributesQuery = []
        query = {}
        finalResult =[]
        with open(realPath("./"+queryFilename)) as csvfile:
            reader = csv.reader(csvfile)
            i = 0
            for row in reader:
                if i==0:
                    self.otcAttributeHeaders = self.getHeadings(row)
                else:
                    index = 0
                    query = {}
                    for input in row:
                        query[self.otcAttributeHeaders[index]]=input                        
                        index = index + 1
                    self.otcAttributesQuery.append(query)
                i = i + 1        
        # track the query rows that matched a requirement (note that more than one requirement may map to the same query row)
        matched = {}
        # i-1 because first row is header. After checking all requirements, all queries should have matched at least one requirement
        for j in range(0,i-1):
            matched[j]=False
        
        # loop through values for all queries and just get the relevant ones
        # "row" contains requirement values for a new product
        for row in self.otcRequirements:
            # find matching rows in actual query results
            result, rowIndexes, matchedRows = self.findMatch(row,self.otcAttributesQuery,True)
            if result==True:
                for index in rowIndexes:
                    matched[index] = True
                matchIndex = 0
                attributes = OTC_ATTRIBUTE_NAMES.copy()
                if len(matchedRows)!=len(OTC_ATTRIBUTE_NAMES):
                    failure = "FAILURE:number of OTC attribute rows with OTC id = "+row['OTC_ID']+" is "+str(len(matchedRows) )
                    finalResult.append(failure)
                    logger.console(failure)
                # matched rows should have each of the values in attributes dictionary
                for matchedRow in matchedRows:
                    for key,value in OTC_ATTRIBUTE_NAMES.items():
                        if matchedRow['Display_Position']==str(key) and matchedRow['OTC_Attribute_Name']==value:
                            del attributes[key]
                if len(attributes.keys()) != 0:
                    missingAttributes = ''
                    for key,attribute in attributes.items():
                        missingAttributes = missingAttributes + "," + attribute
                    missingAttributes = missingAttributes[1:]
                    failure = "FAILURE: otc attributes for otc id = "+row['OTC_ID']+" are missing Attribute_Name(s) = " + missingAttributes
                    finalResult.append(failure)
                    logger.console(failure)
            else:
                failure = "FAILURE: requirement "+str(row)+" does not have a matching otc attribute query row"
                finalResult.append(failure)
                logger.console(failure)


        for key,value in matched.items():
            if value==False:
                failure = "FAILURE: otc attribute query row "+str(key)+" does not have a matching requirement"
                finalResult.append(failure)
                logger.console(failure)
                
        return finalResult
    
    def verify_taxCode(self,queryFilename):
        self.taxCodeQuery = []
        query = {}
        finalResult = []
        with open(realPath("./"+queryFilename)) as csvfile:
            reader = csv.reader(csvfile)
            i = 0
            for row in reader:
                if i==0:
                    self.taxCodeHeaders = self.getHeadings(row)
                else:
                    index = 0
                    query = {}
                    for input in row:
                        if self.taxCodeHeaders[index]=='Sales_Start_Date':
                            #input = re.sub(r"^([1-9])(-.*)",r"0\1\2",input)
                            input = re.sub(r"([0-9\-]*)\s.*",r"\1",input)
                            input = time.mktime(datetime.strptime(str(input), "%Y-%m-%d").timetuple())                            
                        query[self.taxCodeHeaders[index]]=input
                        index = index + 1
                    self.taxCodeQuery.append(query)
                i = i + 1

        # track the query rows that matched a requirement (note that more than one requirement may map to the same query row)
        matched = {}
        # i-1 because first row is header. After checking all requirements, all queries should have matched at least one requirement
        for j in range(0,i-1):
            matched[j]=False
        
        # loop through values for all queries and just get the relevant ones
        # "row" contains requirement values for a new product
        for row in self.productRequirements:
            # find matching row in actual query results
            result, rowIndex, matchedRow = self.findMatch(row,self.taxCodeQuery)
            if result==True:
                matched[rowIndex] = True
            else:
                failure = "FAILURE: requirement "+str(row)+" does not have a matching tax code query row"
                finalResult.append(failure)
                logger.console(failure)

        for key,value in matched.items():
            if value==False:
                failure = "FAILURE: tax code query row "+str(key)+" does not have a matching requirement"
                finalResult.append(failure)
                logger.console(failure)
        
        return finalResult
                
    # match requirement row (needle) to entry in query results
    def findMatch(self,needle,haystack,multiple=False,log=False):
        if log==True: logger.console('NEEDLE:'+str(needle))
        rows = []
        rowIndexes = []
        rowIndex = -1        
        for row in haystack:
            if log==True: logger.console('ROW:'+str(row))
            rowIndex = rowIndex + 1
            match = True
            for key,value in row.items():
                if key in needle:
                    if type(needle[key]) != type(value):
                        if isinstance(needle[key],int) and isinstance(value,float):
                            check = float(needle[key]) == value
                        elif isinstance(needle[key],float) and isinstance(value,int):
                            check = needle[key] == float(value)
                        else:
                            check = str(needle[key])==str(value)
                    else:
                        check = needle[key]==value
                    if check==False:
                        if log==True: logger.console(key+":"+str(needle[key])+","+str(value))
                        match = False
                        break
            if match == True:
                if multiple==True:
                    rows.append(row)
                    rowIndexes.append(rowIndex)
                else:
                    return match, rowIndex, row
        if len(rows)>0: match=True
        return match, rowIndexes, rows
    

def realPath(filename):
    return os.path.join(os.path.dirname(os.path.realpath(__file__)),filename)    
    
# run verification tests for new query rows, whose existence is determined by presence of file format "additional_<query>_<timestamp>.csv"                                
def newTests(reqts_filename):
    verify = verifyNewRequirements()
    results = {}
    verify.extractRequirements(realPath("./"+reqts_filename))
    #verify.verify_productConfig('additional_productConfig_2019-06-07_16_42_48.csv')

    availableFiles = []
    for file in glob.glob(realPath("./additional*.csv")):
        availableFiles.append(os.path.basename(file))

    # product id and otc id among other things need to be extracted before other queries are checked
    orderedQueryNames = ['productConfig','tariffConfig','productAttribute','otcCharge','otcAttribute','taxCode']
    #orderedQueryNames = ['productConfig','tariffConfig']
    for query in orderedQueryNames:
        for file in availableFiles:
            if query in file:
                matches = re.match(".*additional_([a-zA-Z0-9]*).*",file)
                testname = "verify_"+matches.groups()[0]
                logger.console(testname)
                result = getattr(verify, testname)(file)
                if len(result)==0:
                    result = ["PASS",""]
                else:
                    result = ["FAIL"] + result
                results[query] = result
                logger.console(results[matches.groups()[0]])
                break
        if query not in results:
            results[query] = ["PASS","no new rows"]
    fo = open("new_results.log","w")
    fo.write(str(results))
    fo.close()
    
    return results
  
if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--reqts_filename", dest="reqts_filename", help="CSV file containing requirements")
    #parser.add_argument("--query_filename", dest="query_filename", help="CSV file containing product config query, new rows only")
    #parser.add_argument("--timestamp_suffix", dest="timestamp_suffix", help="timestamp of lastest query")
    args = parser.parse_args()
    results = newTests(args.reqts_filename)
    print(str(results))
    '''
    verify = verifyNewRequirements();
    verify.extractRequirements(args.reqts_filename)
    
    
    verify.verify_productConfig('additional_productConfig_2019-06-19_19_22_23.csv')

    verify.verify_tariffConfig('additional_tariffConfig_2019-06-19_19_22_23.csv')
    verify.verify_productAttribute('additional_productAttribute_2019-06-19_19_22_23.csv')
    verify.verify_otcCharge('additional_otcCharge_2019-06-19_19_22_23.csv')
    verify.verify_otcAttribute('additional_otcAttribute_2019-06-19_19_22_23.csv')
    verify.verify_taxCode('additional_taxCode_2019-06-19_19_22_23.csv')
    '''
    #locals()["verify_"+QUERIES[0]](args.reqts_filename,QUERIES[0]+"_"+args.timestamp_suffix+".csv")

