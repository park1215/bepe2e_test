import mysql.connector
from mysql.connector import Error
import os
import sys
import time
import logging
import subprocess
from robot.api import logger

ceBetaDB='10.59.8.43'
dbConfig='~/tng_db.cnf'
orderDB='nnurap2'
bepOrderDB='bep'
cureDB='cure'
configId='5'
orderId='841'
configSysDB='paynet'
pptpDB='nnurap2'
sysId='301715'
locationId='545'
bepOrderId='BEPE2E_Order_Id_1552687257'
customerId='BEPE2E_Customer_Id_1552687494'
#macList = ["64:D1:54:54:B6:3B","1C:B9:C4:37:62:D0"]
#macList = ['64:D1:54:57:97:13', '1C:B9:C4:37:6C:10']
#macList = ['64:D1:54:57:97:13']
#dbUser='azeem.dingankar'
dbUser='azeem.dingankar'
#dbUser='jeff.krier'
dbPwd='bepe2e'

#Helper Functions For DB Query Retrieval
def executeMysqlQuery(connection, query):
    cursor = connection.cursor()
    cursor.execute(query)
    records = cursor.fetchall()
    affectedRecords = cursor.rowcount
    print("Affected Records -->: ", affectedRecords)
    cursor.close()
    return records

def executeMysqlUpdate(connection, query):
    cursor = connection.cursor()
    cursor.execute(query)
    connection.commit()
    affectedRecords = cursor.rowcount
    print("Affected Records -->: ", affectedRecords)
    cursor.close()
    return affectedRecords

def connectMySqlDB(tngDB):
    mySQLconnection = mysql.connector.connect(host=ceBetaDB, database=tngDB, user=dbUser, password=dbPwd, use_pure=True)    
    return mySQLconnection

def disconnectMySqlDB(dbConnection):
    if(dbConnection.is_connected()):
        dbConnection.close()
        print("MySQL connection closed for DB - ")

#Query pptp_user creds entry from pptp_user table in nnurap2 DB to validate successful pptp user and creds setup upon upload
def queryPptpUser(sysId):
    funcName = sys._getframe().f_code.co_name
    try:
        dbConnection = connectMySqlDB(pptpDB)
        sysConfigQuery = 'select * from pptp_user where username=' + sysId
        print(sysConfigQuery)
        queryExecution = executeMysqlQuery(dbConnection, sysConfigQuery)
        print(queryExecution)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying pptp_user= "+str(e)+" index for sysId="+sysId)
        return False, funcName+":error querying pptp_user for specific sysId="+sysId+", error = "+str(e) 

    finally:
        #closing database connection.
        disconnectMySqlDB(dbConnection)
    

def querySysId(deviceMacList):
    logger.console("Robot passed array is -->"+str(deviceMacList))
    funcName = sys._getframe().f_code.co_name
    try:
        dbConnection = connectMySqlDB(configSysDB)
        #sysConfigQuery = 'select * from configSys where configid=314 and value in ' + str(tuple(deviceMacList))
        t = tuple(deviceMacList)
        sysConfigQuery = "select * from configSys where configid=314 and value in {}".format(t)
        sysConfigQuery = sysConfigQuery.replace(',)', ')')
        logger.console("Query is -->"+sysConfigQuery)
        #print(sysConfigQuery)
        queryExecution = executeMysqlQuery(dbConnection,sysConfigQuery)
        print(queryExecution)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying pptp_user= "+str(e)+" index for sysId="+sysId)
        return False, funcName+":error querying configSys for specific deviceMacList="+deviceMacList+", error = "+str(e)

    finally:
        #closing database connection.
        disconnectMySqlDB(dbConnection)


def queryDeploymentIps(orderId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
#      format_strings = ','.join(['%s'] * len(deviceMacList))
#      sysConfigQuery = "select * from configSys where sysid in (%s) % format_strings"
      #sysConfigQuery = 'select * from configSys where sysid in ' + str(tuple(deviceMacList))
        sysConfigQuery = 'select *, inet_ntoa(ip) as ip_address from deployment_ips where locationid in (select location_id from nnurap2.wda_order where id=' + orderId + ')'
        logger.console(sysConfigQuery)
        queryExecution = executeMysqlQuery(dbConnection,sysConfigQuery)
        for row in queryExecution:
            print(row)

        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying deploymentIps= "+str(e)+" index for locationId="+orderId)
        return False, funcName+":error querying DeploymentIps for specific locationId="+orderId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

#Query WDA_Order table in nnurap2 DB for Order Status and Location Id Mapping post Portal Order Entry
def lookupWdaOrderId(externalBepOrderId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(bepOrderDB)
        bepWdaOrderQuery = "select wda_order_id from bep_wda_order where bep_order_id='" + externalBepOrderId +"'"
        logger.console(bepWdaOrderQuery)
        queryExecution = executeMysqlQuery(dbConnection, bepWdaOrderQuery)
        #print("Total number of rows in wda_orders is - ", queryExecution.rowcount)
        print ("Printing each row's column values i.e.  wda orders")
        row  = queryExecution[0][0]
        print(row)
        return True, row

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying bep_wda_order= "+str(e)+" index for ="+externalBepOrderId)
        return False, funcName+":error querying for specific bep_order_Id="+externalBepOrderId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

#Query WDA_location in nnurap2 DB for Address Info
def queryLocationInfo(locationId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
        locationInfoQuery = "select * from wda_location where location_id=" + locationId
        logger.consolelocationInfoQuery()
        queryExecution = executeMysqlQuery(dbConnection, locationInfoQuery)
        #print("Total number of rows in wda_orders is - ", queryExecution.rowcount)
        print ("Printing each row's column values i.e.  Location Info")
        row  = queryExecution[0]
        print(row)
        return True, row

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying location_id= "+str(e)+" index for ="+locationId)
        return False, funcName+":error querying for specific location_Id="+locationId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

#Query WDA_Order table in nnurap2 DB for Order Status and Location Id Mapping post Portal Order Entry
def queryRuckusApWlanConfig(configId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(cureDB)
        ruckusApWlanConfigQuery = "select * from ruckus_ap_wlan_config where configuration_id='" + configId +"'"
        queryExecution = executeMysqlQuery(dbConnection, ruckusApWlanConfigQuery)
        #print("Total number of rows in wda_orders is - ", queryExecution.rowcount)
        #row  = queryExecution[0]
        print(queryExecution)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying configuration_id= "+str(e)+" index for ="+configId)
        return False, funcName+":error querying for specific configuration_id="+configId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)


#Given wdaOrderId, lookup LocationId
def lookupLocationId(externalBepOrderId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(bepOrderDB)
        bepWdaOrderQuery = "select wda_order_id from bep_wda_order where bep_order_id='" + externalBepOrderId +"'"
        logger.console(bepWdaOrderQuery)
        queryExecution = executeMysqlQuery(dbConnection, bepWdaOrderQuery)
        #print("Total number of rows in wda_orders is - ", queryExecution.rowcount)
        print ("Printing each row's column values i.e.  wda orders")
        row  = queryExecution[0][0]
        print(row)
        return True, row

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying bep_wda_order= "+str(e)+" index for ="+externalBepOrderId)
        return False, funcName+":error querying for specific bep_order_Id="+externalBepOrderId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

#Given customerId (used during order creation, retrieve lincenceeId from BEP DB)
def lookupLicenseeId(bepCustomerId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(bepOrderDB)
        beplicenceeQuery = "select customer_id from customer_licensee where customerId='" + bepCustomerId +"'"
        queryExecution = executeMysqlQuery(dbConnection, beplicenceeQuery)
        #print("Total number of rows in wda_orders is - ", queryExecution.rowcount)
        print ("Printing each row's column values i.e.  wda orders")
        #print(queryExecution)
        row  = queryExecution[0][0]
        print(row)
        return True, row

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying bep_customer_id= "+str(e)+" index for ="+bepCustomerId)
        return False, funcName+":error querying for specific customerId="+bepCustomerId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

#Query WDA_Order table in nnurap2 DB for Order Status and Location Id Mapping post Portal Order Entry
def queryWdaOrderStatus(orderId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
        wdaOrderQuery = "select * from wda_order where id=" + orderId
        queryExecution = executeMysqlQuery(dbConnection, wdaOrderQuery)
        #print("Total number of rows in wda_orders is - ", queryExecution.rowcount)
        print ("Printing each row's column values i.e.  wda orders")
        print(queryExecution)
        row  = queryExecution[0]
        print(row)

        return True, row

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying wda_order= "+str(e)+" index for orderId="+orderId)
        return False, funcName+":error querying WdaOrderStatus for specific orderId="+orderId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

#Query WDA_Order table in nnurap2 DB for successful entries relatig to mikrotiks, APs, Customer Portal & Virtual Bridge
def queryWdaOrderItems(orderId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
        wdaOrderQuery = "select * from wda_order_item where device_type_id in (2,3) and order_id=" + orderId
        queryExecution = executeMysqlQuery(dbConnection, wdaOrderQuery) 
        print ("Printing each row's column values i.e.  wda orders")
        print(queryExecution)
#        for row in queryExecution:
#           print(row)
        return True, queryExecution
   
    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying wda_order_item= "+str(e)+" index for orderId="+orderId)
        return False, funcName+":error querying WdaOrderItems for specific orderId="+orderId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

def verifyOrderitemStatusTransition(sysId, stateA, stateB):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
        wdaOrderQuery = "select status from wda_order_item where sysid=" + sysId
        queryExecution = executeMysqlQuery(dbConnection, wdaOrderQuery)
        print(queryExecution)
#        for row in queryExecution:
#           print(row)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error querying wda_order_item= "+str(e)+" index for sysId="+sysId)
        return False, funcName+":error querying WdaOrderItems for specific sysId="+sysId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

def deletePptpUser(sysId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
        pptpuserUpdate = "delete from pptp_user where username ="+sysId
        pptpuserUpdate = pptpuserUpdate.replace(',)', ')')
        queryExecution = executeMysqlUpdate(dbConnection,pptpuserUpdate)
        print ("Printing each row's column values i.e.  wda orders")
#      for row in queryExecution:
#         print(row)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error deleting  pptp_user= "+str(e)+" index for sysId="+sysId)
        return False, funcName+":error deleting pptpUser for specific Controller+AP MACs="+sysId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

def updateWdaOrderItems(orderId):
    funcName = sys._getframe().f_code.co_name

    try:
        dbConnection = connectMySqlDB(orderDB)
        wdaOrderItemsUpdate = "update wda_order_item set `status` = 'error' where `status` in  ('pending', 'discovering', 'configuring') and order_id =" + orderId
        queryExecution = executeMysqlUpdate(dbConnection,wdaOrderItemsUpdate)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error deleting  pptp_user= "+str(e)+" index for sysId="+sysId)
        return False, funcName+":error updating wda_order_items to error  for specific OrderId="+orderId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

def updateDeploymentIps(locationId):
    funcName = sys._getframe().f_code.co_name
    print("Location ID is -->", locationId)
    try:
        dbConnection = connectMySqlDB(orderDB)
        deploymentIpsUpdate = "update deployment_ips set `status` = 'available', sysid = 0, locationid = null where locationid =" + locationId
        print(deploymentIpsUpdate)
        queryExecution = executeMysqlUpdate(dbConnection,deploymentIpsUpdate)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error updating deploymentIps = "+str(e)+" index for locationId="+locationId)
        return False, funcName+":error updating deploymentIps to available for specific locationId="+locationId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

def scrambleSysId(sysId, testIdentifier):
    funcName = sys._getframe().f_code.co_name
    print("SysID is -->", sysId)
    try:
        dbConnection = connectMySqlDB(configSysDB)
        configSysUpdate = "update configSys set value = concat("+testIdentifier+",value) where configid in (314, 251) and sysid =" + sysId
        print(configSysUpdate)
        queryExecution = executeMysqlUpdate(dbConnection,configSysUpdate)
        return True, queryExecution

    except Error as e:
        print ("Error while connecting to MySQL", e)
        logger.error("error updating sysId values = "+str(e))
        return False, funcName+":error updating sysId values to scrambled values for specific sysId="+sysId+", error = "+str(e)

    finally:
       #closing database connection.
        disconnectMySqlDB(dbConnection)

def run():
    pass
#    runOrderQuery=queryWdaOrderItems(orderId)
#    runSysConfigQuery=querySysId(macList)
#    runDeletePptpUser=deletePptpUser(sysId)
#     runUpdateWdaOrderItems=updateWdaOrderItems('758')
#     runUpdateDeploymentIps=updateDeploymentIps(locationId)
#    runPptpUserQuery=queryPptpUser(sysId)
#    runwdaOrderStatusQuery=queryWdaOrderStatus(orderId)
    runqueryRuckusApWlanConfig=queryRuckusApWlanConfig(configId)
#    runDeploymentIpsQuery=queryDeploymentIps(orderId)
#    runBepOrderMapping=lookupWdaOrderId(bepOrderId)
#    runLicenceeIdLookup=lookupLicenseeId(customerId)
#    runstateTransition=verifyOrderitemStatusTransition(sysId,"pending","discovering")
#     runScrambleSysId=scrambleSysId('00302236','CURE BEPE2E_CW_032719 Reset 1_')

run()
