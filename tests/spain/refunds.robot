*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../../common/common_library.py
Library     ../../python_libs/s3lib.py
Resource    ../../common/vps/vps_resource.robot
Resource    ../../common/bep/spb/spb_resource.robot
Resource    ../../common/resource.robot
Variables   ../../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Test Cases ***
Test Refund Within 14 Days
# Get pool of accounts
#  Accounts contain info:  account #, plan, status, status reason, total paid to account, creation date, next bill date
    ${date_to}    Get Current Date
    ${date_from}   Subtract Time From Date  ${date_to}   14 days
    ${date_to}    Convert Date	   ${date_to}	 result_format=%Y-%m-%d
    ${date_from}    Convert Date	   ${date_from}	 result_format=%Y-%m-%d 
    ${accounts}   Get Accounts    ${date_from}    ${date_to}
    Should Be Equal As Strings   ${accounts}[0]   Pass   Unable to get accounts
    ${account_list}  Set Variable   ${accounts}[1]
    ${acct_length}   Get Length   ${account_list}
    Should Be True   ${account_length}>0   No accounts found that match criteria
    
    :FOR   ${account} in @{account_list}
    \     Exit For Loop If   ${account}[4] > 0
    Should Be True  ${account}[4] > 0   No accounts with refundable amount found
    
    
    
    
    
*** Keywords ***
Suite Setup
    Set Country Specific Variables
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    
    
Suite Teardown
    Log   Teardown


Get Accounts
    [Documentation]  gets a list of "OK" accounts satisfying creation date window and status
    [Arguments]   ${creation_date_earliest}   ${creation_date_latest}   
    ${result}   getIraPii   Bepe2e   ${COUNTRY_CODE}
    ${payer_role_ids}   Create List
    ${payer_role_dict}   Create Dictionary
    :FOR   ${entry}   IN   @{result}
    \   Append To List   ${payer_role_ids}   ${entry}[1]
    ${accounts}   Get Billing Accounts By Payer Role Id And Creation Date   ${payer_role_ids}   ${creation_date_earliest}   ${creation_date_latest} 
    ${filtered_accounts}   Locate NC Accounts With Filter     ${accounts}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PRODUCT_PLAN]
    [return]  ${filtered_accounts}