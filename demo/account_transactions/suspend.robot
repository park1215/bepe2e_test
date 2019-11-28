################################################################
#
#  File name: suspend.robot
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
#Suite Teardown      Suite Teardown

*** Comments ***
Usage Data: robot -v modem_ip:10.240.110.20 -v modem_mac_colon:00:A0:BC:6C:7D:D7 -v cpe_ip:10.247.41.102 -v modem_type:AB -v no_of_days_active_account:5 -v system_id:WB_DIRECT -v sales_channel:B2B_PARTNERS suspend.robot
Usage Spock: robot -v modem_ip:10.240.110.21 -v modem_mac_colon:00:A0:BC:6E:B2:F4 -v cpe_ip:10.247.41.107 -v modem_type:AB -v no_of_days_active_account:5 -v system_id:WB_DIRECT -v sales_channel:B2B_PARTNERS suspend.robot
Usage SB2: robot -v modem_ip:10.240.206.91 -v modem_mac_colon:00:A0:BC:4D:B8:A4 -v cpe_ip:10.240.5.64 -v modem_type:SB2 -v no_of_days_active_account:5 -v system_id:WB_DIRECT -v sales_channel:B2B_PARTNERS suspend.robot
Usage Spock: robot -v modem_ip:10.240.110.19 -v modem_mac_colon:00:A0:BC:6E:B2:9C -v cpe_ip:10.247.41.89 -v modem_type:AB -v no_of_days_active_account:5 -v system_id:WB_DIRECT -v sales_channel:B2B_PARTNERS suspend.robot
Usage SB2: robot -v modem_ip:10.240.206.81 -v modem_mac_colon:00:A0:BC:46:FD:AC -v cpe_ip:10.240.5.63 -v modem_type:SB2 -v no_of_days_active_account:5 -v system_id:WB_DIRECT -v sales_channel:B2B_PARTNERS suspend.robot

*** Variables ***


*** Test Cases ***
Suspend Existing Account
    [Documentation]    For given BO parameters suspend a existing Account 
    [Tags]    suspend 
    
    ################### Temp Query ###################
    ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${plan}    ${ext_svc_agree_ref}    Get Active Account Info   ${system_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan_to_query}    
    Set Suite Variable    ${internal_acct_reference}    ${account_id}
    Set Suite Variable    ${ntd_id}    ${service_agreement_id}

    ${type_of_ntd}    Evaluate    type($ntd_id)
    #${type_of_acctid}    Evaluate    type(internal_acct_reference)
    Log    NTD ID is ${ntd_id}     WARN
    Log    type_of_ntd ID is ${type_of_ntd}     WARN

    #Log    internal_acct_reference ID is ${internal_acct_reference}     WARN
    #Log    type_of_acctid ID is ${type_of_acctid}     WARN


    ########### Modem Swap #############
    ${result}  Modem Swap To Live Modem    ${modem_mac_colon}    ${service_agreement_id}    ${ext_svc_agree_ref}    ${system_id}    ${transaction_type_name}    ${sales_channel} 
    Should Be True    ${result}[0]
    Set Suite Variable    ${message_id}    ${result}[1]   
    
    
    ############# Suspend Account #################
    Suspend Existing Account    ${ext_acct_ref}    ${order_requestor}    ${order_sold_by}    ${system_id}
    
    ##################### Extra checks to verify Modem Is In Suspend State ###################
    Verify Suspend State of Modem In ResVNO Components    ${account_id}
    Verify Account & Product Status In Volubill For Suspend State    ${service_agreement_id}
    
    ############## CPE checks ########################
    Run Keyword And Continue On Failure    Verify Cpe State
    Run Keyword And Continue On Failure    Verify Internet Is Not Accessible From CPE
    
   
*** Keywords ***
Suite Setup
    [Documentation]    Verifies modem is in disconnect state if not, de-provision it
    #Log To Console   Modem is already in de-proviosioned state
    ${service_flow_status}   Run Keyword And Return Status   Read Service Flow Ids    Deprovision Test
    Run Keyword If  '${service_flow_status}' == 'False'    Run Keywords
    ...    De-provision The Modem   AND
    ...    Verify SDP Service Status Is Deactivated   AND
    ...    Verify SDP Device Status Is Empty   AND
    ...    Verify SPR Subscriber Information For Modem Disconnection   AND
    ...    Verify Openet Information For Modem Disconnection   AND
    ...    Verify Modem And PTRIA Status Is Inactive   AND
    ...    Verify Product Status Is TX   AND
    ...    Wait For Fresh Modem Reboot    ${modem_ip}   AND
    ...    Verify Modem Is Online   AND
    ...    Wait Until Keyword Succeeds  3m   20s   Read Service Flow Ids   Deprovision Test
    ...  ELSE
    ...  Log To Console   Modem is already in de-proviosioned state
    
    
