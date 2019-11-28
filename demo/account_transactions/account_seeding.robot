################################################################
#
#  File name: account_seeding.robot
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
*** Settings ***

Resource    ../../common/resource.robot
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Comments ***
Usage : robot --console VERBOSE account_seeding.robot

#  DESCRIPTION
#  Test suite to Seed Active Accounts to Suspend at a later time and Suspended Accounts To Resume at a later date

*** Variables ***
${account_count}    2

*** Test Cases ***
Seed Active Accounts
    [Documentation]    Seed Active Accounts to Suspend at a later time
    [Tags]    seed    active
    :FOR    ${INDEX}    IN RANGE    1   ${account_count}+1
    \   Log To Console  Iteration ${INDEX} Started
    \   ${fake_modem_mac}    Run Keyword And Continue On Failure    generateRandomMacAddress
    \   Set Suite Variable    ${modem_mac_colon}    ${fake_modem_mac}
    \   Run Keyword And Continue On Failure    Set Modem Type Based On Index    ${INDEX}
    \   ${service_plan}    Run Keyword And Continue On Failure    Select Random Service Plan From Config
    \   Set Suite Variable    ${service_plan}
    \   ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}    ${ntd_id}    ${lat}    ${long}    Run Keyword And Continue On Failure    Add New Business Account
    \   Set Suite Variable    ${ntd_id}
    \   Clear Modem Logical BeamId    ${ntd_id}    ${lat}    ${long}
    \   Associate New Account With Modem    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}
    \   Run Keyword And Continue On Failure    Retrieve SDP Device Status     ${fake_modem_mac}
    \   Run Keyword And Continue On Failure    Verify SDP Service Status Is Active
    \   Run Keyword And Continue On Failure    Display SPR Subscriber Information Items     ${fake_modem_mac}
    \   Run Keyword And Continue On Failure    Display Openet Information Items
    \   Run Keyword And Continue On Failure    Verify Product Status Is OK
    \   Log    ************* Iteration ${INDEX} ********************   WARN
    \   Log    Modem Mac: ${modem_mac_colon}    WARN
    \   Log    Modem Type: ${modem_type}    WARN
    \   Log    Service Plan: ${service_plan}    WARN
    \   Log To Console  Iteration ${INDEX} Complete



Seed Suspend Accounts
    [Documentation]    Seed Suspend Accounts to resume at a later time
    [Tags]    seed    suspend
    :FOR    ${INDEX}    IN RANGE    1   ${account_count}+1
    \   Log To Console  Iteration ${INDEX} Started
    \   ${fake_modem_mac}    Run Keyword And Continue On Failure    generateRandomMacAddress
    \   Set Suite Variable    ${modem_mac_colon}    ${fake_modem_mac}
    \   Run Keyword And Continue On Failure    Set Modem Type Based On Index    ${INDEX}
    \   ${service_plan}    Run Keyword And Continue On Failure    Select Random Service Plan From Config
    \   Set Suite Variable    ${service_plan}
#    \   ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}    Run Keyword And Continue On Failure    Add New Business Account
    \   ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}    ${ntd_id}    ${lat}    ${long}    Run Keyword And Continue On Failure    Add New Business Account
    \   Set Suite Variable    ${ntd_id}
    \   Clear Modem Logical BeamId    ${ntd_id}    ${lat}    ${long}
    \   Run Keyword And Continue On Failure    Associate New Account With Modem    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref} 
    \   Run Keyword And Continue On Failure    Retrieve SDP Device Status     ${fake_modem_mac}
    \   Run Keyword And Continue On Failure    Verify SDP Service Status Is Active
    \   Run Keyword And Continue On Failure    Display SPR Subscriber Information Items     ${fake_modem_mac}
    \   Run Keyword And Continue On Failure    Display Openet Information Items
    \   Run Keyword And Continue On Failure    Verify Product Status Is OK
    \   Run Keyword And Continue On Failure    Suspend Existing Account    ${order_ref}    ${order_requestor}    ${order_sold_by}    ${system_id}
    \   Run Keyword And Continue On Failure    Verify Openet Information For Modem Disconnection
    \   Run Keyword And Continue On Failure    Verify SDP Service Status For Suspended Account
    \   Run Keyword And Continue On Failure    Verify SPR Subscriber Information For Suspend
    \   Run Keyword And Continue On Failure    Verify Product Status Is SU    
    \   Log    ************* Iteration ${INDEX} ********************   WARN
    \   Log    Modem Mac: ${modem_mac_colon}    WARN
    \   Log    Modem Type: ${modem_type}    WARN
    \   Log    Service Plan: ${service_plan}    WARN
    \   Log To Console  Iteration ${INDEX} Complete 
    
*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    #${modem_ip}   Get From Dictionary   ${MODEM_IP_MAPPINGS}   ${modem_mac_colon}
    #Set Suite Variable   ${modem_ip}
    Set Service Catalog Dictionary
    Log To Console   started

Set Modem Type Based On Index
    [Documentation]  Sets modem type to AB for even index and SB2 for Odd.
    [Arguments]    ${INDEX}
    Run Keyword If    int('${INDEX}')%2 == 0 
    ...    Set Suite Variable    ${modem_type}    AB
    ...  ELSE
    ...    Set Suite Variable    ${modem_type}    SB2
    
Set Service Plan
    [Documentation]  Randomly selects the service plan based on modem type.
    [Arguments]    ${INDEX}
    Run Keyword If    int('${INDEX}')%2 == 0   Set Suite Variable    ${modem_type}    AB
    ... ELSE    Set Suite Variable    ${modem_type}    SB2
    Run Keyword If    int('${INDEX}')%2 == 0 
    ...    Set Suite Variable    ${modem_type}    AB
    ...  ELSE
    ...    Set Suite Variable    ${modem_type}    SB2
    
Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
