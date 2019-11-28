#******************************************************************
#
#  File name: resVNO_resource.robot
#
#  Description: SSH library keyword
#
#  Author:  adingankar/swile/pgadekar
#
#  History:
#
#  Date         Version   ModifiedBy  Description
#  -------------------------------------------------- -------
#  11/13/2018      0.1     adingankar     Created file
#
#
#  Copyright (c) ViaSat, 2018
#
#******************************************************************
*** Settings ***
Documentation     A resource file with reusable keywords and variables.
...               The system specific keywords created here form our own
...               domain specific language. They utilize keywords provided
...               by various imported libraries
#Library           SSHLibrary
Library           OperatingSystem
Library           Process
Library           ../../tools/backOfficeProvisioning/backofficeLibrary.py
Library           ../../tools/backOfficeProvisioning/backofficeAPI.py
Library           ../smoke.py
#Resource          parameters.robot
#Resource          ../resVNO_parameters.robot
*** Keywords ***
Fetch NTD_ID From Modem MAC
    [Documentation]    FOr a Modem Mac that has not been disconnected, retrieve  NTD_ID
    [Arguments]    ${modem_mac_colon}
    ${result}    getDeviceState    ${modem_mac_colon}
    Should Not Be Empty    ${result}   Fetch NTD_ID From Modem MAC: getDeviceState failed to find modem mac
    Should Not Be True   "${result}[0]"=="False"   Fetch NTD_ID From Modem MAC: ${result}[1]
    ${ntd_id} =  Get From List    ${result}    1
    ${latitude} =  Get From List     ${result}     2
    ${longitude} =  Get From List     ${result}     3
    ${latitude}    Convert To String    ${latitude}
    ${longitude}    Convert To String    ${longitude}
    [return]  ${ntd_id}     #${latitude}     ${longitude}

Verify Deprovision State In ResVNO Components
    [Documentation]    Verifies given modem is in disconnect state by checking SDP/SPR/Openet/Product Status
    [Arguments]    ${modem_mac_colon}
    Verify SPR Subscriber Information For Modem Disconnection
    Verify Openet Information For Modem Disconnection
    Verify SDP Device Status Is Empty
    
Verify Suspend State of Modem In ResVNO Components
    [Documentation]    Verifies given modem is in disconnect state by checking SDP/SPR/Openet/Product Status
    [Arguments]    ${account_id}    
    Run Keyword And Continue On Failure    Display Openet Information Items
    Run Keyword And Continue On Failure    Verify SDP Service Status For Suspended Account
    #Run Keyword And Continue On Failure    Verify SDP Device Status Is Empty
    Run Keyword And Continue On Failure    Verify SPR Subscriber Information For Suspend
    Run Keyword And Continue On Failure    Verify Product Status Is SU    ${account_id}
    Run Keyword And Continue On Failure    Wait For Fresh Modem Reboot    ${modem_ip}
    Run Keyword And Continue On Failure    Verify Modem Is Online
    Run Keyword And Continue On Failure    Wait Until Keyword Succeeds  3m   20s   Read Service Flow Ids    ${service_catalog_id}    True
    
    
Fetch SDP Device Status
    #removed csaId
    [Documentation]    Checks the device state for a given Modem Mac in SDP API, returned tuple consists of deviceState, ntdId, latitude & longitude
    [Arguments]    ${modem_mac_colon}
    ${result}    getDeviceState    ${modem_mac_colon}
    [return]  ${result}

Fetch SDP Service Status
    [Documentation]    Checks the service state for a given ntdId in SDP API, returned tuple consists of serviceId, serviceState & serviceCatalogId
    [Arguments]    ${ntd_id}
    ${result}    getDeviceService    ${ntd_id}
    [return]  ${result}

Clear Modem Logical BeamId
    [Documentation]    Deletes the csaid (Beam ID) out of the NTD Terminal using the SDP API
    #[Arguments]    ${ntd_id}=${ntd_id}   ${latitude}=${latitude}   ${longitude}=${longitude}
    [Arguments]    ${ntd_id}   ${latitude}   ${longitude}
    ${result}    clearLogicalBeamId    ${ntd_id}    ${latitude}    ${longitude}
    [return]  ${result}

Modem MAC CleanUp In ResVNO
    [Documentation]    Runs a backOfficeLib method called macCleanUp which deletes RB EventSource if it exists, de-activates FixedNTD in SDP & deletes subscriber Policy from SPR
    [Arguments]    ${modem_mac_colon}    ${ntd_id} 
    ${result}    macCleanUp    ${modem_mac_colon}    ${ntd_id}   
    Should Be True    ${result}[0]   ${result}[1]

Modem Swap To Live Modem
    [Documentation]    Runs a modem swap supporting calls
    [Arguments]    ${modem_mac_colon}    ${service_agreement_id}    ${ext_svc_agree_ref}    ${system_id}    ${transaction_type_name}    ${sales_channel} 
    ${result}    modemSwap    ${modem_mac_colon}    ${service_agreement_id}    ${ext_svc_agree_ref}    ${system_id}   ${transaction_type_name}    ${sales_channel}    ${transaction_status_name}
    [return]  ${result}
    
Disconnect Customer Account
    [Documentation]    For a given modemMac, runs a backOfficeLib method called disconnectAccount which figures out extSysName & extAccRef & calls BO disconnectRequest API
    [Arguments]    ${modem_mac_colon}    ${user}
    ${result}    disconnectAccount    ${modem_mac_colon}    ${user}
    [return]  ${result}

Get Current Account Info
    [Documentation]  For a given modemMac, runs a backOfficeLib method called GetCurrentAccount which figures out extSysName & extAccRef
    ...            Returns execution status (true/false), extSysName, extAcctRef, intAccRef, salesChannel, serviceAgrRef, plan, extServAgr
    [Arguments]    ${modem_mac_colon}    ${user}
    ${result}    GetCurrentAccount    ${modem_mac_colon}    ${user}
    Should Be True    ${result}[0]
    [return]  ${result}[3]    ${result}[2]    ${result}[5]    ${result}[7]    ${result}[6]

Get Internal Account From CustomerRelnId And ProductInstanceId
    [Documentation]  For a given combination of PI-ID & customerRelnId, we want to retrieve the Internal Account Id in RESVNO BO to then provision a modem to that account
    [Arguments]    ${customerRelnId}  ${product_instance_id}
    ${result}    queryWBAforInternalAccountRef  ${customerRelnId}  ${product_instance_id}
    [return]    ${result}

Fetch SPR Subscriber Information
    [Documentation]    For a given modemMac, calls the Library function to retrieve SPR attributes such as packageId, status, serviceProvider, videoDataSaverOption & billReset 
    [Arguments]    ${modem_mac_colon}
    ${result}    checkSPR    ${modem_mac_colon}
    [return]  ${result}

Fetch Openet Information
    [Documentation]    For a given ntdId, calls the Library function to retrieve Openet attributes such as monthlyBalance, balanceEffectiveDate & balanaceExpiryDate
    [Arguments]    ${ntd_id}
    ${result}    checkOpenet    ${ntd_id}
    [return]  ${result}

Fetch FSM Information
    [Documentation]    For a given ntdId, calls the Library function to retrieve FSM  details  such as orderStatus, externalOrderid, list of services & list of equipment
    [Arguments]    ${ntd_id}
    ${result}    checkFSM    ${ntd_id}
    [return]  ${result}

Add Account to RESVNO
    [Documentation]    For a given streetAddress, servicePlan, saleschannel, systemId and combination of order entry folks, this keyword calls the Library function to create a new business customer and return intAcctRef
    [Arguments]    ${service_plan}   ${order_street_address}    ${order_city}    ${order_state}    ${order_zipcode}    ${order_country_code}    ${user}    ${sales_channel}    ${order_requestor}    ${order_sold_by}    ${order_entered_by}    ${customer_type}    ${system_id}
    ${result}    addAccount    ${service_plan}   ${order_street_address}    ${order_city}    ${order_state}    ${order_zipcode}    ${order_country_code}    ${user}    ${sales_channel}    ${order_requestor}    ${order_sold_by}    ${order_entered_by}    ${customer_type}    ${system_id}
    [return]  ${result}
    
Set Service Catalog Dictionary
    [Documentation]    Converts the JSON config file of service catalog to dict 
    ${business_plans}    OperatingSystem.Get File    ${CURDIR}/service_plans_input.json 
    ${business_plans_dict}    convertJsonToDictionary     ${business_plans}
    Set Suite Variable    ${business_plans_dict} 

Select Random Service Plan From Config
    [Documentation]    Selects service plan randomly from business_plan.json.
    [Arguments]    ${modem_type}=${modem_type}
    ${gbs_plans}    Get From Dictionary    ${business_plans_dict}    GBS 
    ${modem_based_plans}    Get From Dictionary    ${gbs_plans}    ${modem_type}
    ${new_plan}=  Evaluate  random.choice($modem_based_plans)  random
    [return]  ${new_plan}    
    
Add New Business Account
    [Documentation]    For given BO parameters & specific geographical address, create a new Business Internet Account
    Set Up Order Address Variables
    Log To Console    ${service_plan} ${order_street_add} ${order_city_add} ${order_state_add} ${order_zipcode_add} ${order_country_code_add}
    ${result_list}    Add Account to RESVNO    ${service_plan}   ${order_street_add}    ${order_city_add}       ${order_state_add}    ${order_zipcode_add}    ${order_country_code_add}    ${user}    ${sales_channel}    ${order_requestor}    ${order_sold_by}    ${order_entered_by}    ${customer_type}    ${system_id}

    # if this fails, the first item is "False" and the second item is the failure reason. Otherwise the list contains the values extracted further down.
    ${execution_status} =  Get From List    ${result_list}    0
    ${message}    Get From List   ${result_list}    1
    Should Be True    ${execution_status}    ${message}
    ${internal_acct_reference} =  Get From List    ${result_list}    1
    Set Suite Variable   ${internal_acct_reference}
    ${ext_sys_id} =  Get From List    ${result_list}    2
    ${order_ref} =  Get From List    ${result_list}    3
    ${ntd_id} =  Get From List    ${result_list}    4
    ${ntd_id}    Convert To String    ${ntd_id}
    Set Suite Variable    ${ntd_id}
    ${lat} =  Get From List    ${result_list}    5
    ${lat}    Convert To String    ${lat}
    #Set Suite Variable    ${lat}
    ${long} =  Get From List    ${result_list}    6
    ${long}    Convert To String    ${long}
    #Set Suite Variable    ${long}
    [Return]    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}    ${ntd_id}    ${lat}    ${long}

Associate New Account With Modem 
    [Documentation]    For a given account associate the servicePlan to this given Customer and provision a compatible modem
    [Arguments]    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}    ${modem_mac_colon}=${modem_mac_colon} 
    Log  inside Associate New Account With Modem of resvno resource: ${modem_mac_colon} ${internal_acct_reference} ${ext_sys_id} ${order_ref}    
    ${result}    Associate Modem to Account    ${modem_mac_colon}    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}
    ${result_length}   Get Length   ${result}
    # if result is true then there will be no message, so add dummy message
    Run Keyword If   ${result_length}==1   Append To List   ${result}   modem associated with account
    Should Be True    ${result}[0]    ${result}[1]   

Retrieve SDP Device Status
    [Documentation]    For given Modem MAC, retrieve and display state of device as per SDP
    [Arguments]    ${modem_mac_colon}
    ${result_list}    Fetch SDP Device Status    ${modem_mac_colon} 
    Should Not Be Empty    ${result_list}    SDP device 
    ${device_status} =  Get From List    ${result_list}    0
    Should Not Be True   "${device_status}"=="ERROR"   SDP device status for ${modem_mac_colon} is ERROR
    Should Not Be True   "${device_status}"=="False"   ${result_list}[1]
    #${ntd_id} =  Get From List    ${result_list}    1
    #${csa_id} =  Get From List    ${result_list}    2
    #${latitude} =  Get From List    ${result_list}    2
    #Set Suite Variable   ${latitude}
    #${longitude} =  Get From List    ${result_list}    3
    #Set Suite Variable   ${longitude}

Verify SDP Device Status Is Empty
    [Documentation]    For given Modem MAC, retrieve and display state of device as per SDP
    ${result_list}    Fetch SDP Device Status    ${modem_mac_colon} 
    ${status} =  Get From List    ${result_list}    0
    Should Not Be True    ${status}
    
Verify SDP Service Status Is Active
    [Documentation]    For given ntd_id, retrieve and display state of device as per SDP
    [Arguments]    ${input_plan}=${service_plan}    ${modem_type}=${modem_type}    ${ntd_id}=${ntd_id}
    Log To Console  service plan=${service_plan}
    Log To Console   input plan=${input_plan}
    Log To Console  modem_type=${modem_type}
    ${metered_input_plan}    getPlanName    ${input_plan}    ${modem_type}
    ${result_list}    Fetch SDP Service Status    ${ntd_id}
    #Log    ${result_list}    console=true
    #Log   metered_input_plan is: ${metered_input_plan}    WARN
    #Log   service_plan is: ${service_plan}    WARN
    #Log   input_plan is: ${input_plan}    WARN
    Should Not Be Empty    ${result_list}   SDP service status for service account ${ntd_id} is not available
    Should Not be True   "${result_list}[0]"=="False"   ${result_list}[1]
    ${service_id} =  Get From List    ${result_list}    0
    ${service_state} =  Get From List    ${result_list}    1
    Should Be True   "${service_state}"=="ACTIVE"   Service state for NTD ID=${ntd_id} is ${service_state} instead of ACTIVE
    ${service_catalog_id} =  Get From List    ${result_list}    2
    Should Be Equal    ${metered_input_plan}    ${service_catalog_id}

Wait For Verify SDP Service Status Is Active With Correct Plan
    [Documentation]    For given ntd_id, retrieve and display state of device as per SDP
    [Arguments]    ${input_plan}
    Wait Until Keyword Succeeds    60s    5s  Verify SDP Service Status Is Active  ${input_plan}


Verify SDP Service Status Is Deactivated
    [Documentation]    For given ntd_id, retrieve and display state of device as per SDP  
    ${result_list}    Fetch SDP Service Status    ${ntd_id}
    Log    ${result_list}    console=true
    Should Not Be Empty    ${result_list}   SDP service status for service account ${ntd_id} is not available
    Should Not be True   "${result_list}[0]"=="False"   ${result_list}[1]
    ${service_id} =  Get From List    ${result_list}    0
    ${service_state} =  Get From List    ${result_list}    1
    Should Be True   "${service_state}"=="DEACTIVATED"   Service state for NTD ID=${ntd_id} is ${service_state} instead of DEACTIVATED
    ${service_catalog_id} =  Get From List    ${result_list}    2
    
Verify SDP Service Status For Suspended Account
    [Documentation]    For given ntd_id, retrieve and display state of device as per SDP  
    ${result_list}    Fetch SDP Service Status    ${ntd_id}
    Log    ${result_list}    console=true
    Should Not Be Empty    ${result_list}   SDP service status for service account ${ntd_id} is not available
    Should Not be True   "${result_list}[0]"=="False"   ${result_list}[1]
    ${service_id} =  Get From List    ${result_list}    0
    ${service_state} =  Get From List    ${result_list}    1
    Should Be True   "${service_state}"=="ACTIVE"   Service state for NTD ID=${ntd_id} is ${service_state} instead of ACTIVE
    ${service_catalog_id} =  Get From List    ${result_list}    2
    Should Contain    ${service_catalog_id}    Suspend
    Set Suite Variable    ${service_catalog_id}
    
Display SPR Subscriber Information Items
    [Documentation]    For given Modem MAC, display various SPR information items
    [Arguments]    ${modem_mac_colon}
    ${result_list}    Fetch SPR Subscriber Information    ${modem_mac_colon}
    Log To Console   ${result_list}
    Should Not Be True   "${result_list}[0]"=="False"   ${result_list}[1]
    ${package_id} =  Get From List    ${result_list}    0
    ${spr_status} =  Get From List    ${result_list}    1
    ${service_provider} =  Get From List    ${result_list}    2
    ${bill_reset} =  Get From List    ${result_list}    3
    ${video_data_saver} =  Get From List    ${result_list}    4    
    Should Be True    ${result_list}
    
Verify SPR Subscriber Information For Modem Disconnection
    [Arguments]    ${modem_mac_colon}
    [Documentation]    For given Modem MAC, display various SPR information items
    ${result_list}    Fetch SPR Subscriber Information    ${modem_mac_colon}
    ${execution_status} =  Get From List    ${result_list}    0
    Should Be True    ${execution_status}==False    SPR query returns service plan = ${execution_status}

Verify SPR Subscriber Information For Suspend
    [Documentation]    For given Modem MAC, display various SPR information items
    ${result_list}    Fetch SPR Subscriber Information    ${modem_mac_colon}
    ${execution_status} =  Get From List    ${result_list}    1
    Should Contain    ${execution_status}    suspended    SPR query returns status as ${execution_status} instead of suspended
    
Display Openet Information Items
    [Documentation]    For given NTD_ID, display Openet Information
    [Arguments]    ${ntd_id}=${ntd_id}
    ${result_list}    Fetch Openet Information    ${ntd_id}
    Should Not Be True   "${result_list}[0]"=="False"   ${result_list}[1]
    ${modem_balance} =  Get From List    ${result_list}    0
    ${openet_effective_date} =  Get From List    ${result_list}    1
    ${openet_expiry_date} =  Get From List    ${result_list}    2
    
Verify Openet Information For Modem Disconnection
    [Documentation]    For given Modem MAC, display Openet Information
    ${result_list}    Fetch Openet Information    ${modem_mac_colon}
    ${execution_status} =  Get From List    ${result_list}    0
    Should Be True    ${execution_status}==False   Openet query returns active service
    
    
Verify Product Status Is OK
    Log    ${input_plan}
    [Documentation]    After provisioning, verify that all customer products have "OK" status in billing database. Returns list of dictionaries.
    ...   To test, try inputs 106606950 or 302750130 instead of ${internal_acct_reference}
    [Arguments]    ${internal_acct_reference}=${internal_acct_reference}    ${input_plan}=${service_plan}
    Log    ${input_plan}
    @{response}    Get Product Status From Billing Using Account Reference    ${internal_acct_reference}
    Log To Console   ${response}
    ${resp_length}   Get Length  ${response}
    Should Be True   ${resp_length}>0   Product status not available for internal account reference ${internal_acct_reference}
    Set Test Variable    ${matches_current_plan}    False
    @{plan_list}=    Create List
    :FOR    ${product}    IN    @{response}
    \   ${business_service}    Run Keyword And Return Status    Should Contain    ${product['name']}    Business
    \   ${matches_current_plan}    Run Keyword If   ${business_service}    Run Keyword And Return Status    Should Contain    ${input_plan}    ${product['name']}
    \   Run Keyword If    ${business_service} and ${matches_current_plan}    Append To List    ${plan_list}    ${product}
    \   Run keyword Unless    ${business_service}    Run Keyword And Continue On Failure   Verify Billing Product Status      ${product}   OK
    ${most_recent_plan}    getRecentPlan    ${plan_list}
    Run Keyword And Continue On Failure   Verify Billing Product Status      ${most_recent_plan}   OK


Verify Product Status For Given Plan
    [Documentation]    Product status can have multiple plans based on history. this keyword looks the status for a given plan.
    [Arguments]    ${product}    ${input_plan}
    Log To Console   mac address = ${modem_mac_colon} '\n'
    @{response}    Get Product Status From Billing Using Account Reference    ${internal_acct_reference}
    Log To Console   ${response}
    ${resp_length}   Get Length  ${response}
    Should Be True   ${resp_length}>0    Product status not available for internal account reference ${internal_acct_reference}
    :FOR    ${product}    IN    @{response}
    \    ${result}   Run Keyword And Continue On Failure   Verify Billing Product Status      ${product}   TX


Verify Product Status Is TX
    [Documentation]    After provisioning, verify that all customer products have "OK" status in billing database. Returns list of dictionaries.
    ...   To test, try inputs 106606950 or 302750130 instead of ${internal_acct_reference}
    [Arguments]    ${internal_acct_reference}=${internal_acct_reference}
    Log To Console   mac address = ${modem_mac_colon} '\n'
    @{response}    Get Product Status From Billing Using Account Reference    ${internal_acct_reference}
    Log To Console   ${response}
    ${resp_length}   Get Length  ${response}
    Should Be True   ${resp_length}>0    Product status not available for internal account reference ${internal_acct_reference}
    :FOR    ${product}    IN    @{response}
    \    ${result}   Run Keyword And Continue On Failure   Verify Billing Product Status      ${product}   TX
    
Verify Product Status Is SU
    [Documentation]    After suspending, verify that all customer products have "SU" status in billing database. Returns list of dictionaries.
    ...   To test, try inputs 106606950 or 302750130 instead of ${internal_acct_reference}
    [Arguments]    ${internal_acct_reference}=${internal_acct_reference}
    Log To Console   mac address = ${modem_mac_colon} '\n'
    @{response}    Get Product Status From Billing Using Account Reference    ${internal_acct_reference}
    Log To Console   ${response}
    ${resp_length}   Get Length  ${response}
    Should Be True   ${resp_length}>0    Product status not available for internal account reference ${internal_acct_reference}
    :FOR    ${product}    IN    @{response}
    \    ${result}   Run Keyword And Continue On Failure   Verify Billing Product Status      ${product}   SU
    
Suspend Existing Account
    [Documentation]    For a given external account reference, systemId and combination of order entry folks, this keyword calls the Library function to suspend existing customer 
    [Arguments]    ${external_account}    ${order_requestor}    ${order_sold_by}    ${system_id}
    ${result_list}    suspendAccount    ${external_account}   ${order_requestor}    ${order_sold_by}    ${system_id}
    # if this fails, the first item is "False" and the second item is the failure reason. Otherwise the list contains the values extracted further down.
    ${execution_status} =  Get From List    ${result_list}    0
    ${message}    Get From List   ${result_list}    1
    Should Be True    ${execution_status}    ${message}
    ${ext_sys_id} =  Get From List    ${result_list}    1
    ${order_ref} =  Get From List    ${result_list}    2
    
Resume Suspended Account
    [Documentation]    For a given external account reference, systemId and combination of order entry folks, this keyword calls the Library function to resume suspended customer 
    [Arguments]    ${external_account}    ${order_requestor}    ${order_sold_by}    ${system_id}
    ${result_list}    resumeAccount    ${external_account}   ${order_requestor}    ${order_sold_by}    ${system_id}
    # if this fails, the first item is "False" and the second item is the failure reason. Otherwise the list contains the values extracted further down.
    ${execution_status} =  Get From List    ${result_list}    0
    ${message}    Get From List   ${result_list}    1
    Should Be True    ${execution_status}    ${message}
    ${ext_sys_id} =  Get From List    ${result_list}    1


Transition To New Plan
    [Documentation]    For a given external account reference, systemId and combination of order entry folks, this keyword calls the Library function to Transition To New Plan
    [Arguments]    ${external_account}    ${order_requestor}    ${order_sold_by}    ${order_entered_by}    ${system_id}    ${new_plan}
    ${result_list}    transitionPlan    ${external_account}   ${order_requestor}    ${order_sold_by}    ${order_entered_by}    ${system_id}    ${new_plan}
    # if this fails, the first item is "False" and the second item is the failure reason. Otherwise the list contains the values extracted further down.
    ${execution_status} =  Get From List    ${result_list}    0
    ${message}    Get From List   ${result_list}    1
    Should Be True    ${execution_status}    ${message}
    ${ext_sys_id} =  Get From List    ${result_list}    1
    
    
Associate Modem to Account
    [Documentation]    For a given modemMac & InternalAcctRef, calls the Library function to associate business account to modem under Test
    [Arguments]    ${modem_mac_colon}    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}
    Log   inside Associate Modem to Account of resvno resource: ${modem_mac_colon} ${internal_acct_reference} ${ext_sys_id} ${order_ref}    
    ${result}    provisionModem2Account    ${modem_mac_colon}    ${internal_acct_reference}    ${ext_sys_id}    ${order_ref}
    [return]  ${result}

Get Modem And PTRIA Status
    [Documentation]     Using service agreement id, check wb_data for modem and ptria status
    [Arguments]         ${service_agreement_id}
    ${status}    getModemPtriaStatus    ${service_agreement_id}
    [return]     ${status}
    
Get Product Status From Billing Using Account Reference
    [Documentation]     Starting with account ref #, get status of all of this order's products in billing database
    [Arguments]         ${account_reference_id}
    ${product_status}   getBillingProductStatusFromAccountReference   ${account_reference_id}
    [return]    ${product_status}

Get Active Account Info
    [Documentation]     Using systemID, salesChannel, extAcctStatsWith, modemType get the first account reference #
    [Arguments]         ${ext_sys_id}  ${sales_channel}  ${account_starts_with}  ${modem_type}  ${no_of_days_active_account}  ${plan}
    #${response}    getBillingProductStatusFromCustomerReferenceId    12323
    Log To Console    Inputs To Get Active Account: sys id: ${ext_sys_id}, sales channel:${sales_channel}, acct start with:${account_starts_with}, modem type:${modem_type},# od days:${no_of_days_active_account}, plan:${plan}
    ${query_response}    getActiveAccountReference    ${ext_sys_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    ${account_id}    Get From List     ${query_response}    0
    ${ext_acct_ref}    Get From List     ${query_response}    1
    ${service_agreement_id}    Get From List     ${query_response}    3
    ${ext_svc_agree_ref}    Get From List     ${query_response}    4
    ${plan}    Get From List     ${query_response}    8
    ${account_id}    Convert To Integer    ${account_id}
    ${service_agreement_id}    Convert To Integer    ${service_agreement_id}
    ${service_agreement_id}    Convert To String    ${service_agreement_id}
    Log   account_id is:${account_id}   WARN
    Log   external ref id is:${ext_acct_ref}   WARN
    Log   service_agreement_id:${service_agreement_id}   WARN
    Log   plan:${plan}   WARN
    Log   ext_svc_agree_ref is:${ext_svc_agree_ref}   WARN
    [return]     ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${plan}    ${ext_svc_agree_ref}
    
Get Suspended Account Info
    [Documentation]     Using systemID, salesChannel, extAcctStatsWith, modemType get the first suspended account reference #
    [Arguments]         ${ext_sys_id}  ${sales_channel}  ${account_starts_with}  ${modem_type}  ${no_of_days_active_account}  ${plan}
    ${query_response}    getSuspendedAccountReference    ${ext_sys_id}  ${sales_channel}    ${account_starts_with}    ${modem_type}    ${no_of_days_active_account}  ${plan}
    #Log     DB Output is ${query_response}    WARN   
    ${account_id}    Get From List     ${query_response}    0
    ${ext_acct_ref}    Get From List     ${query_response}    1
    ${service_agreement_id}    Get From List     ${query_response}    3
    ${ext_svc_agree_ref}    Get From List     ${query_response}    4
    ${plan}    Get From List     ${query_response}    8
    ${account_id}    Convert To Integer    ${account_id}
    ${service_agreement_id}    Convert To Integer    ${service_agreement_id}
    ${service_agreement_id}    Convert To String    ${service_agreement_id}
    Log   account_id is:${account_id}   WARN
    Log   external ref id is:${ext_acct_ref}   WARN
    Log   service_agreement_id:${service_agreement_id}   WARN
    Log   plan:${plan}   WARN
    Log   ext_svc_agree_ref is:${ext_svc_agree_ref}   WARN
    [return]     ${account_id}    ${ext_acct_ref}    ${service_agreement_id}    ${plan}    ${ext_svc_agree_ref}
    
Verify Billing Product Status
    [Documentation]     Given expected status, and dictionary with status, name, and reason, verify status = expected value
    [Arguments]         ${product}    ${expected_status}
    ${status}   ${message}    Should Be Equal   ${product['status']}    ${expected_status}    ${product['name']} has status ${product['status']} with reason ${product['reason']}
    [return]   ${status}   ${message}

Verify Account & Product Status In Volubill For Suspend State
    [Documentation]      Verify Account & Product Status In Volubill For Suspend State
    [Arguments]         ${service_agreement_id}
     #### Verify Account Status In Volubill For Suspend   ${service_agreement_id} ####
    ${query_response}    getVolubillAccountStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    ${status}    Get From List     ${query_response}    4
    Run Keyword And Continue On Failure    Should Contain Any    ${status}    Active
    Log   status is:${status}   WARN
     ##### Verify Product Status In Volubill For Suspend   ${service_agreement_id} #####
    ${query_response}    getVolubillProductStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    :FOR    ${product}    IN    @{query_response}
    #\    Log   product in for loop is:${product}   WARN
    #\    ${plan_name}    Get From List     ${product}    4
    #\    ${business_plan}    Run Keyword And Return Status    Should Contain    ${plan_name}    Business
    #\    ${valid_plan}        Run Keyword If    ${business_plan}    Check If Valid Plan     ${plan_name}    ${input_plan}
    #\    Run Keyword If    ${valid_plan}    Verify Product Status In VB    ${product}
    #\    Run Keyword Unless    ${business_plan}    Verify Product Status In VB    ${product}
    \    ${status}    Get From List     ${product}    6
    \    Run Keyword And Continue On Failure    Should Contain    ${status}    BLOCKED

Verify Account & Product Status In Volubill For New Connect
    [Documentation]      Verify Account & Product Status In Volubill For new connect before provisioning
    [Arguments]         ${service_agreement_id}
     #### Verify Account Status In Volubill For Suspend   ${service_agreement_id} ####
    ${query_response}    getVolubillAccountStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    ${status}    Get From List     ${query_response}    4
    Should Contain Any    ${status}    New
    Log   status is:${status}   WARN
     ##### Verify Product Status In Volubill For Suspend   ${service_agreement_id} #####
    ${query_response}    getVolubillProductStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    :FOR    ${product}    IN    @{query_response}
    #\    Log   product in for loop is:${product}   WARN
    #\    ${plan_name}    Get From List     ${product}    4
    #\    ${business_plan}    Run Keyword And Return Status    Should Contain    ${plan_name}    Business
    #\    ${valid_plan}        Run Keyword If    ${business_plan}    Check If Valid Plan     ${plan_name}    ${input_plan}
    #\    Run Keyword If    ${valid_plan}    Verify Product Status In VB    ${product}
    #\    Run Keyword Unless    ${business_plan}    Verify Product Status In VB    ${product}
    \    ${status}    Get From List     ${product}    6
    \    Run Keyword And Continue On Failure    Should Contain    ${status}    NEW

Verify Account & Product Status In Volubill For Provisioned State
    [Documentation]      Verify Account & Product Status In Volubill For provisioned state
    [Arguments]         ${service_agreement_id}
     #### Verify Account Status In Volubill For Suspend   ${service_agreement_id} ####
    ${query_response}    getVolubillAccountStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    ${status}    Get From List     ${query_response}    4
    Should Contain Any    ${status}    Active
    Log   status is:${status}   WARN
     ##### Verify Product Status In Volubill For Suspend   ${service_agreement_id} #####
    ${query_response}    getVolubillProductStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    :FOR    ${product}    IN    @{query_response}
    #\    Log   product in for loop is:${product}   WARN
    #\    ${plan_name}    Get From List     ${product}    4
    #\    ${business_plan}    Run Keyword And Return Status    Should Contain    ${plan_name}    Business
    #\    ${valid_plan}        Run Keyword If    ${business_plan}    Check If Valid Plan     ${plan_name}    ${input_plan}
    #\    Run Keyword If    ${valid_plan}    Verify Product Status In VB    ${product}
    #\    Run Keyword Unless    ${business_plan}    Verify Product Status In VB    ${product}
    \    ${status}    Get From List     ${product}    6
    \    Run Keyword And Continue On Failure    Should Contain    ${status}    ACTIVE

Verify Account & Product Status In Volubill For Disconnect State
    [Documentation]      Verify Account & Product Status In Volubill For disconnect State
    [Arguments]         ${service_agreement_id}
     #### Verify Account Status In Volubill For Suspend   ${service_agreement_id} ####
    ${query_response}    getVolubillAccountStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    ${status}    Get From List     ${query_response}    4
    Should Contain Any    ${status}    Closed
    Log   status is:${status}   WARN
     ##### Verify Product Status In Volubill For Suspend   ${service_agreement_id} #####
    ${query_response}    getVolubillProductStatus    ${service_agreement_id}
    Should Not Be Empty    ${query_response}
    Log To Console     DB Output is ${query_response}
    :FOR    ${product}    IN    @{query_response}
    #\    Log   product in for loop is:${product}   WARN
    #\    ${plan_name}    Get From List     ${product}    4
    #\    ${business_plan}    Run Keyword And Return Status    Should Contain    ${plan_name}    Business
    #\    ${valid_plan}        Run Keyword If    ${business_plan}    Check If Valid Plan     ${plan_name}    ${input_plan}
    #\    Run Keyword If    ${valid_plan}    Verify Product Status In VB    ${product}
    #\    Run Keyword Unless    ${business_plan}    Verify Product Status In VB    ${product}
    \    ${status}    Get From List     ${product}    6
    \    Run Keyword And Continue On Failure    Should Contain    ${status}    CLOSED

Verify Product Status In VB
    [Arguments]  ${product}
    ${status}    Get From List     ${product}    5
    Should Contain    ${status}    ACTIVE

Check If Valid Plan
    [Documentation]  The DB response in VB retruns multiple business plan, this keyword ietartes and returns valid Plan
    [Arguments]  ${plan_name}  ${input_plan}
    Log   plan name in for loop is:${plan_name}   WARN
    ${valid_plan}    Run Keyword And Return Status    Should Contain    ${plan_name}    ${input_plan}
    [return]    ${valid_plan}

Run SDP Modem Speed Test
    [Documentation]  Will run a DOWNLOAD or UPLOAD speed test against a given modem and testType and will return the state of the command
    [Arguments]  ${modem_mac_colon}  ${speed_test_type}
    ${result}   runModemSpeedTest  ${modem_mac_colon}  ${speed_test_type}
    [return]    ${result}

Set Up Order Address Variables
    [Documentation]  Sets up the address variables based on modem type
    Run Keyword If    '${modem_type}' == 'AB'    Run Keywords
    ...    Set Suite Variable    ${order_street_add}    ${order_street_address}   AND
    ...    Set Suite Variable    ${order_city_add}      ${order_city}   AND
    ...    Set Suite Variable    ${order_state_add}      ${order_state}   AND
    ...    Set Suite Variable    ${order_zipcode_add}      ${order_zipcode}    AND
    ...    Set Suite Variable    ${order_country_code_add)    ${order_country_code}
    ...  ELSE IF    '${modem_type}' == 'SB2'    Run Keywords
    ...    Set Suite Variable    ${order_street_add}    ${sb_order_street_address}   AND
    ...    Set Suite Variable    ${order_city_add}      ${sb_order_city}   AND
    ...    Set Suite Variable    ${order_state_add}      ${sb_order_state}   AND
    ...    Set Suite Variable    ${order_zipcode_add}      ${sb_order_zipcode}    AND
    ...    Set Suite Variable    ${order_country_code_add}    ${sb_order_country_code}
    ...  ELSE
    ...     Log     modem type is not valid     WARN  
ResVNO Smoke
    [Documentation]   Invokes resvno smoke test
    &{resvno_status}   resvno_smoke_test
    :FOR    ${key}    IN    @{resvno_status.keys()}
    \    Run Keyword If   '${key}'!='in_error'   Should Be Equal   ${resvno_status["${key}"]}    OK    ${key} status is ${resvno_status["${key}"]} instead of OK
Get Video Data Saver Option
    [Documentation]    Checks the value of the video data saver option and returns it
    [Arguments]   ${serviceAgreementReference}
    ${status}  ${result}    getVideoDataSaver    ${serviceAgreementReference}
    [return]    ${result}  ${status}
Update Video Data Saver Option
    [Documentation]    Switches the Video Data Saver Option if it is set to TRUE
    [Arguments]    ${servicAgreementReference}    ${videoDataSaverOption}
    ${status}    ${result}    updateVideoDataSaver    ${servicAgreementReference}  ${videoDataSaverOption}
    [return]    ${result}  ${status}
