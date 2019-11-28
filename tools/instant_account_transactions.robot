################################################################
#
#  File name: instant_account_transactions.robot
#
#  Description: This suite checks the library keywords for account transactions
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
*** Settings ***
Resource    ../common/resource.robot

Suite Setup         Suite Setup
#Suite Teardown      Suite Teardown

*** Comments ***
Usage Data: robot -v modem_ip:10.240.110.20 -v modem_mac_colon:00:A0:BC:6C:7D:D7 -v cpe_ip:10.247.41.102 -v modem_type:AB -v service_plan:'Business Metered 20 GB' instant_account_transactions.robot
Usage Spock: robot -v modem_ip:10.240.110.21 -v modem_mac_colon:00:A0:BC:6E:B2:F4 -v cpe_ip:10.247.41.107 -v modem_type:AB -v service_plan:'Business Metered 20 GB' instant_account_transactions.robot
Usage SB2: robot -v modem_ip:10.240.206.91 -v modem_mac_colon:00:A0:BC:4D:B8:A4 -v cpe_ip:10.240.5.64 -v modem_type:SB2 -v service_plan:'Business Metered 20 GB' instant_account_transactions.robot

*** Variables ***


*** Test Cases ***
Add Suspend And Resume New Account
    [Documentation]    For given BO parameters add new account, suspend and then resume it
    [Tags]    suspend 
    #Set Suite Variable    ${internal_acct_reference}    302778684
    #Set Suite Variable    ${ext_sys_id}    WB_DIRECT
    #Set Suite Variable    ${order_ref}    BEPE2E1551466982
    #Set Suite Variable    ${ntd_id}    403031613
    
    ########### Add Account #############
    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}    Add New Business Account
    Associate New Account With Modem    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}   
    
    ############ Extra checks to verify Modem Is Provisioned #############
    Retrieve SDP Device Status
    Verify SDP Service Status Is Active
    Display SPR Subscriber Information Items
    Display Openet Information Items
    Prep Modem To Come Online
    Verify Modem And PTRIA Status Is Active
    Verify Product Status Is OK
    Wait For Fresh Modem Reboot    ${modem_ip}
    Verify Modem Is Online
    Wait For Verify CSP Status Is True On Modem
    Wait Until Keyword Succeeds  2m   20s   Read Service Flow Ids
    Fetch Order Information From FSM    
   
    ################### Temp Query ###################
    #Get Active Account Reference Number   ${ext_sys_id}  ${sales_channel}    ${account_starts_with}    ${int_plan}   ${modem_type}=AB
    
    ############# Suspend Account #################
    Suspend Existing Account    ${order_ref}    ${order_requestor}    ${order_sold_by}    ${system_id}
    
    ##################### Extra checks to verify Modem Is De-Provisioned ###################
    Run Keyword And Continue On Failure    Verify Openet Information For Modem Disconnection
    Prep Modem To Come Online
    Verify SDP Service Status For Suspended Account
    Verify SPR Subscriber Information For Suspend
    Verify Product Status Is SU
    Wait For Fresh Modem Reboot    ${modem_ip}
    Verify Modem Is Online
    Wait Until Keyword Succeeds  3m   20s   Read Service Flow Ids    ${service_catalog_id}    True
    
    ############## CPE checks ########################
    Verify Cpe State
    Verify Internet Is Not Accessible From CPE
    
    ########## Resume Account #############
    Resume Suspended Account    ${order_ref}    ${order_requestor}    ${order_sold_by}    ${system_id}
    
    ############ Extra checks to verify Modem Is Provisioned #############
    Retrieve SDP Device Status
    Verify SDP Service Status Is Active
    Display SPR Subscriber Information Items
    Display Openet Information Items
    Prep Modem To Come Online
    Verify Modem And PTRIA Status Is Active
    Verify Product Status Is OK
    Verify Modem Is Online
    Wait For Verify CSP Status Is True On Modem
    Wait Until Keyword Succeeds  2m   20s   Read Service Flow Ids
    Fetch Order Information From FSM  
    
    ############## CPE checks ########################
    Verify Cpe State
    Verify Internet Is Accessible From CPE
    
*** Keywords ***
Suite Setup
    [Documentation]    Verifies modem is in disconnect state
    #Verify Modem Is In Disconnect State
    Log To Console   started

    
    
