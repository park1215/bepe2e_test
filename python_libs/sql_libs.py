import psycopg2
from credentials import *
import cx_Oracle
import os
from robot.api import logger

RB_QA_HOST = "rbm.api.dev.rbm.viasat.com"
RB_QA_PORT = '1522'
RB_QA_SERVICE_NAME = 'vsrba3'
RB_QA_DSN="""(DESCRIPTION=
(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCPS)(HOST=rbm.api.dev.rbm.viasat.com)(PORT=1522)))
(CONNECT_DATA=(SERVICE_NAME=vsrba3)))"""

def querySPB(sqlCommand,params=None):
    spb_pg_name = "SPB"
    spb_pg_port = "5432"
    spb_pg_username = SPG_PG_USERNAME
    spb_pg_ip = "spbpreprod.cknuqmynawk0.us-west-2.rds.amazonaws.com"
    spb_pg_password = SPB_PG_PASSWORD  
    conn = None
    try:
        conn = psycopg2.connect(host=spb_pg_ip, database=spb_pg_name, user=spb_pg_username, password=spb_pg_password, port=spb_pg_port)
        cur = conn.cursor()
        if params is not None:
            cur.execute(sqlCommand, (params['data'],params['created_before'],params['created_after']))
        else:
            cur.execute(sqlCommand,)
        output = cur.fetchall()
        cur.close()
    except Exception as e:
        logger.error("error in querySPB = "+str(e))
    finally:
        if conn is not None:
            conn.close()
    return output

def queryCMS(sqlCommand,params=None):
    logger.info("############### line # 38 ################")
    output = None
    cms_pg_name = "CMS"
    cms_pg_port = "5432"
    cms_pg_username = "cms_ro_user"
    cms_pg_ip = "cmspreprod.ckv4gb50klga.us-west-2.rds.amazonaws.com"
    cms_pg_password = "cms_ro_user092019"
    conn = None
    try:
        logger.info("############### line # 46 ################")
        conn = psycopg2.connect(host=cms_pg_ip, database=cms_pg_name, user=cms_pg_username, password=cms_pg_password, port=cms_pg_port)
        cur = conn.cursor()
        if params is not None:
            cur.execute(sqlCommand, (params['data'],params['created_before'],params['created_after']))
        else:
            logger.info("############### line # 52 ################")
            cur.execute(sqlCommand,)
            logger.info("############### line # 54 ################")
        output = cur.fetchall()
        logger.info("############### line # 56 ################")
        cur.close()
        conn.close()
        logger.info("output is:")
        logger.info(output)
        return True, output[0]
    except Exception as e:
        logger.error("error in queryCMS = "+str(e))
        return  False, output
    finally:
        if conn is not None:
            conn.close()


def queryNC(sqlCommand):
    os.environ['TNS_ADMIN']='/etc/oracle/rb_qa_tns_admin'
    result = 'Fail'
    output = 0
    conn = None
    try:
        conn = cx_Oracle.connect(RB_QA_USER,RB_QA_PASSWORD,RB_QA_DSN,encoding="UTF-8")
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()            
        curs.close()
        result = 'Pass'
    except Exception as e:
        print("failure = "+str(e))
        output = str(e)
    finally:
        if conn is not None:
            conn.close()
    return [result,output]

def queryNCWithParams(sqlCommand,data,append=''):
    data = tuple(data)
    sqlCommand = sqlCommand % (data)
    sqlCommand = sqlCommand + append
    os.environ['TNS_ADMIN']='/etc/oracle/rb_qa_tns_admin'
    result = 'Fail'
    output = 0
    conn = None
    try:
        conn = cx_Oracle.connect(RB_QA_USER,RB_QA_PASSWORD,RB_QA_DSN,encoding="UTF-8")
        curs = conn.cursor()
        curs.execute(sqlCommand)
        output = curs.fetchall()            
        curs.close()
        result = 'Pass'
    except Exception as e:
        print("failure = "+str(e))
    finally:
        if conn is not None:
            conn.close()
    return [result,output]

