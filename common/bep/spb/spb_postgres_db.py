#!/usr/bin/python3.6

import sys
import psycopg2
import json
import os
from credentials import *
from sql_libs import *
import time
from robot.api import logger


class SPB_PG_API_Lib:

    # At initialization generates information needed for security header
    def __init__(self, inputLog=False):
        # Initialize username and password used in requests
        self._spb_pg_name = "SPB"
        self._spb_pg_port = "5432"
        self._spb_pg_username = SPG_PG_USERNAME

        #### Preprod Environment
        self._spb_pg_ip = "spbpreprod.cknuqmynawk0.us-west-2.rds.amazonaws.com"
        self._spb_pg_password = SPB_PG_PASSWORD

    def queryCustomerPartyId(self, CustomerPartyRoleId):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.customer_party where customer_party_role_id = '%s'""" % (CustomerPartyRoleId)
        output = querySPB(sqlCommand)     
        return output[0][0]

    def queryPayerPartyId(self, PayerPartyRoleId):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.payer_party where payer_party_role_id = '%s'""" % (PayerPartyRoleId)
        output = querySPB(sqlCommand)
        return output[0][0]


    def queryCustomerMapTable(self, CustomerPartyId, PayerPartyId):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.customer_payer_map where customer_party_id = '%s' AND payer_party_id = '%s'""" % (CustomerPartyId, PayerPartyId)
        output = querySPB(sqlCommand)

        return [output[0][3], output[0][0]]


    def queryProductPartyTable(self, CustomerPayerMapId):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.product_party where customer_payer_map_id = '%s'""" % (CustomerPayerMapId)
        output = querySPB(sqlCommand)
        return output[0][1]

    def getPiiFileLocationId(self):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.pii_reference_file where description = 'Location PII file from PSM'"""
        output = querySPB(sqlCommand)
        return output[0][0]

    def queryAccountProductsTable(self, productInstanceId):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.account_products where product_instance_id = '%s'"""% (productInstanceId)
        output = querySPB(sqlCommand)
        return output[0]

    def queryBillingAccountTable(self, billingAccount):
        sqlCommand = """SELECT * FROM
                      rb_data_owner.billing_account where billing_account_reference = '%s'"""% (billingAccount)
        output = querySPB(sqlCommand)
        return output[0]

    def queryBatchRequestTable(self, filename):
        sqlCommand = """SELECT * FROM batch_owner.batch_request_file where request_file_name = '%s'""" % (filename)
        response = querySPB(sqlCommand)
        if isinstance(response[0],tuple):
            return response[0][3]
        return None
                     
    def queryBillingAccount(self,accounts):
        columns = ['billing_account_reference','account_group_id','invoicing_organization_id','pii_reference_file_id','payment_reference_type_id', \
               'billing_pii_reference','mailing_pii_reference','billing_account_id','payment_reference_value','payment_system_payment_type']
        output = ''
        for account in accounts:
            output = output + "account: " + account + '\n'
            query = 'select '
            fields = ''
            for column in columns:
                fields = fields + column + ','
            fields = fields[:-1]
            query = query + fields
            output = output + fields + '\n'
            query = query + " from rb_data_owner.billing_account where billing_account_reference ='" + account +"'"
            response = querySPB(query)
            print(str(response))
            if response[0]=='Pass':
                for entry in response[1]:
                    output = output + str(entry) + ','
                output = output[:-1] + '\n'
        fo = open("spb_billing_account_"+accounts[0]+"_"+str(int(time.time()))+".csv","w")
        fo.write(output)
        print(output)
        fo.close()
        
def getRbPaymentMethodInfo(type,country):
    query = "select create_payment_mandate,rb_payment_method_id,rb_payment_method_name from rb_data_owner.payment_system_payment_method_map_vw where invoicing_organization_name='"+country+"' and \
            payment_system_payment_type='"+type+"'"
    logger.console("query = "+query)
    response = querySPB(query)
    logger.console(str(response))
    return  response

def getAccountNumbersByPayerRoleIds(payerRoleIds,after,before):
    # date in format YYYY-MM-DD
    query = "select billing_account_reference,payment_reference_value,create_date from rb_data_owner.billing_account where billing_pii_reference in %s and create_date<%s and create_date>%s"
    queryDict = {"data":tuple(payerRoleIds),"created_before":before,"created_after":after}
    output = querySPB(query,queryDict)
    accounts = []
    index =0
    for item in output:
        accounts.append(item[0])
    return accounts           
        
def getSpbDbInstance():
    return SPB_PG_API_Lib()

def useSpbPgApi(apiMethod,*argv):
    funcName = sys._getframe().f_code.co_name
    spbApi = SPB_PG_API_Lib()
    if apiMethod=='queryCustomerPartyId':
        result = spbApi.queryCustomerPartyId(argv[0])
    elif apiMethod == 'queryPayerPartyId':
        result = spbApi.queryPayerPartyId(argv[0])
    elif apiMethod == 'queryCustomerMapTable':
        result = spbApi.queryCustomerMapTable(argv[0], argv[1])
    elif apiMethod == 'queryProductPartyTable':
        result = spbApi.queryProductPartyTable(argv[0])
    elif apiMethod == 'queryAccountProductsTable':
        result = spbApi.queryAccountProductsTable(argv[0])
    elif apiMethod == 'queryBillingAccountTable':
        result = spbApi.queryBillingAccountTable(argv[0])
    elif apiMethod == 'getPiiFileLocationId':
        result = spbApi.getPiiFileLocationId()

    else:
       result =  (False,funcName + " Incorrect number of arguments for "+funcName)
    return result

if __name__ == "__main__":
    spbApi = SPB_PG_API_Lib()
    #result = spbApi.queryBatchRequestTable('VGBP_MEX_3019_20190820231050.txt')
    #print(result)
    spbApi.queryBillingAccount(['5000001059','5000001141','5000001145','5000001152'])