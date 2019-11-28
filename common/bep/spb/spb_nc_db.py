#!/usr/bin/python3.6

import sys
import json
import random
import os
import jaydebeapi
import cx_Oracle
import time
from credentials import *
from spb_parameters import *
from sql_libs import *
from nc_queries import *
from robot.api import logger

NC_TABLES_BEFORE = {"account":{"index":"account_num","fields":["customer_ref","billing_status","total_billed_tot","total_paid_tot","info_currency_code"]}, \
             "accountpayment":{"index":"account_num","fields":["created_dtm","account_payment_status","account_payment_seq","account_payment_mny","account_payment_dat"]}, \
             "physicalpayment":{"index":"customer_ref","fields":["created_dtm","physical_payment_status","physical_payment_mny","physical_payment_dat","currency_code","payment_method_id"]}, \
             "prmandate":{"index":"account_num","fields":["payment_method_id","active_to_dat","active_from_dat","mandate_ref","mandate_attr_1"]}}
NC_TABLES_AFTER = {"billrequest":{"index":"account_num","fields":["bill_seq","request_seq","bill_dat","bill_request_status","bill_type_id"]}, \
                   "billsummary":{"index":"account_num","fields":["bill_seq","invoice_tax_mny","balance_fwd_mny","bill_dtm","invoice_net_mny","bill_type_id", \
                       "balance_out_mny","outstanding_debt_mny","invoice_num","actual_bill_dtm","start_of_bill_dtm"]}, \
                   "paymentrequest":{"index":"account_num","fields":["payment_request_seq","request_mny","bill_seq","collection_dat","request_status","mandate_ref"]}}


class SPB_NC_API_Lib:

    # At initialization generates information needed for security header
    def __init__(self, inputLog=False):
        os.environ['TNS_ADMIN'] = '/etc/oracle/rb_qa_tns_admin'
        self._spb_nc_db_string = RB_QA_DSN

    def _realPath(self, filename):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)), filename)

    def queryNcAccountTable(self, accountNumber):
        sqlCommand = """SELECT * FROM ACCOUNT WHERE ACCOUNT_NUM = '%s'""" % (accountNumber)
        response = queryNC(sqlCommand)

        if response[0] == 'Pass':
            return response[1][0][1]
        else:
            return None

    def queryNcToFindActiveAccount(self, planName):
        logger.info(planName)
        sqlCommand = """SELECT
                          /*csv*/
                        NULL AS "PRODUCTS",
                        cust_ref,
                        acc_num,
                        sub_ref,
                        prd_seq,
                        prd_id,
                        tariff_id,
                        wb_ref,
                        product_name,
                        tariff_name,
                        status,
                        status_reason,
                        cust_reln_id,
                        TO_CHAR(effective_dtm, 'YYYY-MM-DD HH24:MI:SS') AS effective_date,
                        event_source,
                        TO_CHAR(start_dtm, 'YYYY-MM-DD HH24:MI:SS') AS event_source_start_date,
                        CASE
                            WHEN event_source = next_mac_by_cust THEN NULL
                            ELSE TO_CHAR(end_dtm, 'YYYY-MM-DD HH24:MI:SS')
                        END AS event_source_end_date
                    FROM
                        (
                            SELECT cust_ref,
                            acc_num,
                            sub_ref,
                            prd_seq,
                            prd_id,
                            tariff_id,
                            wb_ref,
                            product_name,
                            tariff_name,
                            status,
                            status_reason,
                            cust_reln_id,
                            effective_dtm,
                            event_source,
                            start_dtm,
                            end_dtm,
                            LEAD(event_source, 1, NULL) OVER (PARTITION BY cust_ref
                        ORDER BY
                            cust_ref,
                            prd_seq,
                            effective_dtm,
                            end_dtm) AS next_mac_by_cust
                        FROM
                            (
                                SELECT ac.customer_ref AS cust_ref,
                                ac.account_num AS acc_num,
                                chp.subscription_ref AS sub_ref,
                                cps.product_seq AS prd_seq,
                                chp.product_id AS prd_id,
                                cptd.tariff_id,
                                cpad.attribute_value AS wb_ref,
                                p.product_name,
                                t.tariff_name,
                                cps.product_status AS status,
                                cps.status_reason_txt AS status_reason,
                                prm.MANDATE_ATTR_1 AS cust_reln_id,
                                cps.effective_dtm,
                                ces.event_source,
                                ces.start_dtm,
                                end_dtm
                            FROM
                                geneva_admin.custhasproduct chp,
                                geneva_admin.product p,
                                geneva_admin.custproductstatus cps,
                                geneva_admin.custproductattrdetails cpad,
                                geneva_admin.account ac,
                                geneva_admin.accountattributes aa,
                                geneva_admin.custproducttariffdetails cptd,
                                geneva_admin.tariff t,
                                geneva_admin.custeventsource ces,
                                GENEVA_ADMIN.PRMANDATE prm,
                                (
                                    SELECT TO_DATE('2099-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS') AS end_date
                                FROM
                                    dual ) a
                            WHERE
                                ac.account_num = aa.account_num(+)
                                AND ac.customer_ref = chp.customer_ref(+)
                                AND chp.product_id = p.product_id(+)
                                AND chp.customer_ref = cps.customer_ref(+)
                                AND chp.product_seq = cps.product_seq(+)
                                AND chp.customer_ref = cpad.customer_ref (+)
                                AND chp.product_seq = cpad.product_seq (+)
                                AND cps.customer_ref = cptd.customer_ref(+)
                                AND cps.product_seq = cptd.product_seq(+)
                                AND cptd.tariff_id = t.tariff_id(+)
                                AND chp.customer_ref = ces.customer_ref (+)
                                AND chp.product_seq = ces.product_seq (+)
                                AND ac.ACCOUNT_NUM = prm.ACCOUNT_NUM (+)
                                --AND ac.account_num = '5000001097'
                                AND t.TARIFF_NAME = '%s'
                                AND cps.product_status NOT IN ('TX')
                                AND cps.product_status = 'OK'
                                AND cpad.PRODUCT_ATTRIBUTE_SUBID = 8
                            ORDER BY
                                ac.account_num DESC))""" % (planName)
        logger.info(sqlCommand)
        response = queryNC(sqlCommand)

        if response[0] == 'Pass':
            randomAccount = random.choice(response[1])
            logger.info(randomAccount)
            return randomAccount
        else:
            return None

    def getLedgerBalance(self, accountNumber):
        sqlCommand = """SELECT total_billed_tot,total_paid_tot,currency_code FROM ACCOUNT WHERE ACCOUNT_NUM = '%s'""" % (
            accountNumber)
        response = queryNC(sqlCommand)
        logger.info('NC account = ' + str(response))
        if response[0] == 'Pass':
            ledgerBalance = response[1][0][0] - response[1][0][1]
            return ledgerBalance, response[1][0][2]
        else:
            return 'Fail', 0

    def getPhysicalPaymentEntry(self, accountNumber):
        sqlCommand = """SELECT physical_payment_mny,payment_method_id,currency_code FROM PHYSICALPAYMENT WHERE customer_ref = '%s'""" % (
            accountNumber)
        response = queryNC(sqlCommand)
        logger.console(response[1])
        if response[0] == 'Pass':
            return response[1][0][0], response[1][0][1], response[1][0][2]
        else:
            return 'Fail', 0, 0

    def queryNcTariffTable(self, tariffDesc, countryCode):
        sqlCommand = """SELECT * FROM TARIFF WHERE TARIFF_DESC = '%s'""" % (tariffDesc)
       # if countryCode == "NO" and tariffName == "Equipment Lease Fee":
       #     sqlCommand = """SELECT * FROM TARIFF WHERE TARIFF_NAME = '%s' and TARIFF_DESC='Equipment Lease Fee'""" % (tariffName)
       # elif countryCode == "PL" and tariffName == "Equipment Lease Fee":
       #     sqlCommand = """SELECT * FROM TARIFF WHERE TARIFF_NAME = '%s' and TARIFF_DESC='Equipment Lease Fee'""" % (tariffName)
       # else:
       #     sqlCommand = """SELECT * FROM TARIFF WHERE TARIFF_NAME = '%s'""" % (tariffName)
        # returns "pass/fail" and then response to query (if pass)
        logger.info(sqlCommand)
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            return True, response[1][0][0]
        else:
            return False, None

    def getProductId(self, productName, countryCode=None):
        logger.info("inputs are")
        logger.info(productName)
        logger.info(countryCode)

        if productName=='Contract':
            if countryCode == "MX":
                sqlCommand = """SELECT * FROM PRODUCT WHERE PRODUCT_NAME = '%s' and product_family_id='108'""" % (productName)
            else:
                sqlCommand = """SELECT * FROM PRODUCT WHERE PRODUCT_NAME = '%s' and product_family_id='104'""" % (productName)
        elif productName == 'Lease Fee - Monthly':
            if countryCode == "NO" or countryCode == "PL":
                sqlCommand = """SELECT * FROM PRODUCT WHERE PRODUCT_NAME = '%s' and product_family_id='105'""" % (productName)
            elif countryCode == "MX":
                sqlCommand = """SELECT * FROM PRODUCT WHERE PRODUCT_NAME = '%s' and product_family_id='102'""" % (productName)
        else:
            sqlCommand = """SELECT * FROM PRODUCT WHERE PRODUCT_NAME = '%s'""" % (productName)

        logger.info(sqlCommand)
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            return True, response[1][0][0]
        else:
            return False, None

    def queryNcPRMandateTable(self, accountNumber):

        sqlCommand = """SELECT * FROM PRMANDATE WHERE account_num = '%s'""" % (accountNumber)
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            if len(response[1])>0:
                return True, response[1][0]
            else: return True, response[1]
        else:
            return False, None

    def queryNcPaymentMethodTable(self, paymentMethodName):
        sqlCommand = """SELECT * FROM PAYMENTMETHOD WHERE payment_method_name = '%s'""" % (paymentMethodName)
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            return True, response[1]
        else:
            return False, None

    def queryNcAccHasOTCTable(self, accountNumber):

        sqlCommand = """SELECT * FROM ACCHASONETIMECHARGE WHERE account_num = '%s' ORDER BY OTC_DTM DESC""" % (accountNumber)
        logger.info(sqlCommand)        
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            logger.info(response)
            return True, response[1][0]
        else:
            return False, None

    def queryNcOneTimeChargeTable(self, otcName):

        sqlCommand = """SELECT * FROM ONETIMECHARGE WHERE OTC_NAME = '%s'""" % (otcName)
        logger.info(sqlCommand)      
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            return True, response[1][0]
        else:
            return False, None

    def queryNcCustomerContractTable(self, custRef):

        sqlCommand = """SELECT * FROM CUSTOMERCONTRACT WHERE CUSTOMER_REF = '%s'""" % (custRef)
        logger.info(sqlCommand)      
        response = queryNC(sqlCommand)
        if response[0] == 'Pass':
            return True, response[1]
        else:
            return False, None

    def queryNcProductTable(self, accountNumber, productStatus, subscriptionRef):
        if subscriptionRef == 'None':
            sqlCommand = """SELECT /*csv*/ NULL AS "PRODUCTS", cust_ref,
                       acc_num,
                       sub_ref,
                       prd_seq,
                       prd_id,
                       tariff_id,
                       wb_ref,
                       product_name,
                       tariff_name,
                       status,
                       status_reason,
                       TO_CHAR(effective_dtm, 'YYYY-MM-DD HH24:MI:SS') AS effective_date,
                       event_source,
                       TO_CHAR(start_dtm, 'YYYY-MM-DD HH24:MI:SS') AS event_source_start_date,
                       CASE
                         WHEN event_source = next_mac_by_cust
                         THEN NULL
                         ELSE TO_CHAR(end_dtm, 'YYYY-MM-DD HH24:MI:SS')
                       END AS event_source_end_date
                     FROM
                       (SELECT cust_ref,
                         acc_num,
                         sub_ref,
                         prd_seq,
                         prd_id,
                         tariff_id,
                         wb_ref,
                         product_name,
                         tariff_name,
                         status,
                         status_reason,
                         effective_dtm,
                         event_source,
                         start_dtm,
                         end_dtm,
                         LEAD(event_source,1,NULL) OVER (PARTITION BY cust_ref ORDER BY cust_ref,prd_seq,effective_dtm,end_dtm) AS next_mac_by_cust
                       FROM
                         (SELECT ac.customer_ref AS cust_ref,
                           ac.account_num AS acc_num,
                           chp.subscription_ref   AS sub_ref,
                           cps.product_seq        AS prd_seq,
                           chp.product_id         AS prd_id,
                           cptd.tariff_id,
                           cpad.attribute_value AS wb_ref,
                           p.product_name,
                           t.tariff_name,
                           cps.product_status    AS status,
                           cps.status_reason_txt AS status_reason,
                           cps.effective_dtm,
                           ces.event_source,
                           ces.start_dtm,
                           end_dtm
                         FROM geneva_admin.custhasproduct chp,
                           geneva_admin.product p,
                           geneva_admin.custproductstatus cps,
                           geneva_admin.custproductattrdetails cpad,
                           geneva_admin.account ac,
                           geneva_admin.accountattributes aa,
                           geneva_admin.custproducttariffdetails cptd,
                           geneva_admin.tariff t,
                           geneva_admin.custeventsource ces,
                           (SELECT TO_DATE('2099-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS') AS end_date
                           FROM dual ) a
                         WHERE ac.account_num              = aa.account_num(+)
                         AND ac.customer_ref               = chp.customer_ref(+)
                         AND chp.product_id                = p.product_id(+)
                         AND chp.customer_ref              = cps.customer_ref(+) 
                         AND chp.product_seq               = cps.product_seq(+)
                         AND chp.customer_ref              = cpad.customer_ref (+)
                         AND chp.product_seq               = cpad.product_seq (+)
                         AND cps.customer_ref              = cptd.customer_ref(+)
                         AND cps.product_seq               = cptd.product_seq(+)
                         AND cptd.tariff_id               = t.tariff_id(+)     
                         AND chp.customer_ref              = ces.customer_ref (+)
                         AND chp.product_seq               = ces.product_seq (+)
                         AND ac.account_num = '%s' 
                         AND cps.product_status = '%s'))""" % (accountNumber, productStatus)

        else:

            sqlCommand = """SELECT /*csv*/ NULL AS "PRODUCTS", cust_ref,
                                              acc_num,
                                              sub_ref,
                                              prd_seq,
                                              prd_id,
                                              tariff_id,
                                              wb_ref,
                                              product_name,
                                              tariff_name,
                                              status,
                                              status_reason,
                                              TO_CHAR(effective_dtm, 'YYYY-MM-DD HH24:MI:SS') AS effective_date,
                                              event_source,
                                              TO_CHAR(start_dtm, 'YYYY-MM-DD HH24:MI:SS') AS event_source_start_date,
                                              CASE
                                                WHEN event_source = next_mac_by_cust
                                                THEN NULL
                                                ELSE TO_CHAR(end_dtm, 'YYYY-MM-DD HH24:MI:SS')
                                              END AS event_source_end_date
                                            FROM
                                              (SELECT cust_ref,
                                                acc_num,
                                                sub_ref,
                                                prd_seq,
                                                prd_id,
                                                tariff_id,
                                                wb_ref,
                                                product_name,
                                                tariff_name,
                                                status,
                                                status_reason,
                                                effective_dtm,
                                                event_source,
                                                start_dtm,
                                                end_dtm,
                                                LEAD(event_source,1,NULL) OVER (PARTITION BY cust_ref ORDER BY cust_ref,prd_seq,effective_dtm,end_dtm) AS next_mac_by_cust
                                              FROM
                                                (SELECT ac.customer_ref AS cust_ref,
                                                  ac.account_num AS acc_num,
                                                  chp.subscription_ref   AS sub_ref,
                                                  cps.product_seq        AS prd_seq,
                                                  chp.product_id         AS prd_id,
                                                  cptd.tariff_id,
                                                  cpad.attribute_value AS wb_ref,
                                                  p.product_name,
                                                  t.tariff_name,
                                                  cps.product_status    AS status,
                                                  cps.status_reason_txt AS status_reason,
                                                  cps.effective_dtm,
                                                  ces.event_source,
                                                  ces.start_dtm,
                                                  end_dtm
                                                FROM geneva_admin.custhasproduct chp,
                                                  geneva_admin.product p,
                                                  geneva_admin.custproductstatus cps,
                                                  geneva_admin.custproductattrdetails cpad,
                                                  geneva_admin.account ac,
                                                  geneva_admin.accountattributes aa,
                                                  geneva_admin.custproducttariffdetails cptd,
                                                  geneva_admin.tariff t,
                                                  geneva_admin.custeventsource ces,
                                                  (SELECT TO_DATE('2099-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS') AS end_date
                                                  FROM dual ) a
                                                WHERE ac.account_num              = aa.account_num(+)
                                                AND ac.customer_ref               = chp.customer_ref(+)
                                                AND chp.product_id                = p.product_id(+)
                                                AND chp.customer_ref              = cps.customer_ref(+) 
                                                AND chp.product_seq               = cps.product_seq(+)
                                                AND chp.customer_ref              = cpad.customer_ref (+)
                                                AND chp.product_seq               = cpad.product_seq (+)
                                                AND cps.customer_ref              = cptd.customer_ref(+)
                                                AND cps.product_seq               = cptd.product_seq(+)
                                                AND cptd.tariff_id               = t.tariff_id(+)     
                                                AND chp.customer_ref              = ces.customer_ref (+)
                                                AND chp.product_seq               = ces.product_seq (+)
                                                AND ac.account_num = '%s' 
                                                AND chp.SUBSCRIPTION_REF = '%s'
                                                AND cps.product_status = '%s'))""" % (accountNumber, subscriptionRef, productStatus)

        logger.info(sqlCommand)
        response = queryNC(sqlCommand)
        logger.info("response is:    ")
        logger.info(response)
        if response[0] == 'Pass':
            return True, response[1]
        else:
            return False, None

    def getBillingTableEntries(self, params):
        tables = params[0]
        accounts = params[1]
        if len(params) == 3:
            writeFile = params[2]
        else:
            writeFile = False
        output = ''
        outputDict = {}
        for account in accounts:
            output = output + "account: " + account + '\n'
            for table in tables.keys():
                output = output + table + '\n'
                index = tables[table]['index']
                if index == 'customer_ref':
                    indexValue = customer_ref  # this cannot be the first table or we won't have customer_ref yet
                else:
                    indexValue = account
                query = 'select '
                fields = ''
                for column in tables[table]['fields']:
                    fields = fields + column + ','
                fields = fields[:-1]
                query = query + fields
                output = output + fields + '\n'
                query = query + " from geneva_admin." + table + " where " + index + "='" + indexValue + "'"
                if 'where' in tables[table]:
                    query = query + tables[table]['where']
                logger.console(query)
                response = queryNC(query)
                logger.console(response)
                if response[0] == 'Pass':
                    outputDict[table] = response[1]
                    if table == 'account':
                        customer_ref = response[1][0][0]
                    for entry in response[1]:
                        for item in entry:
                            output = output + str(item) + ','
                        output = output[:-1] + '\n'
        if writeFile == 'True' or writeFile == True:
            fo = open("nc_out_" + accounts[0] + "_" + str(int(time.time())) + ".csv", "w")
            fo.write(output)
            logger.info(output)
            fo.close()
        return outputDict


def filterAccountsByProductNameAndStatus(accounts, productName="EU Internet", status='OK', plan='', nextBillDate=''):
    nc_query = account_query % (productName, status, tuple(accounts))
    if plan != '':
        nc_query = nc_query + " AND cpad.attribute_value like '" + plan + "'"
    if nextBillDate != '':
        nc_query = nc_query + "AND ac.next_bill_dtm = DATE '" + nextBillDate + "'"

    nc_query = nc_query + ")) ORDER BY acc_num DESC"
    logger.info("query = "+nc_query)
    result = queryNC(nc_query)
    return result


def getSubproductsByAttributeId(attributeId, status, accountNum):
    # suggested attributeId=10. Status can be OK, PE, or ?
    subproducts = []
    attributeId = int(attributeId)
    keys = ['cust_ref', 'acc_num', 'sub_ref', 'prd_seq', 'prd_id', 'tariff_id', 'wb_ref', 'product_name', 'tariff_name', 'status', 'status_reason', 'effective_date', 'event_source']
    query = subproduct_id_query % (attributeId, status, accountNum)
    response = queryNC(query)
    if response[0] == 'Pass':
        for row in response[1]:
            sub = {}
            i = 0
            for key in keys:
                sub[key] = row[i]
                i = i + 1
            subproducts.append(sub)
        response[1] = subproducts
    return response


def getSubproductsByAttributeValue(name, status, accountNum):
    # Status can be OK, PE, or ?
    subproducts = []
    keys = ['cust_ref', 'acc_num', 'sub_ref', 'prd_seq', 'prd_id', 'tariff_id', 'wb_ref', 'product_name','subproduct_id', 'tariff_name', 'status', 'status_reason', 'effective_date', 'event_source']
    query = subproduct_name_query % (name, status, accountNum)
    response = queryNC(query)
    if response[0] == 'Pass':
        for row in response[1]:
            sub = {}
            i = 0
            for key in keys:
                sub[key] = row[i]
                i = i + 1
            subproducts.append(sub)
        response[1] = subproducts
    return response


def useSpbNcApi(apiMethod, *argv):
    funcName = sys._getframe().f_code.co_name
    spbApi = SPB_NC_API_Lib()
    if apiMethod == 'queryNcProductTable':
        result = spbApi.queryNcProductTable(argv[0], argv[1], argv[2])
    elif apiMethod == 'queryNcTariffTable':
        result = spbApi.queryNcTariffTable(argv[0],argv[1])
    elif apiMethod == 'getProductId':
        logger.info("inside")
        result = spbApi.getProductId(argv[0], argv[1])
    elif apiMethod == 'getBillingTableEntries':
        result = spbApi.getBillingTableEntries(argv)
    else:
        result = getattr(spbApi, apiMethod)(argv[0])
    return result


if __name__ == "__main__":
    spbApi = SPB_NC_API_Lib()
    # result = spbApi.getLedgerBalance(sys.argv[1])
    # print(str(result))
    NC_TABLES_BEFORE.update(NC_TABLES_AFTER)
    spbApi.getBillingTableEntries([NC_TABLES_BEFORE, ['5000044637','5000044647'],True])
    #response = getSubproductsByAttributeValue('SERVICE_CONTRACT','OK','5000011773')
    #print(str(response))
