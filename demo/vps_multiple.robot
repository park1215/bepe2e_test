*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Resource    ../common/bep/om/om_resource.robot
Resource    ../common/bep/fo/fo_resource.robot
Resource    ../common/bep/ira/ira_resource.robot
Resource    ../common/bep/psm/psm_resource.robot
Resource    ../common/bep/pom/pomresource.robot
Resource    ../common/bep/spb/spb_resource.robot
Resource    ../common/vps/vps_resource.robot
Variables   ../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
#${mex_org_id}          fe34ee49-6198-44b0-a96a-baa39bf59175
${cartId}           42ed3fa4-6ac0-4783-859a-e8374588ce51
${buyer_id}
${buyer_name}    BEP Nexus Sprint#2 Customer
${upsert_method}  ''
${relatedParties}   [{id: "", role: "buyer"}, {id: "fe34ee49-6198-44b0-a96a-baa39bf59175", role: "seller"}]
#${location}         {coordinates: {latitude: 28.6, longitude: -106.1}}
#${country_code}       MX
${spain_product_id}       a99aaf0b-4589-419f-83b1-70038d02188b
${cart_name}    BEPE2E's Cart
#${seller_id}    fe34ee49-6198-44b0-a96a-baa39bf59175
${shopping_cart_item}    {id: "0c643357-8c0d-4697-934a-c2efe1da8278", action: "add", cartItems: [{id: "ded0a22d-675d-4e3e-96cc-cdea1ddbf8ff", action: "add", product: {id: "297413e0-d2de-4912-9786-90f561bdd7cb", name: "Equipment Lease Fee - Lifetime"}}]}
${cart_item_id}                d7ccf99f-4f27-44e0-84c9-cc33cc5cb89d
${offer_id}    37977211-824a-4ca8-922a-6fcb8b6dcddd
# for batch payments
${batch_payment_request_prefix}  VPGB_MEX_
${index_13_customer_ref}        unused1
${index_14_account_num}         unused2
${index_17_payment_method_id}   13
${index_35_payment_amount}      1280000
${index_37_payment_request_id}   3000

*** Test Cases ***
Make Payment
    [Documentation]   Get payment transaction id and authorize payment info
    [Tags]   vps  captureResponseTime
    Request Payment Transaction
    Add One Time Payment Method To VPS
    Add Billing Account To SPB
    Modify Payment Transaction Id In VPS
    Submit Sale
    Add One Time Payment
    Verify Account Payment History   ${advance_payment}

Make Payment With Alternate Method
    [Documentation]  Change the payment type and do another OTP
    [Tags]   alt
    ${all_methods}   copy.deepcopy   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PAYMENT_METHODS]
    Remove Values From List   ${all_methods}   ${VPS_PAYMENT_METHOD}    CustBankTransfer
    ${method}    Evaluate  random.choice($all_methods)  random
    Set Suite Variable   ${VPS_PAYMENT_METHOD}   ${method}
 
    Request Payment Transaction
    Add One Time Payment Method To VPS
    Modify Payment Transaction Id In VPS
    Submit Sale
    Add One Time Payment   False
    Verify Account Payment History    ${advance_payment}
    
Refund Part Of Payment
    [Documentation]   Refund part of most recent payment
    [Tags]   refund
    ${random}=	 Evaluate	${advance_payment}*random.randint(1,100)/100   	modules=random
    ${refund_amount}   Convert To Number   ${random}   2
    Log To Console  REFUND=${refund_amount}
    Refund Payment And Verify NC Update  ${payment_transaction_id}   ${refund_amount}
    ${refund_amount}   Evaluate  -1* ${refund_amount}
    Wait Until Keyword Succeeds  3x  5s  Verify Account Payment History   ${refund_amount}
    
*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    ${otp_method}   ${rec_method}   Set And Get Payment Methods
    Set Country Specific Variables
    Log To Console  vps instance = ${VPS_INSTANCE}
    Set Suite Variable  ${VPS_PAYMENT_METHOD}   ${otp_method}
    Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}   ${rec_method}
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    
    # Create individual
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    Set Suite Variable    ${party_id}
    ${response}    Add Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${billing_address}    ${PHONE_NUMBER}
    ${returned_email}=   Set Variable    ${response}[data][id1][email]
    ${returned_address}=   Set Variable    ${response}[data][id2][address]
    ${returned_phone_number}=   Set Variable    ${response}[data][id3][phoneNumber]
    ${tin_external_id}=   Set Variable    ${response}[data][id4][value]
    ${reln_id}=   Set Variable    ${response}[data][id5][relnId]
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}
    Set Suite Variable    ${reln_id}
    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    Set Suite Variable   ${customer_role_id}
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    Set Suite Variable   ${payer_role_id}
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Suite Variable  ${customer_ref}   ${reln_id}    

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@

Request Payment Transaction
    ${vps_request_payment_transaction_id}   Create Dictionary
    ${txnAmount}=	 Evaluate	random.randint(0,10000)/100   	modules=random
    ${txnAmount}   Convert To Number   ${txnAmount}   2
    
    ${vps_request_payment_transaction_id}   copy.deepcopy   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    #:FOR    ${key}    IN    @{VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS.keys()}
    #\   Set To Dictionary  ${vps_request_payment_transaction_id}   ${key}=${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}[${key}]
    
    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}   txnType=Sale    txnAmount=${txnAmount}
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}
    ${paymentRetrieve Payment}  Retrieve Payment Transaction Id   ${payment_transaction_id}
    Log   Payment Transaction Info = ${paymentRetrieve Payment}
    Set Suite Variable   ${advance_payment}   ${txnAmount}

Add One Time Payment Method To VPS
    ${one_time_payment_id}   Request New Payment On File   ${customer_ref}   ${VPS_PAYMENT_METHODS}[${VPS_PAYMENT_METHOD}]
    Log   one_time_payment id=${one_time_payment_id}
    Set Suite Variable   ${one_time_payment_id}
    Log    ${vps_request_payment_transaction_id}

Add Billing Account To SPB
    Set Suite Variable  ${customer_ref}   ${reln_id}
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}   ${VPS_RECURRING_PAYMENT_METHOD}
    Set Suite Variable  ${billing_account_id}

Modify Payment Transaction Id In VPS
    &{billing_info}   Create Dictionary  billingAccount=${billing_account_id}
    Set To Dictionary   ${vps_request_payment_transaction_id}   additionalDetails=${billing_info}
    Log    ${vps_request_payment_transaction_id}
    Modify VPS Payment Transaction Id   ${vps_request_payment_transaction_id}

Submit Sale
    ${vps_sale}   Create Dictionary   paymentOnFileId=${one_time_payment_id} 
    VPS Sale   ${vps_sale}
    ${paymentRetrieve Payment}  Retrieve Payment Transaction Id   ${payment_transaction_id}
    Log   ${paymentRetrieve Payment}
    
Add One Time Payment
    [Arguments]   ${first_time_payment}=True
    ${result}   useSpbApi   addOneTimePayment   ${payment_transaction_id}    ${PAYMENT_REFERENCE_TYPE}[${VPS_INSTANCE}]
    ${status}   ${message}    Should Be True   ${result}[0]
    ${status}   ${message2}     Should Not Contain   ${result}[1]   errors    ${message}
    Log  ${result}
    Verify Account Balance   ${billing_account_id}   ${first_time_payment}

Verify Account Payment History
    [Arguments]   ${amount}
    Get PR Mandate Presence and RB Payment Method Id   ${billing_account_id}
    Verify SPB Account Payment History   ${billing_account_id}  ${amount}   ${VPS_PAYMENT_METHOD}

