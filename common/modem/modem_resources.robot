#******************************************************************
#
#  File name: modem_resources.robot
#
#  Description: Keywords for UTs
#
#  Author:  swile
#
#  Copyright (c) ViaSat, 2018
#
#******************************************************************
*** Settings ***
Documentation     Perform commands and retrieve status on user terminals

Library           OperatingSystem
Library           Process
Library           String
#Library           Collections
Resource          modem_parameters.robot
Resource          ../ssh_library.robot
Resource         ../resource.robot
Library         ./modem.py

*** Keywords ***
Connect To Modem
    [Documentation]     Opens SSH connection to modem.
    [Arguments]         ${modem_ip}
    Open SSH Connection And Login    ${modem_ip}  "modem"  ${MODEM_USERNAME}   ${MODEM_PASSWORD}
    
Disconnect Modem SSH
    [Documentation]     Closes modem's ssh connection.
    Close SSH Connection

Get Utstat
    [Documentation]     Using existing SSH connection, do utstat -${modifier} and return response. Assume already switched to this SSH connection.
    [Arguments]         ${modifier}=${EMPTY}
    ${response}         Execute SSH Command And Return Stdout   utstat ${modifier}
    [return]   ${response}

Prep Modem To Come Online
    [Documentation]    For given Modem MAC, clear out beamID association for Pre-Prod
    [Arguments]    ${modem_mac_colon}
    ${result}    Clear Modem Logical BeamId    ${modem_mac_colon}
    Should Be True    ${result}
    
De-provision The Modem
    ${ntd_id}    Fetch NTD_ID From Modem MAC    ${modem_mac_colon}
    Log To Console   Fetched ntd id
    Set Suite Variable   ${ntd_id}
    ${result_list}    Disconnect Customer Account    ${modem_mac_colon}    ${user}
    Log To Console  returned from disconnect customer account
    ${execution_status} =  Get From List    ${result_list}    0
    Log To Console  result of disconnect is ${execution_status}
    Should Be True    ${execution_status}   ${result_list}[1]
    ${internal_acct_reference} =  Get From List    ${result_list}    1
    Set Suite Variable   ${internal_acct_reference}
    Modem MAC CleanUp In ResVNO    ${modem_mac_colon}    ${ntd_id}   
    
Verify Modem And PTRIA Status Is Active
    [Documentation]    After provisioning, verify that modem and ptria are active. Use service agreement id AKA ntd_id.
    ${response}   Get Modem And PTRIA Status    ${ntd_id}
    Run Keyword And Continue On Failure  Should Be Equal   ${response['MODEM']}   ACTIVE
    Should Be Equal   ${response['TRIA']}   ACTIVE
    
Verify Modem And PTRIA Status Is Inactive
    [Documentation]    After provisioning, verify that modem and ptria are active. Use service agreement id AKA ntd_id.
    ${response}   Get Modem And PTRIA Status    ${ntd_id}
    Run Keyword And Continue On Failure  Should Be Equal   ${response['MODEM']}   INACTIVE   modem status=${response['MODEM']} and PTRIA status=${response['TRIA']}
    Should Be Equal   ${response['TRIA']}   INACTIVE    modem status=${response['MODEM']} and PTRIA status=${response['TRIA']}
    
Verify Modem Is Online
    [Documentation]   Login to modem and verify that it is Online
    Log To Console  ${MODEM_USERNAME} ${MODEM_PASSWORD} ${modem_ip}
    #Wait For Fresh Modem Reboot    ${modem_ip} 
    #Wait Until Keyword Succeeds  5m   10s  Open SSH Connection And Login     ${modem_ip}   ${modem_ip}  ${MODEM_USERNAME}   ${MODEM_PASSWORD}
    Wait Until Keyword Succeeds    5m   10s   Wait For Modem Online
    
    
Verify Modem Reboot on Login
    [Documentation]     There are times when CMT-API reboot is received late causing us to login to modem before reboot command is issued. This method checks uptime is on order of mins
    [Arguments]         ${modem_ip}
    Connect To Modem    ${modem_ip}
    ${response}    Execute SSH Command And Return Stdout   ${FRESH_REBOOT_CMD}    
    Log To Console  ${response}
    Disconnect Modem SSH
    Should Be Equal    ${response}  ${FRESH_REBOOT_STR}

Wait For Fresh Modem Reboot
    [Documentation]     There are times when CMT-API reboot is received late causing us to login to modem before reboot command is issued. This method waits till modem reboot is fresh
    [Arguments]         ${modem_ip}
    Wait Until Keyword Succeeds    ${FRESH_REBOOT_LOGIN_RETRY}    ${FRESH_REBOOT_LOGIN_INTERVAL}    Verify Modem Reboot on Login    ${modem_ip}

Verify Port Configuration
    [Documentation]     Check modem port configuration and verify bridge or router mode, depending on Argument. Assume already switched to SSH connection.
    [Arguments]         ${mode}
    ${response}         Get Utstat  ${PORT_CONFIGURATION}
    ${match}            Get Lines Containing String   ${response}   ${mode} mode
    ${line_length}      Get Length   ${match}
    ${status}   ${message}         Should Not Be Equal As Numbers   ${line_length}   0
    [return]     ${status}
    
Retrieve SDFID List
    [Documentation]      Using utstat -W get SDFIDs associated with modem. Assume already switched to SSH connection.
    ${response}         Get Utstat  ${SERVICE_FLOW_LISTS}
    ${service_flows}     getSDFIDList   ${response}
    [return]        ${service_flows}

Verify CSP Status Is True On Modem
    [Documentation]    Get CSP STATE from utstat and verify csp is True
    ${response}    Get Utstat  ${CSP_STATE_TRUE} 
    Should Contain    ${response}    ${UT_CSP_STATE_TRUE}    Verify CSP Status Is True On Modem: CSP state is ${response}

Wait For Verify CSP Status Is True On Modem
    [Documentation]    Wait For Verify CSP Status Is True On Modem
    Wait Until Keyword Succeeds    ${CSP_RETRY}    ${CSP_INTERVAL}    Verify CSP Status Is True On Modem

Verify LED & UMAC Status Is Online On Modem
    [Documentation]    Get LED & UMAC STATE from utstat and verify both are Online
    ${led_state}    Get Utstat  ${MODEM_LED_ONLINE}
    ${umac_state}    Get Utstat  ${MODEM_UMAC_ONLINE}
    Should Contain    ${led_state}    ${MODEM_ONLINE_STATE}    Verify LED & UMAC Status Is Online On Modem: led state is ${led_state} and umac state is ${umac_state}
    Should Contain    ${umac_state}    ${MODEM_ONLINE_STATE}   Verify LED & UMAC Status Is Online On Modem: umac state is ${umac_state} and led state is ${led_state}
    [return]    ${led_state}  ${umac_state}  
 
Wait For Modem Online
    [Documentation]    Wait For Modem ledState & uMacState to be Online
    ${status}   ${message}  Wait Until Keyword Succeeds  2m   20s  Open SSH Connection And Login     ${modem_ip}   ${modem_ip}  ${MODEM_USERNAME}   ${MODEM_PASSWORD}
    Verify LED & UMAC Status Is Online On Modem
    
Get Modem Type
    [Documentation]    Determine if modem is DATA, SPOCK, or UT2
    ${modem_version}     Get Utstat   ${MODEM_SW_VERSION}
    ${match}   Get Regexp Matches  ${modem_version}   (\[A-Z0-9\]\*)_   1
    [return]   ${match[0]}
    
Verify Modem Is In Bridge Mode
    [Documentation]    Verify Modem Is In Bridge Mode
    ${port}     Get Utstat   ${PORT_CONFIGURATION}
    Should Contain    ${port}    Router mode is disabled
    
Read Service Flow Ids
    [Documentation]    service flow id test case, allows it to be run repeatedly until pass
    [Arguments]    ${service_plan_name}=${service_plan}     ${suspend}=False
    &{modem_sdfids}=   Create Dictionary
    ${status}   ${message}  Wait Until Keyword Succeeds  2m   20s  Open SSH Connection And Login     ${modem_ip}   ${modem_ip}  ${MODEM_USERNAME}   ${MODEM_PASSWORD}
    Compare Service Flow Ids    ${service_plan_name}    ${suspend} 

Compare Service Flow Ids
    [Documentation]  do the actual compare once modem login is possible
    [Arguments]    ${service_plan_name}=${service_plan}    ${suspend}=False
    ${modem_sdfids}     Retrieve SDFID List
    ${modem_type}   Get Modem Type
    Log    ${modem_sdfids} ${service_plan_name} ${modem_type} ${suspend}  
    ${response}     compareSDFIDs   ${modem_sdfids}   ${service_plan_name}   ${modem_type}    ${suspend}  
    Should Be Equal As Strings   ${response}[0]   True   Compare Service Flow Ids:${response}[1]

Get Current Realm On Modem
    [Documentation]    returns what realm modem is on
    [Arguments]    ${modem_mac}
    ${status}    ${realm}    getCurrentRealm    ${modem_mac}
    Should Be True    ${status}
    Log    ${realm}
    [return]  ${realm}

Verify Realm On Modem
    [Documentation]    returns what realm modem is on
    [Arguments]    ${modem_mac}   ${expected_realm}
    ${realm}    Get Current Realm On Modem    ${modem_mac}
    Should Be Equal As Strings    ${realm}    ${expected_realm}

Verify And Deprovision Modem
    [Documentation]    verifies if modem is deprovisioned if, not de-provisions it
    [Arguments]    ${modem_mac}
    Log    Testing in progress
    ${status}    ${state}  ${ntd_product_instance_id}  ${lat}  ${long}    getDeviceState    ${modem_mac}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][MODEM][SDP_JWT_NAME]
    Should Be True    ${status}
    Run Keyword Unless   '${state}' == 'False'    Request PI Life Cycle State Change To Deactivated    ${ntd_product_instance_id}
    Verify SPR Subscriber Information For Modem Disconnection    ${modem_mac}

Verify And Change Realm On Modem
    [Documentation]    returns what realm modem is on
    [Arguments]    ${modem_mac}   ${new_realm}
    ${realm}    Get Current Realm On Modem   ${modem_mac}
    ${different_realm}    Run Keyword And Return Status    Should Not Be Equal As Strings    ${realm}    ${new_realm}
    ${new_received_realm}    Run Keyword If    ${different_realm}    changeRealmOnModem   ${modem_mac}     ${new_realm}
    ${updated_realm}    Get Current Realm On Modem    ${modem_mac}
    Should Be Equal As Strings    ${updated_realm}    ${new_realm}

Modem Setup
    [Documentation]    tis setup keyword puts modem in de-prov and changes realm
    [Arguments]    ${modem_mac}
    Verify And Deprovision Modem    ${modem_mac}
    Verify And Change Realm On Modem    ${modem_mac}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][MODEM][REALM]