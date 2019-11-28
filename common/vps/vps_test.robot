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
*** Variables ***
 

*** Test Cases ***
Add Individual & Relationship To IRA
    [Documentation]  SW  Create a new party in IRA with certain Name & Group Association step 4-6
    [Tags]    IRA  captureResponseTime
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
    
Initialize Transaction With VPS
    [Documentation]   Get payment transaction id and authorize payment info
    [Tags]   vps  captureResponseTime
    Set Suite Variable  ${customer_ref}   ${reln_id}
    ${vps_request_payment_transaction_id}   Create Dictionary
    # deepcopy doesn't seem to work
    :FOR    ${key}    IN    @{VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS.keys()}
    \   Set To Dictionary  ${vps_request_payment_transaction_id}   ${key}=${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}[${key}]

    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}
    ${paymentRetrieve Payment}  Retrieve Payment Transaction Id   ${payment_transaction_id}
    Log To Console   Payment Transaction Info = ${paymentRetrieve Payment}
    Set Suite Variable   ${advance_payment}   ${txnAmount}

Add One Time Payment Method To VPS
    [Documentation]   Add a payment method for the first payment only
    [Tags]   vps  captureResponseTime   
    ${one_time_payment_id}   Request New Payment On File   ${customer_ref}   ${VPS_PAYMENT_METHODS}[${VPS_PAYMENT_METHOD}]
    Log To Console   one_time_payment id=${one_time_payment_id}
    Set Suite Variable   ${one_time_payment_id}
    Log To Console    ${vps_request_payment_transaction_id}

Update Payment
    ${new_params}   Create Dictionary   useAsDefault=False  useForRecurringPayment=False  id=${one_time_payment_id}   ccExpYear=2021
    ${result}   useVpsApi   updatePaymentOnFile   ${new_params}   ${vps}

Retrieve Payment On File From VPS
    ${pof}   Retrieve Payment On File    ${one_time_payment_id}
    Log To Console  ${pof}
    
Delete One Time Payment Method In VPS
    [Tags]   
    ${input_dict}   Create Dictionary    id=${one_time_payment_id}
    ${result}   useVpsApi   deletePaymentOnFile   ${input_dict}   ${vps}
    Log To Console  ${result}
 
 Attempt To Retrieve Payment On File From VPS 
    ${pof}   Retrieve Payment On File    ${one_time_payment_id}
    Log To Console  ${pof}
      
*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    ${otp_method}   ${rec_method}   Set and Get Payment Methods
    Set Suite Variable  ${VPS_PAYMENT_METHOD}   ${otp_method}
    Set Country Specific Variables
    ${response}   ${vps}   useVpsApi   initialize
    Should Be True  ${response}
    Set Suite Variable  ${vps}    