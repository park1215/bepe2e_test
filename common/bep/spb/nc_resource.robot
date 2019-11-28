*** Settings ***
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Library    OperatingSystem
Library    Process
Library   ./spb_api.py
Library   ./spb_postgres_db.py
Library   ./spb_nc_db.py
Library   ./spb_sftp.py
Library   ../../../python_libs/bep_common.py
Variables   ./spb_parameters.py

*** Keywords ***
Get Netcracker Payments
    [Documentation]   get total_paid_tot from account, account_payment_mny from accountpayment, physical_payment_mny from physicalpayment
    [Arguments]   ${account}
    ${date}    Get Current Date
    ${date}    Convert Date	   ${date}	 result_format=%Y-%m-%d
    ${acolumns}    Create List   customer_ref  total_paid_tot
    ${account_info}   Create Dictionary   index=account_num   fields=${acolumns}
    ${apcolumns}    Create List   account_payment_mny   TO_CHAR(account_payment_dat, 'YYYY-MM-DD') as account_payment_dat
    ${accountpayment_info}   Create Dictionary   index=account_num   fields=${apcolumns}   where=${SPACE}and TO_CHAR(account_payment_dat, 'YYYY-MM-DD')='${date}'
    ${ppcolumns}    Create List   physical_payment_mny    TO_CHAR(physical_payment_dat, 'YYYY-MM-DD') as physical_payment_dat
    ${physicalpayment_info}   Create Dictionary   index=customer_ref   fields=${ppcolumns}   where=${SPACE}and TO_CHAR(physical_payment_dat, 'YYYY-MM-DD')='${date}'
    ${nc_info}  Create Dictionary   account=${account_info}  accountpayment=${accountpayment_info}   physicalpayment=${physicalpayment_info}
    ${accounts}   Create List  ${account}
    ${result}   useSpbNcApi   getBillingTableEntries  ${nc_info}  ${accounts}   False
    [return]   ${result}
  
Add Prmandate To Prmandate List
    [Arguments]   ${columns}   ${entry}
    ${item}   bep_common.createDictionaryFromLists   ${columns}    ${entry}
    Append To List  ${prmandates}   ${item}

Get Prmandate Table From NC
    [Arguments]   ${account}
    ${columns}   Create List  payment_method_id  mandate_status   active_from_dat   active_to_dat   mandate_attr_1
    ${col_string}   Set Variable   payment_method_id,mandate_status,TO_CHAR(active_from_dat, 'YYYY-MM-DD') as active_from_dat,TO_CHAR(active_to_dat, 'YYYY-MM-DD') as active_to_dat,mandate_attr_1
    ${query}  Set Variable   Select ${col_string} from prmandate where account_num='${account}'
    Log   ${query}
    ${response}   sql_libs.queryNC   ${query}
    Should Be Equal As Strings   ${response}[0]    Pass   prmandate query yields ${response}[1] for query ${query}
    ${prmandates}  Create List
    Set Test Variable   ${prmandates}
    ${results}  Set Variable  ${response}[1]
    :FOR   ${entry}   IN  @{results}
    \     Add Prmandate To Prmandate List   ${columns}   ${entry}

    Log   PRMANDATES=${prmandates}   console=True
    [return]   ${prmandates}
   
Verify Payment Mandate Change In NC
    [Documentation]   Query NC to verify the presence of the old and new payment methods. This only works when there is one previous payment method.
    [Arguments]   ${account}   ${expected_before}    ${expected_after}   
    ${nc_result}    Get Prmandate Table From NC    ${account}
    # verify that only one of the entries has a "to_date" = None
    ${nc_length}   Get Length   ${nc_result}
    Should Be True   ${nc_length}>1   prmandate table missing entry after new recurring payment method added:${nc_result}[0]
    
    :FOR   ${entry}   IN  @{nc_result}
    \   Run Keyword If   '${entry}[active_to_dat]'=='None'    Set Test Variable  ${new_mandate}   ${entry}
    \   Run Keyword If   '${entry}[active_to_dat]'!='None'    Set Test Variable  ${old_mandate}   ${entry}
    Variable Should Exist    ${new_mandate}
    Variable Should Exist    ${old_mandate}
    Should Be Equal As Strings    ${old_mandate}[active_to_dat]   ${expected_before}[active_to_dat]
    Should Be Equal As Strings    ${old_mandate}[mandate_status]   ${expected_before}[mandate_status]
    Should Be Equal As Strings    ${new_mandate}[mandate_status]   ${expected_after}[mandate_status]
    [return]   ${nc_result}
    
Get NC Id For Payment Method
    [Documentation]   NC has one id for all CCs and separate ids for other payment methods eg SEPA
    [Arguments]   ${payment_type}
    ${status}   ${message}   Run Keyword And Ignore Error  List Should Contain Value    ${VPS_CC_SELECTIONS}   ${payment_type} 
    ${payment_method_id}  Set Variable If  '${status}'=='PASS'   ${VPS_PAYMENT_TYPES}[${COUNTRY_CODE}][CC]   ${VPS_PAYMENT_TYPES}[${COUNTRY_CODE}][${VPS_RECURRING_PAYMENT_METHOD}]
    [return]   ${payment_method_id}
    
Locate NC Accounts With Filter
    [Documentation]   Filter list of (500x) accounts by specified product name, status, plan (optional), next bill date (optional). Date is in format YYYY-MM-DD
    [Arguments]    ${accounts}   ${product_name}   ${status}=OK  ${plan}=${EMPTY}   ${next_bill_date}=${EMPTY}
    ${result}   filterAccountsByProductNameAndStatus   ${accounts}   ${product_name}   ${status}
    [return]   ${result}