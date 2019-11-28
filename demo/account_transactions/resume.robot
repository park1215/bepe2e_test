################################################################
#
#  File name: resume.robot
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
Resource    ../common/modem/modem_resources.robot

Suite Setup         Suite Setup
#Suite Teardown      Suite Teardown

*** Comments ***
Usage Data: robot -v modem_ip:10.240.110.20 -v modem_mac_colon:00:A0:BC:6C:7D:D7 -v cpe_ip:10.247.41.102 -v modem_type:AB resume.robot
Usage Spock: robot -v modem_ip:10.240.110.21 -v modem_mac_colon:00:A0:BC:6E:B2:F4 -v cpe_ip:10.247.41.107 -v modem_type:AB resume.robot
Usage SB2: robot -v modem_ip:10.240.206.91 -v modem_mac_colon:00:A0:BC:4D:B8:A4 -v cpe_ip:10.240.5.64 -v modem_type:SB2 resume.robot

*** Variables ***


*** Test Cases ***
Resume Suspended Account
    [Documentation]    For given BO parameters resume a suspended Account 
    [Tags]    resume 
    
    ################### Temp Query ###################
    ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${plan}    ${ext_svc_agree_ref}    Get Suspended Account Info   ${system_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan_to_query}    
    Set Suite Variable    ${ntd_id}    ${service_agreement_id}
    
    ############# Resume Account #################
    Resume Suspended Account    ${ext_acct_ref}    ${order_requestor}    ${order_sold_by}    ${system_id}
    
    ########### Modem Swap #############
    ${result}  Modem Swap To Live Modem    ${modem_mac_colon}    ${service_agreement_id}    ${ext_svc_agree_ref}    ${system_id}    ${transaction_type_name}    ${sales_channel} 
    Should Be True    ${result}[0]
    Set Suite Variable    ${message_id}    ${result}[1]       


    ############ Extra checks to verify Modem Is Provisioned #############
    Run Keyword And Continue On Failure    Display Openet Information Items    ${service_agreement_id}
    Retrieve SDP Device Status     ${modem_mac_colon}
    #Set Suite Variable    ${latitude}     ${longitude}
    Prep Modem To Come Online     ${modem_mac_colon}
    #Run Keyword And Continue On Failure    Retrieve SDP Device Status     ${modem_mac_colon}
    Run Keyword And Continue On Failure    Verify SDP Service Status Is Active    ${plan}
    Run Keyword And Continue On Failure    Display SPR Subscriber Information Items     ${modem_mac_colon}
    Run Keyword And Continue On Failure    Verify Product Status Is OK    ${account_id}     ${plan}
    Run Keyword And Continue On Failure    Wait For Fresh Modem Reboot    ${modem_ip}
    Run Keyword And Continue On Failure    Verify Modem Is Online
    Run Keyword And Continue On Failure    Wait Until Keyword Succeeds  2m   20s   Read Service Flow Ids    ${plan}
    Run Keyword And Continue On Failure    Wait For Verify CSP Status Is True On Modem
    Run Keyword And Continue On Failure    Verify Account & Product Status In Volubill For Provisioned State    ${service_agreement_id}
    Run Keyword And Continue On Failure    Verify Modem And PTRIA Status Is Active    

    
    ############## CPE checks ########################
    Run Keyword And Continue On Failure   Verify Cpe State
    Run Keyword And Continue On Failure   Verify Internet Is Accessible From CPE
   
*** Keywords ***
Suite Setup
    [Documentation]    Verifies modem is in disconnect state
    #${ResVNO_Status}    Run Keyword And Return Status    Verify Deprovision State In ResVNO Components    ${modem_mac_colon}
    #Set Suite Variable    ${service_plan}    Deprovision Test
    ${service_flow_status}   Run Keyword And Return Status   Read Service Flow Ids    Deprovision Test
    #Run Keyword If  '${ResVNO_Status}' == 'False' and '${service_flow_status}' == 'False'    Run Keywords
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
    #Modem MAC CleanUp In ResVNO    ${modem_mac_colon}
