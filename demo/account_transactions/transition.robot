################################################################
#
#  File name: transition.robot
#
#  Description: This suite checks the library keywords for account transactions
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
*** Settings ***
Resource    ../../common/resource.robot

Suite Setup         Suite Setup

*** Comments ***
Usage Data: robot -v modem_ip:10.240.110.20 -v modem_mac_colon:00:A0:BC:6C:7D:D7 -v cpe_ip:10.247.41.102 -v modem_type:AB transition.robot
Usage Spock: robot -v modem_ip:10.240.110.21 -v modem_mac_colon:00:A0:BC:6E:B2:F4 -v cpe_ip:10.247.41.107 -v modem_type:AB transition.robot
Usage SB2: robot -v modem_ip:10.240.206.91 -v modem_mac_colon:00:A0:BC:4D:B8:A4 -v cpe_ip:10.240.5.64 -v modem_type:SB2 transition.robot

*** Variables ***


*** Test Cases ***
Transition Account
    [Documentation]    For given BO parameters transition the account
    [Tags]    transition
    ${modem_deprov}   Run Keyword And Return Status   Read Service Flow Ids    Deprovision Test
    ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${old_plan}    ${ext_svc_agree_ref}    Run Keyword If    ${modem_deprov}      Get New Account From DB And Associate With Modem    ${system_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan_to_query}
    ...  ELSE
    ...    Get Current Account Info    ${modem_mac_colon}   ${user}
    Set Suite Variable    ${internal_acct_reference}    ${account_id}
    Set Suite Variable    ${ntd_id}    ${service_agreement_id}

    ################### Select random business plan ###################
    
    Set Service Catalog Dictionary
    ${new_plan}    Select Random Service Plan From Config
    FOR    ${INDEX}    IN RANGE    1   100
    \    ${new_plan}    Select Random Service Plan From Config
    \    Log    new plan: ${new_plan}    WARN
    \    Log     old_plan: ${old_plan}    WARN
    \    ${different}    Run Keyword And Return Status    Should Not Be Equal    ${new_plan}    ${old_plan}
    \    Run Keyword If    ${different}    Exit For Loop

    ############# Transition Account #################
    Transition To New Plan    ${ext_acct_ref}    ${order_requestor}    ${order_sold_by}    ${order_entered_by}    ${system_id}    ${new_plan}
  
    ############ Extra checks to verify Modem Is Provisioned #############
    Run Keyword And Continue On Failure    Wait For Verify SDP Service Status Is Active With Correct Plan    ${new_plan}
    Prep Modem To Come Online     ${modem_mac_colon}
    Wait For Fresh Modem Reboot    ${modem_ip}
    Run Keyword And Continue On Failure    Verify Modem Is Online
    Run Keyword And Continue On Failure    Wait For Verify CSP Status Is True On Modem
    Run Keyword And Continue On Failure    Display Openet Information Items    ${service_agreement_id}
    Run Keyword And Continue On Failure    Retrieve SDP Device Status
    Run Keyword And Continue On Failure    Wait For Verify SDP Service Status Is Active With Correct Plan    ${new_plan}

    Run Keyword And Continue On Failure    Display SPR Subscriber Information Items
    Run Keyword And Continue On Failure    Verify Product Status Is OK    ${account_id}
    ####Run Keyword And Continue On Failure    Wait For Fresh Modem Reboot    ${modem_ip}

    Run Keyword And Continue On Failure    Wait Until Keyword Succeeds  2m   20s   Read Service Flow Ids    ${new_plan}
    Run Keyword And Continue On Failure    Wait For Verify CSP Status Is True On Modem
    Run Keyword And Continue On Failure    Verify Modem And PTRIA Status Is Active

    
    ############## CPE checks ########################
    Run Keyword And Continue On Failure   Verify Cpe State
    Run Keyword And Continue On Failure   Verify Internet Is Accessible From CPE
   
*** Keywords ***
Suite Setup
    [Documentation]    Verifies modem is in disconnect state
    ${modem_online}    Run Keyword And Return Status    Verify Modem Is Online
    Run Keyword Unless    ${modem_online}    Prep Modem To Come Online
    Verify Modem Is Online 

Get New Account From DB And Associate With Modem
    [Documentation]    This queries the existing account from DB and associate it with the modem
    [Arguments]    ${system_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan_to_query} 
    ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${old_plan}    ${ext_svc_agree_ref}    Get Active Account Info   ${system_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan_to_query}      
    Set Suite Variable    ${internal_acct_reference}    ${account_id}    
    Set Suite Variable    ${ntd_id}    ${service_agreement_id}
    
    ${result}  Modem Swap To Live Modem    ${modem_mac_colon}    ${service_agreement_id}    ${ext_svc_agree_ref}    ${system_id}    ${transaction_type_name}    ${sales_channel} 
    Should Be True    ${result}[0]
    Set Suite Variable    ${message_id}    ${result}[1]  
    
    
   [return]    ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${old_plan}    ${ext_svc_agree_ref}    
