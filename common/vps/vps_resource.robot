*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     vps_api.py
Library     ../bep/spb/spb_postgres_db.py
Resource    ../bep/spb/spb_resource.robot
Library     copy    
Resource    ../resource.robot

*** Keywords ***
Request VPS Payment Transaction Id
    [Documentation]   get a payment transaction ID from VPS so we can authorize payment and capture sale
    [Arguments]   ${transactionParameters}=${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}    
    ${txn_amount}   Set Variable   ${transactionParameters}[txnAmount]
    Set Suite Variable  ${txn_amount}
    Log   ${transactionParameters}
    Set To Dictionary   ${transactionParameters}    currencyIsoCode=${EXPECTED_CURRENCY_DICT}[alphabeticCode]   systemName=${VPS_SYSTEM_NAME}
    
    ${id_result}   useVpsApi   requestPaymentTransactionId    ${transactionParameters}  ${vps}
    ${status}   ${message}   Run Keyword   Should Be True    ${id_result}[0]   Request Payment Transaction Id failure = ${id_result}[1]
    Log    ${id_result}[1]
    Set Suite Variable  ${payment_transaction_id}   ${id_result}[1]
    [return]    ${id_result}[1]
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Initialize Transaction With VPS
    [Documentation]   Get payment transaction id and authorize payment info
    [Arguments]   ${customer_ref}    ${advance_payment}
    ${vps_request_payment_transaction_id}   Create Dictionary
    ${vps_request_payment_transaction_id}   copy.deepcopy    ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}   txnAmount=${advance_payment}  systemName=${VPS_SYSTEM_NAME}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}
    ${paymentRetrieve Payment}  Retrieve Payment Transaction Id   ${payment_transaction_id}
    [return]    ${vps_request_payment_transaction_id}    ${payment_transaction_id}

Add One Time Payment Method To VPS
    [Documentation]   Add a payment method for the first payment only
    [Arguments]   ${customer_ref}    ${given_vps_payment_method}
    ${submit_sale_bool}   ${rb_payment_method_id}   ${dontcare}   Retrieve Payment Type Info    ${given_vps_payment_method}
    ${submit_sale_bool}  Set Variable If  '${submit_sale_bool}'=='True'  true   false
    Set Suite Variable   ${submit_sale_bool}
    ${payment_id}   Request Payment On File   ${customer_ref}   ${VPS_PAYMENT_METHODS}[${given_vps_payment_method}]
    Log   one_time_payment id=${payment_id}
    [return]   ${payment_id}

Request Payment On File
    [Documentation]   generic request POF, for OTP or recurring
    [Arguments]   ${ref}   ${method}
    ${payment_id}   Request New Payment On File    ${ref}   ${method}
    [return]   ${payment_id}

Set Recurring Payment Method In VPS
    [Arguments]   ${customer_ref}   ${vps_recurring_payment_method}
    ${method}  Set Variable   ${VPS_PAYMENT_METHODS}[${vps_recurring_payment_method}]
    Set To Dictionary  ${method}   useForRecurringPayment=True
    ${recurring_payment_id}   Request Payment On File   ${customer_ref}   ${method}
    [return]   ${recurring_payment_id}
    
Add Recurring Payment Method To VPS
    [Documentation]   Add a recurring payment method, required for adding the billing account. If not a VPS-handled payment method, skip
    [Arguments]   ${customer_ref}    ${given_vps_recurring_payment_method}
    # get boolean create prmandate entry? and also rb payment method id
    ${create_prmandate}   ${rb_payment_method_id}   ${dontcare}      Retrieve Payment Type Info    ${given_vps_recurring_payment_method}
    Set Suite Variable    ${create_prmandate}
    ${recurring_payment_id}    Set Recurring Payment Method In VPS    ${customer_ref}   ${given_vps_recurring_payment_method}
    [return]     ${recurring_payment_id}

Modify Payment Transaction Id In VPS
    [Documentation]   add billing account id to payment transaction
    [Arguments]   ${billing_account_id}    ${vps_request_payment_transaction_id}
    &{billing_info}   Create Dictionary  billingAccount=${billing_account_id}
    Set To Dictionary   ${vps_request_payment_transaction_id}   additionalDetails=${billing_info}
    Modify VPS Payment Transaction Id   ${vps_request_payment_transaction_id}

Submit Sale To VPS
    [Arguments]   ${one_time_payment_id}
    ${vps_sale}   Create Dictionary   paymentOnFileId=${one_time_payment_id}
    ${result}  VPS Sale   ${vps_sale}
    [return]   ${result}

Randomize Payment
    [Documentation]   used when payment amount is not known
    [Arguments]   ${base_payment}
    ${random}=	 Evaluate	random.randint(0,99)/100   	modules=random
    ${random}   Convert To Number   ${random}
    ${base_payment}  Convert To Number   ${base_payment}
    ${txn_amount}   Evaluate   ${base_payment}+${random}
    Set Suite Variable  ${txn_amount}
    
Modify VPS Payment Transaction Id    
    [Documentation]   modify a payment transaction ID from VPS 
    [Arguments]   ${transactionParameters}
    Set To Dictionary   ${transactionParameters}   systemName=${VPS_SYSTEM_NAME}
    ${id_result}   useVpsApi   modifyPaymentTransactionId    ${transactionParameters}   ${vps}
    ${status}   ${message}   Run Keyword   Should Be True    ${id_result}[0]   Modify Payment Transaction Id failure = ${id_result}[1]
    Log    billing account id = ${id_result}[1]
    
Authorize Payment Method
    [Documentation]   Authorize payment method with VPS
    [Arguments]   ${auth_parameters}=${VPS_AUTH_DEFAULTS}
    ${auth_result}   useVpsApi   auth   ${auth_parameters}   ${vps}   
    ${status}   ${message}   Run Keyword   Should Be True   ${auth_result}[0]   Authorize Payment Method failure = ${auth_result}[1]
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Capture Sale
    [Documentation]   Use payment transaction ID to complete sale. Payment transaction id is already in ${vps} object
    &{params}   Create Dictionary  
    ${sale_result}   useVpsApi  captureSale   ${params}   ${vps}
    ${status}   ${message}   Run Keyword   Should Be True   ${sale_result}[0]   Capture Sale failure = ${sale_result}[1]
    [return]   ${sale_result}[1]
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

VPS Sale
    [Documentation]   Just like Auth but completes the sale
    [Arguments]   ${sale_parameters}
    ${sale_result}   useVpsApi   sale   ${sale_parameters}   ${vps}
    ${status}   ${message}   Run Keyword   Should Be True   ${sale_result}[0]   Sale failure = ${sale_result}[1]
    [return]    ${sale_result}[1]
    
Request New Payment On File 
    [Documentation]  Add a payment on file
    [Arguments]   ${customer_ref}   ${pof_inputs}=${VPS_PAYMENT_METHODS}[${VPS_PAYMENT_METHOD}]  
    Set To Dictionary   ${pof_inputs}   customerRef=${customer_ref}   currencyIsoCode=${EXPECTED_CURRENCY_DICT}[alphabeticCode]    systemName=${VPS_SYSTEM_NAME}
    ${result}   useVpsApi   requestPaymentOnFile  ${pof_inputs}    ${vps}  
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Request Payment On File failure = ${result}[1]
    [return]   ${result}[1]
  
Update Payment On File 
    [Documentation]  Update a payment on file in VPS. ${update_inputs} includes payment id which will be deleted by updatePaymentOnFile
    [Arguments]   ${update_inputs}
    ${result}   useVpsApi   updatePaymentOnFile   ${update_inputs}    ${vps}  
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Update Payment On File failure = ${result}[1]
    [return]    

Retrieve Payment On File
    [Documentation]   Retrieve informationation about a payment on file
    [Arguments]   ${id}
    ${input_dict}   Create Dictionary    id=${id}
    ${result}   useVpsApi   retrievePaymentOnFile   ${input_dict}    ${vps}  
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Retrieve Payment On File failure = ${result}[1]
    [return]   ${result}[1]

Query Payment On File
    [Documentation]   Retrieve informationation about a payment on file
    [Arguments]   ${id}   
    ${input_dict}   Create Dictionary    id=${id}   systemName=${VPS_SYSTEM_NAME}
    ${result}   useVpsApi   queryPaymentOnFile   ${input_dict}    ${vps}    
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Retrieve Payment On File failure = ${result}[1]
    [return]   ${result}[1]
    
Retrieve Payment Transaction Id
    [Documentation]   retrieve info relating to a payment transaction ID from VPS
    [Arguments]   ${id}
    &{params}   Create Dictionary   id=${id}
    ${result}   useVpsApi   retrievePaymentTransactionId    ${params}   ${vps}
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Retrieve Payment Transaction Id failure = ${result}[1]
    [return]   ${result}[1]
    
Refund VPS Payment
    [Documentation]  Refund a payment given the transaction id
    [Arguments]    ${amount}  ${id}=${EMPTY}   
    ${input_dict}   Create Dictionary    txnAmount=${amount}
    Run Keyword If  '${id}'!='${EMPTY}'   Set To Dictionary   ${input_dict}   paymentTxnId=${id}
    ${result}   useVpsApi   refundTransaction    ${input_dict}    ${vps}
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Refund Payment failure = ${result}[1]
    ${status}   ${message}   Run Keyword   Should Be Equal As Strings  ${result}[1]   Success   Refund Payment failure
    [return]   ${result}[1]
    
Delete VPS Payment On File
    [Documentation]  cancel payment method
    [Arguments]   ${id}
    &{params}   Create Dictionary   id=${id}
    ${result}   useVpsApi   deletePaymentOnFile    ${params}   ${vps}
    ${status}   ${message}   Run Keyword   Should Be True    ${result}[0]   Delete Payment failure = ${result}[1]
    [return]
    
Refund Payment And Verify NC Update 
    [Documentation]  Request refund from VPS for the OTP and verifies SPB notifies NC and NC updates tables. ${billing_account_id} is suite variable
    [Arguments]   ${payment_transaction_id}   ${refund_amount}

    #${payment_transaction_id}  Set Variable  a0L8E000004ubSJUAY
    #${billing_account_id}   Set Variable   5000012782

    ${refund_amount}   Convert To Number  ${refund_amount}

    # spb getBillingAccount will show a negative value for balance because customer paid ahead
    ${spb_before}   Get Billing Account From SPB   ${billing_account_id}
    ${spb_balance_before}    Set Variable   ${spb_before}[currentBalance][value]
    ${spb_balance_before}   Convert To Number  ${spb_balance_before}

    Wait Until Keyword Succeeds   15x   30s   Refund VPS Payment  ${refund_amount}   ${payment_transaction_id}
    
    ${spb_balance_expected}   Evaluate  ${refund_amount}+${spb_balance_before}
    
    ${spb_balance_after}   Wait Until Keyword Succeeds  1m   10s   Verify SPB New Balance     ${billing_account_id}     ${spb_balance_expected}
    
    # netcracker numbers are multiplied by 1000
    ${nc_balances}   Get Netcracker Payments   ${billing_account_id}
    ${converted_spb_balance_after}  Evaluate   ${spb_balance_after}*-1000
    Should Be Equal As Numbers  ${converted_spb_balance_after}   ${nc_balances}[account][0][1]   Netcracker account table total_paid_tot does not equal SPB balance
    
    ${converted_refund}   Evaluate   ${refund_amount}*-1000
    
    # accountpayment and physicalpayment filtered for payments made today
    ${account_payments}  Set Variable  ${nc_balances}[accountpayment]
    ${account_payment_result}   bep_common.findMatchInListOfLists   ${account_payments}  0   ${converted_refund}
    Should Be Equal As Strings   ${account_payment_result}   True
    ${physical_payments}  Set Variable  ${nc_balances}[physicalpayment]
    ${physical_payment_result}   bep_common.findMatchInListOfLists   ${physical_payments}  0   ${converted_refund}
    Should Be Equal As Strings   ${physical_payment_result}   True
    
Modify Recurring Payment Method And Verify NC Update
    [Documentation]  Change an existing payment method to be the recurring payment method and verify NC update. ${customer_ref} should be a suite variable
    [Arguments]   ${payment_id}   ${payment_method}

    ${pof_inputs}   Create Dictionary   id=${payment_id}    useforRecurringPayment=True
    Update Payment On File  ${pof_inputs}
    Set Suite Variable   ${new_recurring_payment_method}   ${payment_method}
    
    # we need the id used in the prmandate table
    ${expected_old_payment_method_id}  Get NC Id For Payment Method   ${VPS_RECURRING_PAYMENT_METHOD}
    ${expected_new_payment_method_id}  Get NC Id For Payment Method   ${payment_method}

    ${date}    Get Current Date
    ${date}    Convert Date	   ${date}	 result_format=%Y-%m-%d
    ${expected_new_prmandate}  Create Dictionary    payment_method_id=${expected_new_payment_method_id}    active_to_dat=None   mandate_status=2   mandate_attr_1=${customer_ref} 
    ${expected_old_prmandate}  Create Dictionary    payment_method_id=${expected_old_payment_method_id}    active_to_dat=${date}   mandate_status=2   mandate_attr_1=${customer_ref}      
    ${nc_result}   Wait Until Keyword Succeeds   2x   5s    Verify Payment Mandate Change In NC   ${billing_account_id}     ${expected_old_prmandate}  ${expected_new_prmandate}
    ${spb_result}   Wait Until Keyword Succeeds   2x   5s    Verify SPB Recurring Payment Method   ${billing_account_id} 
  
Add New Recurring Payment Method And Verify NC Update
    [Documentation]   add a new recurring payment on file and verify that SPB updates payment method from getBillingAccount and NC adds entry to prmandate table 
    ...  Suite variables are ${billing_account_id}   ${VPS_RECURRING_PAYMENT_METHOD}   ${customer_ref}
    #Set Suite Variable   ${billing_account_id}  5000012758
    #Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}  Visa
    #Set Suite Variable   ${customer_ref}   2526caac-7e29-4597-b7bd-28b3ad2996c8
    #Sleep   10s
    ${spb_before}   Get Billing Account From SPB   ${billing_account_id}
    Log   SPB BEFORE=${spb_before}  
    ${nc_before}    Get Prmandate Table From NC    ${billing_account_id}
    # add a different payment method than the one just deleted
    ${all_methods}   copy.deepcopy   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PAYMENT_METHODS]
    Remove Values From List   ${all_methods}   ${VPS_RECURRING_PAYMENT_METHOD}     CustBankTransfer
    ${method}    Evaluate  random.choice($all_methods)  random
    #${method}   Set Variable  SEPA
    Set Suite Variable   ${new_recurring_payment_method}   ${method}
    # following sets suite variable ${rb_payment_method_id} and ${create_prmandate}
    Add Recurring Payment Method To VPS    ${customer_ref}   ${method}
    Set Suite Variable   ${expected_old_payment_method_id}   ${rb_payment_method_id}

    ${new_create_prmandate}    ${expected_new_payment_method_id}   ${dontcare}     Retrieve Payment Type Info    ${new_recurring_payment_method}

    ${date}    Get Current Date
    ${date}    Convert Date	   ${date}	 result_format=%Y-%m-%d
    ${expected_new_prmandate}  Create Dictionary    payment_method_id=${expected_new_payment_method_id}    active_to_dat=None   mandate_status=2   mandate_attr_1=${customer_ref} 
    ${expected_old_prmandate}  Create Dictionary    payment_method_id=${expected_old_payment_method_id}    active_to_dat=${date}   mandate_status=2   mandate_attr_1=${customer_ref}    
    ${nc_result}   Wait Until Keyword Succeeds   4x   5s    Verify Payment Mandate Change In NC   ${billing_account_id}     ${expected_old_prmandate}  ${expected_new_prmandate}
    ${spb_result}   Wait Until Keyword Succeeds   4x   5s    Verify SPB Recurring Payment Method   ${billing_account_id} 
  
 Remove Recurring Payment Method And Verify NC Update
    [Documentation]   Delete the recurring payment on file and verify that SPB removes payment method from getBillingAccount and NC updates entry in prmandate table
    ...   uses suite variables ${billing_account_id}, ${customer_ref} 
    Set Suite Variable   ${billing_account_id}   5000012758
    Set Suite Variable   ${customer_ref}    2526caac-7e29-4597-b7bd-28b3ad2996c8
    ${spb_before}   Get Billing Account From SPB   ${billing_account_id}
    Log   SPB BEFORE=${spb_before}   
    ${nc_before}    Get Prmandate Table From NC    ${billing_account_id}
    ${pof}   Query Payment On File    ${customer_ref}
    Log   ${pof} 
    Set Test Variable   ${recurringPayment_id}    ${pof}[pofDetails][0][id]
    ${pofs}   Set Variable  ${pof}[pofDetails]
    :FOR  ${payment}  IN   @{pofs}
    \   Run Keyword If  '${payment}[useForRecurringPayment]'=='True'   Set Test Variable   ${recurringPayment_id}   ${payment}[id]
    \   Exit For Loop If  '${payment}[useForRecurringPayment]'=='True'
    Log  ${recurringPayment_id}
    Log   ${billing_account_id}
    # as of 10/11/2019 prmandate is not updated upon cc deletion
    #Delete VPS Payment On File    ${recurring_payment_id}
    #Sleep   12s
    # Add verifications here when implemented by SPB and NC