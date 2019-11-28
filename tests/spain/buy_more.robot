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
${buyer_id}

*** Test Cases ***
Verify Buy More Is Supported For Given Plan
    [Documentation]  Verify buy more is selected for a given plan
    [Tags]    OFM    BUYMORE
    Run Keyword And Continue On Failure    Verify Buy More Plans    Clásica 30
    Run Keyword And Continue On Failure    Verify Buy More Plans    Ilimitada 30
    Run Keyword And Continue On Failure    Verify Buy More Plans    Ilimitada 50

Find Existing Customer With Active Plan Of Clásica 30
    [Documentation]   search for active accounts where last name of billing acct starts with Bepe2e_ and plan=Clásica 30
    [Tags]   buymore
    ${to_time}    Get Current Date   UTC   result_format=%Y-%m-%d
    ${candidates}   Locate Active Customers   ES   ${to_time}

    ${acct_list}   Create List
    :FOR   ${acct}   IN   @{candidates}
    \   Convert To List  ${acct}
    \   Run Keyword If   '${acct}[1]'=='Clásica 30'   Append To List  ${acct_list}  ${acct}
    ${accts_length}   Get Length  ${acct_list}
    Should Be True   ${accts_length}>0   

    ${selected_acct}    Evaluate  random.choice($acct_list)  random
    Log   acct = ${selected_acct}   

    Set Suite Variable  ${existing_customer_billing_account_id}   ${selected_acct}[0]

    ${existing_customer_reln_id}   Get Cust Rel Id From Billing Account    ${existing_customer_billing_account_id}
    ${main_product_instance_id}   Get PSM Instance With RelnId    ${existing_customer_reln_id}
    
    Set Suite Variable    ${existing_customer_reln_id}
    Set Suite Variable    ${offer_id}    a99aaf0b-4589-419f-83b1-70038d02188b
    Set Suite Variable    ${offer_name}    Clásica 30
    Set Suite Variable    ${main_product_instance_id} 

Add Buy More Plan To Cart And Upsert Order To OM
    [Tags]   buymore
    ${buymore_offer_id}    ${buymore_offer_name}    Select Random Buy More Plan    ${offer_name}    ${offer_id}
    Set Suite Variable    ${buymore_offer_id}
    Set Suite Variable    ${buymore_offer_name}
    Add Selected Buy More Plan To Cart And Validate OFM
    ${buy_more_om_order_id}    ${buy_more_product_instance_id}    ${buy_more_product_type_id}    ${buy_more_order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}    Create And Upsert Order To OM    ${existing_customer_reln_id}    ${buy_more_cart_id}    ${buy_more_cart_item_id}    ${existing_customer_billing_account_id}
    Set Suite Variable    ${buy_more_om_order_id}
    Set Suite Variable    ${buy_more_product_instance_id}
    Set Suite Variable    ${buy_more_product_type_id}
    Set Suite Variable    ${buy_more_order_state}
    Should Contain    ${buy_more_order_state}    Processed
    Get Product Instance Ids From PSM For Buy More Order

Validate OM And PSM Events For Buy More
    [Tags]   buymore
    ${start_state}    ${end_state}    ${message}    Run Keyword And Continue On Failure    Get Event From OM SNS    ${buy_more_om_order_id}
    Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
    Log    OrderLifecycleEvent is: ${message}
    ${event}   Get & Verify Event From PSM SNS For Buy More   ${existing_customer_billing_account_id}    ${buy_more_pi_file_location_id}     ACCEPTING      ACCEPTED    @{buy_more_product_instance_ids}
    Log    ${event}

Add Relantionship and Change State In PSM
    [Tags]   buymore
    Insert Product Instance Relationship    ${main_product_instance_id}    ${buy_more_product_instance_id}    DEPENDS_ON
    Request PI Life Cycle State Change To Processed    ${buy_more_product_instance_id}

Verify PostGress And Netcracker For Buy More
    [Tags]   buymore
    Run Keyword And Continue On Failure    Wait For OTC Update In NC DB    ${existing_customer_billing_account_id}  ${cart_item_price}   ${buymore_offer_name}   1
    Wait For Account Product Update In PG DB     ${existing_customer_billing_account_id}    ${buy_more_pi_file_location_id}    @{buy_more_product_instance_ids}

*** Comments ***
NCS And SISA With Clásica 30
    [Documentation]  New customer sign up with Ilimitada 30 plan and activate satellite service
    [Tags]    ncs    exclude
    # Get Offers and offer validation
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    Set Suite Variable    ${existing_vps_recurring_payment_method}    ${expected_vps_recurring_payment_method}
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    Set Suite Variable    ${offer_id}    a99aaf0b-4589-419f-83b1-70038d02188b
    Set Suite Variable    ${offer_name}    Clásica 30
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Test Variable    ${advance_payment}
    ${discount_prod_type_id}   ${contract_prod_type_id}    Get Discount And Contract Product Type Ids    ${offers}    ${offer_id}
    # Adding item to the cart and cart validation
    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    ${high_level_spb_category}   ${discount_spb_price_category}  ${contract_spb_price_category}    Get Cart Item Id And SPB categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}
    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}
    # Adding cust info in IRA
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    #Set Test Variable    ${party_id}
    ${returned_email}  ${returned_address}  ${returned_phone_number}  ${tin_external_id}  ${reln_id}  Add And Get Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${ADDRESS_LINE}    ${CITY}   ${STATE}   ${POSTAL_CODE}   ${PHONE_NUMBER}
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}
    #Set Test Variable    ${reln_id}
    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    #Set Test Variable   ${customer_role_id}
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    Set Suite Variable   ${existing_customer_payer_role_id}    ${payer_role_id}
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Test Variable  ${customer_ref}   ${reln_id}
    Set Suite Variable  ${existing_customer_reln_id}   ${reln_id}
    # Changing cart to accepeted
    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED
    ${vps_request_payment_transaction_id}   ${payment_transaction_id}   Initialize Transaction With VPS    ${reln_id}    ${advance_payment}
    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}

    #Add Billing Account To SPB
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
    Set Test Variable  ${billing_account_id}
    Set Suite Variable  ${existing_customer_billing_account_id}    ${billing_account_id}

    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}

    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}    Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}
    Set Suite Variable    ${old_product_instance_id}    ${product_instance_id}
    @{product_instance_ids}    ${discount_product_instance_id}    ${contract_product_instance_id}    Get And Validate Product Instance Ids From PSM    ${product_instance_id}   ${billing_account_id}   ${discount_prod_type_id}    ${contract_prod_type_id}

    ${pi_file_location_id}    Get SPB PII File Location Id
    #Set Test Variable    ${pi_file_location_id}

    #Get OM SNS Event
    ${start_state}    ${end_state}    ${message}    Run Keyword And Continue On Failure    Get Event From OM SNS    ${om_order_id}
    #Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
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
    Set Suite Variable    ${old_product_pid_mapping}    ${product_pid_mapping}

    #Perform Netcracker Validations For Pending State
    Set Test Variable    ${expected_row_count}   10
    Run Keyword And Continue On Failure    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}
    Verify PR Mandate From NC DB    ${billing_account_id}    2
    Validate Payment Method Id In NC DB   ${billing_account_id}    ${expected_vps_recurring_payment_method}

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
    Verify PostGress For Account Products    ${billing_account_id}    ${pi_file_location_id}    @{product_instance_ids}


*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    ${otp_method}   ${rec_method}   Set And Get Payment Methods
    Set Country Specific Variables
    Set Suite Variable  ${VPS_PAYMENT_METHOD}   ${otp_method}
    Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}   ${rec_method}
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    Create PSM SQS Queue
    Create OM SQS Queue
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}
    ${result}    usePomApi  getVersion
    Log    OFM Preprod Version: ${result}    
    
Suite Teardown
    [Documentation]  Restore all resources to original state
    Delele PSM Queue
    Delele OM Queue

Add Selected Buy More Plan To Cart And Validate OFM
    ${buy_more_cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${buy_more_offer_id}    ${buy_more_offer_name}
    Set Test Variable    ${buy_more_cart_id}
    Log    NEW CART ID is ${buy_more_cart_id}
    ${buy_more_cart_data}    Get The Cart Data    ${buy_more_cart_id}
    Log    Cart Data is ${buy_more_cart_data}
    ${buy_more_cart_items}    Get From Dictionary    ${buy_more_cart_data}    cartItems
    ${buy_more_cart_item_id}    Get Cart Item Id from Cart Item List    ${buy_more_cart_items}    ${buy_more_offer_id}
    Set Test Variable    ${buy_more_cart_item_id}
    ${buy_more_high_level_spb_category}    Get SPB Category For Top Level Product    ${buy_more_cart_id}
    Set Suite Variable    ${buy_more_high_level_spb_category}
    Log    ${buy_more_high_level_spb_category}
    Update And Verify Cart Status To Accepted    ${buy_more_cart_id}    ACCEPTED

Get Product Instance Ids From PSM For Buy More Order
    [Documentation]   Get Product Instance Ids From PSM For Upserted Order
    ${result}   Get PSM Instance   ${buy_more_product_instance_id}
    Log   ${result}
    ${buy_more_product_instance_ids} =	Create List    ${buy_more_product_instance_id}
    Log   ${buy_more_product_instance_ids}
    Set Suite Variable    ${buy_more_product_instance_ids}
    ${billing_Account_from_psm}    Get Billing Account From PSM    ${result}
    Should Be Equal    ${billing_Account_from_psm}    ${existing_customer_billing_account_id}
    ${buy_more_pi_file_location_id}    Get SPB PII File Location Id
    Set Suite Variable    ${buy_more_pi_file_location_id}


