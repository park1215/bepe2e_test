#################################################################
#
#  File name:  tng_resources.robot
#
#  Description: TNG Library to perform various operations related to queries/rollback/verification of TNG Orders, mikrotik controllers & Ruckus APs
#
#  Author: adingankar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
# In most keywords, assume caller has already made SSH connection
*** Settings ***
Resource   ../resource.robot
Library    OperatingSystem
Library    Process
Library   ./tng_db.py
Resource          tng_parameters.robot

*** Variables ***
@{ssids}
@{ssid_pwds}


*** Keywords ***
Lookup wdaOrderId given externalBepOrderId
    [Documentation]   For a given externalBepOrderId, retrieve wdaOrderId
    [Arguments]    ${BEP_ORDER_ID}
    ${status}    ${result}    lookupWdaOrderId    ${BEP_ORDER_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    [return]    ${result}

Validate pptpUser ip and status
    [Documentation]   For a given systemId, retrieve pptp_user and ip address
    [Arguments]    ${CNT_SYS_ID}
    ${status}    ${result}    queryPptpUser    ${CNT_SYS_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    Should Not Be Empty    ${result}    msg=DB Lookup Failed or returned no Entries
    Should Be True    "${result}[4]"=="Active"

Retrieve wdaOrder information
    [Documentation]   For a given orderid, retrieve all order related information
    [Arguments]    ${ORDER_ID}
    ${status}    ${result}    queryWdaOrderStatus    ${ORDER_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    Should Not Be Empty    ${result}    msg=DB Lookup Failed or returned no Entries
    [return]    ${result}

Retrieve ruckusAp configInfo
    [Documentation]   For a given configId, retrieve all applicable WLans
    [Arguments]    ${CONFIG_ID}
    ${status}    ${result}    queryRuckusApWlanConfig    ${CONFIG_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    Should Not Be Empty    ${result}    msg=DB Lookup Failed or returned no Entries
    [return]    ${result}

Retrieve location Info
    [Documentation]   For a given orderId, retrieve Location Info
    [Arguments]    ${LOCATION_ID}
    ${status}    ${result}    queryLocationInfo  ${LOCATION_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    Should Not Be Empty    ${result}    msg=DB Lookup Failed or returned no Entries
    

Extract locationId from wdaOrder Info
    [Documentation]   From Order Info retrieved from DB, extract locationId
    [Arguments]    ${ORDER_INFO}
    ${location_id} =  Get From List    ${result}  2
    [return]    ${location_id}    

Extract configId from wdaOrder Info
    [Documentation]   From Order Info retrieved from DB, extract configId
    [Arguments]    ${ORDER_INFO}
    ${location_id} =  Get From List    ${result}  2
    [return]    ${config_id}

Retrieve wlanInfo from wlanConfig
    [Documentation]  For a particular Ruckus AP Config, pull out the private/public SSIDs
    [Arguments]    ${CONFIG_INFO}
    :FOR    ${item}    IN    @{CONFIG_INFO}
    \    Append To List    ${ssids}  ${item}[13] 
    \    Append To List    ${ssid_pwds}  ${item}[16]
    [return]    ${ssids}  ${ssid_pwds}

Validate wifiOrder status
    [Documentation]   For a given orderid, validate order status & external acct reference
    [Arguments]    ${ORDER_INFO}  ${EXTERNAL_REFERENCE_ID}
    Should Be True    "${ORDER_INFO}[18]"=="Approved"
    Should Be True    "${result}[5]"==${EXTERNAL_REFERENCE_ID}

Validate wifiOrderItems status
    [Documentation]   For a given orderid, validate that the Mikrotik & AP/s are in appropriate state
    [Arguments]    ${ORDER_ID}  ${ORDER_ITEM_STATE}
    ${status}    ${result}    queryWdaOrderItems    ${ORDER_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    :FOR    ${item}    IN    @{result}
    \    Log To Console    ${item}
    \     Should Be True    "${item}[7]"==${ORDER_ITEM_STATE}  

Validate deploymentIps status
    [Documentation]   For a given orderId, retrieve locationId and validate deploymentIp status
    [Arguments]    ${ORDER_ID}    ${DEPLOYMENT_IP_STATE}
    ${status}    ${result}    queryDeploymentIps    ${ORDER_ID}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    :FOR    ${item}    IN    @{result}
    \    Log To Console    ${item}
    \     Should Be True    "${item}[2]"==${DEPLOYMENT_IP_STATE}
    [return]    ${status}

Get mikrotik sysId
    [Documentation]   Given a list of one or more  MAC Address, retrieve SysId/s
    [Arguments]    @{MAC_ADDRESS_LIST}
    ${status}    ${result}    querySysId  ${MAC_ADDRESS_LIST}
    Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
    @{sys_id_list}    Create List 
    :FOR    ${item}    IN    @{result}
    \    Log    ${item}
    \    ${sys_id}    Get From List    ${item}  0
    \    Append To List    ${sys_id_list}    ${sys_id}
    [return]    ${sys_id_list}

Get device orderItem State
   [Documentation]   Given sysid and deviceType, retrieve install status
   [Arguments]    ${SYS_ID}
   ${status}    ${result}    queryWdaOrderItemStatus    ${SYS_ID}    
   Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error
   Should Be True    "${result}[18]"==

Scramble SysId To Reset Device
   [Documentation]   Given sysid concatenate Test Identifier to existing SysId so physical device can be re-associated to other Orders
   [Arguments]    ${SYS_ID}    ${TEST_IDENTIFIER}
   ${status}    ${result}    scrambleSysId    ${SYS_ID}    ${TEST_IDENTIFIER}
   Should Be True    ${status}    msg=DB Lookup Failed or Encountered Unexpected Error

#Verify device configuration transition
#   [Documentation]   Given a wifi device (mikrotik or AP)  sysId for a particular Order, return when state transitions from A to B Ex. pending to discovering, discovering to configuring, configuring to installed
#   [Arguments]    ${SYS_ID}    ${STATE_A}    {STATE_B}
#   Wait Until Keyword Succeeds    ${DB_POLL_RETRY}    ${DB_POLL_INTERVAL}    Get device orderItem State    ${SYS_ID}
#   ${status}    ${result}    verifyOrderitemStatusTransition    ${SYS_ID} 
    
