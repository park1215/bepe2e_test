*** Settings ***
Documentation    Tests VPS notification on changes to payment on file
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     copy
Library     ../../common/common_library.py
Resource    ../../common/bep/om/om_resource.robot
Resource    ../../common/bep/fo/fo_resource.robot
Resource    ../../common/bep/ira/ira_resource.robot
Resource    ../../common/bep/psm/psm_resource.robot
Resource    ../../common/bep/pom/pomresource.robot
Resource    ../../common/bep/spb/spb_resource.robot
Resource    ../../common/vps/vps_resource.robot
Variables   ../../python_libs/bep_parameters.py
Library     ../../python_libs/sql_libs.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
${buyer_id}

*** Test Cases ***
NCS With Random OTP And Recurring Payments
    [Documentation]  new customer sign up with OTP as CC and recurrring as same CC
    [Tags]    ncs
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    Set Suite Variable   ${expected_vps_recurring_payment_method}
    Set Suite Variable   ${expected_vps_payment_method}
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Test Variable    ${advance_payment}
    ${discount_prod_type_id}   ${contract_prod_type_id}    Get Discount And Contract Product Type Ids    ${offers}    ${selected_offer_id}

    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    ${high_level_spb_category}   ${discount_spb_price_category}  ${contract_spb_price_category}    Get Cart Item Id And SPB categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}

    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    ${returned_email}  ${returned_address}  ${returned_phone_number}  ${tin_external_id}  ${reln_id}  Add And Get Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${ADDRESS_LINE}    ${CITY}   ${STATE}   ${POSTAL_CODE}   ${PHONE_NUMBER}
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}
    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Suite Variable  ${customer_ref}   ${reln_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

    ${vps_request_payment_transaction_id}   copy.deepcopy   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}   txnAmount=${advance_payment}   txnType=Authorize
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}    
    Set Suite Variable   ${payment_transaction_id}
     
    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}
    Set Suite Variable   ${one_time_payment_id}
    Set Suite Variable   ${recurring_payment_id}


    #Add Billing Account To SPB
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
    Set Suite Variable  ${billing_account_id}

    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}
    ${auth_dict}   Create Dictionary  paymentOnFileId=${one_time_payment_id}
    Authorize Payment Method    ${auth_dict}
    
    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}    Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}

    @{product_instance_ids}    ${discount_product_instance_id}    ${contract_product_instance_id}    Get And Validate Product Instance Ids From PSM    ${product_instance_id}   ${billing_account_id}   ${discount_prod_type_id}    ${contract_prod_type_id}

    ${pi_file_location_id}    Get SPB PII File Location Id

    #Get OM SNS Event
    ${start_state}    ${end_state}    ${message}    Get Event From OM SNS    ${om_order_id}
    Log    OrderLifecycleEvent is: ${message}

    #Get PSM SNS Event For Accepted State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Accepted State   ${billing_account_id}    ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    PENDING    ${billing_account_id}
    ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}    Run Keyword And Continue On Failure    Get Product Id And Tariff Id For Main Product    ${offer_name}
    Log     ${main_product_tariff_id}, ${contract_tariff_id}, ${discount_tariff_id}, ${main_product_id}, ${contract_product_id}, ${discount_product_id}

    ${product_pid_mapping}    Run Keyword And Continue On Failure    CreatePIDMappingForMainAndSubProducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}  ${product_instance_id}  ${contract_product_instance_id}  ${discount_product_instance_id}  ${INTERNET_KIND}  ${CONTRACT_KIND}  ${DISCOUNT_KIND}  ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${high_level_spb_category}  ${contract_spb_price_category}  ${discount_spb_price_category}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}
    Log    ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Pending State
    Set Test Variable    ${expected_row_count}   10
    Run Keyword And Continue On Failure    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}
    Run Keyword And Continue On Failure    Validate Payment Method Id In NC DB   ${billing_account_id}    ${expected_vps_recurring_payment_method}

    Submit Sale To VPS    ${one_time_payment_id}

    Add One Time Payment To SPB    ${payment_transaction_id}   ${billing_account_id}

    Request PI Life Cycle State Change To Active    ${product_instance_id}

    #Get PSM SNS Event For Active State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Active State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

    #Get Product Instances For Active State From SPB
    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    ACTIVE    ${billing_account_id}

    #Perform Netcracker Validations For Active State
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}
    
    Set Suite Variable  ${product_instance_id}
    Set Suite Variable  ${product_instance_ids}
    Set Suite Variable  ${pi_file_location_id}
    Set Suite Variable   ${discount_spb_price_category}
    Set Suite Variable   ${contract_spb_price_category}
    Set Suite Variable    ${contract_product_instance_id}
    Set Suite Variable    ${high_level_spb_category}
    
Change PI Life Cycle State To SUSPENDED
    [Documentation]   Change the PI life cycle state to SUSPENDED
    [Tags]   suspend
    Request PI Life Cycle State Change To Suspended    ${product_instance_id}

Get PSM SNS Event For Suspended State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product upserted in OM
    [Tags]     suspend
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Suspended State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}
    
Add New Recurring Payment Method
    [Documentation]   add a new recurring payment on file and verify that SPB updates payment method from getBillingAccount and NC adds entry to prmandate table 
    [Tags]   vps    pof  addnew
    Log To Console   Billing account = ${billing_account_id}
    Log To Console   Press enter to continue
    bep_common.waitForInput
    #Set Suite Variable   ${billing_account_id}  5000012999
    #Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}  Visa
    #Set Suite Variable   ${customer_ref}   16bc4304-487d-4e3b-8a37-555988630766
    Sleep   10s
    Add New Recurring Payment Method And Verify NC Update
    
Modify OTP Payment To Be Recurring
    [Documentation]  Change the OTP to be the recurring payment method and verify NC update. 
    [tags]   vps  pof   modify 
    Modify Recurring Payment Method And Verify NC Update     ${one_time_payment_id}   ${expected_vps_payment_method}
  
Refund Payment
    [Documentation]  Request refund from VPS for the OTP and verifies SPB notifies NC and NC updates tablestest06
    [tags]   vps   refund

    #${payment_transaction_id}  Set Variable  a058E00000A0fZQQAZ
    #${billing_account_id}   Set Variable   5000012999
    
    ${spb_before}   Get Billing Account From SPB   ${billing_account_id}
    ${spb_balance_before}    Set Variable   ${spb_before}[currentBalance][value]
    ${spb_balance_before}   Convert To Number  ${spb_balance_before}
    # use random percentage from 1 to 50% of existing balance    
    ${random} 	Evaluate	random.randint(1, 50)	random
    ${refund_amount}   Evaluate   -1*${spb_balance_before}*${random}/100
    ${refund_amount}   Convert To Number  ${refund_amount}   2
    Log To Console      REFUND ${refund_amount}
    
    Refund Payment And Verify NC Update   ${payment_transaction_id}   ${refund_amount} 

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    Set Country Specific Variables
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    Create PSM SQS Queue
    Create OM SQS Queue
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}    WARN
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}    WARN
    ${result}    usePomApi  getVersion
    Log    OFM Preprod Version: ${result}    WARN
    
Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    Delele PSM Queue
    Delele OM Queue

