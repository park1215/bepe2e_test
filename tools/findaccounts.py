import sys, os
from s3lib import *
import psycopg2
import json
from credentials import *
from ncqueries import *
import sql_libs
import cx_Oracle

DEFAULT_INPUT = {"status":"OK","plan":"Cl%","created_before":"2019-10-01","created_after":"2019-09-01","next_bill_date":"2019-10-02 00:00:00","country":"ES"}
BEPE2E_NAME_PREFIX = "Bepe2e"
OUTPUT_HEADER = ['Account #', 'Plan', 'Status', 'Status Reason', 'Date Created', 'Next Bill Date']
ACCOUNTS = ('Clásica 30','Ilimitada 30','Ilimitada 50','Broce 50','Plata 30','Ora 50','Platino 150','Clasica 30')

def getPii(country=None):
    s3Instance = s3library("preprod-ira-spb-pii-exporter-pii-files")
    result = s3Instance.readFileFromBucket("pii.csv")
    if result[0]==False:
        print(result[1])
        return False
    else:
        lines = result[1].split("\n")
        bepe2e_accounts = []
        for line in lines:
            if BEPE2E_NAME_PREFIX in line:             
                linelist = line.split(';')
                if country is None or linelist[7]==country:
                    bepe2e_accounts.append(linelist[1])
        print("number of bepe2e accounts = "+str(len(bepe2e_accounts)))
        return bepe2e_accounts

def getAccountNumbers(payerRoleIds,before,after):
    query = "select billing_account_reference,payment_reference_value,create_date from rb_data_owner.billing_account where billing_pii_reference in %s and create_date<%s and create_date>%s"
    queryDict = {"data":tuple(payerRoleIds),"created_before":before,"created_after":after}
    output = sql_libs.querySPB(query,queryDict)
    accounts = []
    index =0
    for item in output:
        accounts.append(item[0])
    return accounts

############### start of script ############### 

if len(sys.argv)>1:
    filename = sys.argv[1]
    fi = open(filename,"r")
    input = json.loads(fi.read())
    fi.close()
    # use default if not present in input
    for key in DEFAULT_INPUT.keys():
        if key not in input and key not in ('plan','next_bill_date'):
            print("using default for input "+key)
            input[key] = DEFAULT_INPUT[key]   
else:
    input = DEFAULT_INPUT
    
# get all of the IRA PII entries with BEPE2E_NAME_PREFIX
payer_role_ids = getPii(input['country'])
print(str(len(payer_role_ids))+" payer role ids in PII")
if payer_role_ids == False:
    exit()
# look up account numbers in spb postgresdb
accounts = getAccountNumbers(payer_role_ids,input['created_before'],input['created_after'])
print(str(len(accounts))+" accounts found in postgresdb")
if accounts==False:
    exit()
if len(accounts)==0:
    print("no accounts available in postgresdb")
    exit()
    
# get account info from NC

nc_query = account_query % ('EU Internet',input['status'],tuple(accounts))
if 'plan' in input:
    nc_query = nc_query + " AND cpad.attribute_value like '" + input['plan'] + "'"
if 'next_bill_date' in input:
    nc_query = nc_query + "AND ac.next_bill_dtm = DATE '"+ input['next_bill_date'] + "'"

nc_query = nc_query + ")) ORDER BY acc_num DESC"

#print(nc_query)
result = sql_libs.queryNC(nc_query)
if result[0]=='Pass':
    fo = open('accounts.csv','w',encoding='utf-8')
    sep = ','
    fo.write(sep.join(OUTPUT_HEADER)+"\n")
    print(str(len(result[1]))+" accounts found in NC")
    for account in result[1]:
        account = list(account)
        try:
            index = account.index(None)
            if index>=0:
                account[index]="None"
        except:
            pass
        fo.write(sep.join(account)+"\n")
    fo.close()
else:
    print(result[0])