#!/usr/bin/python3.6

import sys
import psycopg2
import json
import os
from credentials import *
from sql_libs import *
import time
from robot.api import logger


class CMS_PG_API_Lib:

    # At initialization generates information needed for security header
    def __init__(self, inputLog=False):
        # Initialize username and password used in requests
        self._cms_pg_name = "CMS"
        self._cms_pg_port = "5432"
        self._cms_pg_username = "cms_ro_user"

        #### Preprod Environment
        self._cms_pg_ip = "cmspreprod.ckv4gb50klga.us-west-2.rds.amazonaws.com"
        self._cms_pg_password = "cms_ro_user092019"

    def getCustomerAgreementInfo(self, contractId, customerId):
        logger.info("inside getCustomerAgreementInfo variables are")
        logger.info(contractId)
        logger.info(customerId)
        sqlCommand = """SELECT * FROM cms_schema_owner.customer_agreement_info where contract_id = '%s' AND customer_id = '%s' ORDER BY update_date DESC""" % (contractId, customerId)
        logger.info("############### line # 31 ################")
        state, output = queryCMS(sqlCommand)
        logger.info("############### line # 33 ################")
        return state, output

#def getSpbDbInstance():
#    return SPB_PG_API_Lib()


def useCmsPgApi(apiMethod, *argv):
    funcName = sys._getframe().f_code.co_name
    cmsPgApi = CMS_PG_API_Lib()
    if apiMethod == 'getCustomerAgreementInfo':
        logger.info("inside useCmsPgApi def")
        result = cmsPgApi.getCustomerAgreementInfo(argv[0], argv[1])
    else:
        result = (False, funcName + " Incorrect number of arguments for " + funcName)
    return result


if __name__ == "__main__":
    cmsPgApi = CMS_PG_API_Lib()
