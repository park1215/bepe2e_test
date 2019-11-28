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
NCS And SISA With Ilimitada 30
    [Documentation]  New customer sign up with Ilimitada 30 plan and activate satellite service
    [Tags]    ncs
    # Get Offers and offer validation
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    Set Suite Variable    ${existing_vps_recurring_payment_method}    ${expected_vps_recurring_payment_method}
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    Set Test Variable    ${offer_id}    16b58ac6-872f-457a-b5aa-a742a5dacb5f
    Set Test Variable    ${offer_name}    Ilimitada 30
    # PAtsing spb categories, product type ids and advance payment
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
    ${start_state}    ${end_state}    ${message}    Get Event From OM SNS    ${om_order_id}
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

Downgrade To Classica 30 With Existing Customer With Future Order
    [Documentation]  Existing customer from Test #1 downgrading to classica 30 with future order
    [Tags]     ncs
    #${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    ${offers}    Get Offers From POM    ${existing_customer_payer_role_id}    ${SELLER_ID}    ${country_code}
    Set Test Variable    ${offer_id}    a99aaf0b-4589-419f-83b1-70038d02188b
    Set Test Variable    ${offer_name}    Clásica 30
    Set Suite Variable    ${new_offer_name}    ${offer_name}
   # ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    #Set Test Variable    ${advance_payment}
    ${discount_prod_type_id}   ${contract_prod_type_id}    Get Discount And Contract Product Type Ids    ${offers}    ${offer_id}
    Set Suite Variable    ${discount_prod_type_id}
    Set Suite Variable    ${contract_prod_type_id}

    ${cart_id}    Add Cart With Item And Verify Cart    ${existing_customer_payer_role_ids}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    ${high_level_spb_category}   ${discount_spb_price_category}  ${contract_spb_price_category}    Get Cart Item Id And SPB categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}
    Set Suite Variable    ${high_level_spb_category}
    Set Suite Variable    ${discount_spb_price_category}
    Set Suite Variable    ${contract_spb_price_category}
    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

    #${vps_request_payment_transaction_id}   ${payment_transaction_id}   Initialize Transaction With VPS    ${existing_customer_reln_id}    ${advance_payment}
    #${one_time_payment_id}    Add One Time Payment Method To VPS   ${existing_customer_reln_id}   ${expected_vps_payment_method}


    #Modify Payment Transaction Id In VPS    ${existing_customer_billing_account_id}    ${vps_request_payment_transaction_id}
    ${future_date_time}    generateFutureDatetime    minutes    5
    Log    ${future_date_time}
    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}    Create And Upsert Order To OM    ${existing_customer_reln_id}    ${cart_id}    ${cart_item_id}    ${existing_customer_billing_account_id}    ${future_date_time}
    Should Contain    ${order_state}    Scheduled
    Set Suite Variable    ${new_om_order_id}    ${om_order_id}


    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${old_product_instance_id}    ACTIVE    ${existing_customer_billing_account_id}


    #Perform Netcracker Validations For Active State
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${existing_customer_billing_account_id}   ${old_product_pid_mapping}   OK   ${expected_row_count}
    Validate Payment Method Id In NC DB   ${existing_customer_billing_account_id}    ${existing_vps_recurring_payment_method}


Cancel In Flight For Different Order
    [Documentation]  New customer sign up with randomly selected plan and then cancel order
    [Tags]    cifo
    Select Random Offer From POM As Anonymous User
    Add Selected Plan To Cart And validate OFM
    Add Customer And Relationships To IRA
    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${VPS_RECURRING_PAYMENT_METHOD}
    Set Test Variable  ${billing_account_id}
    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}    Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}
    Set Test Variable    ${om_order_id}
    Set Test Variable    ${product_instance_id}
    Set Test Variable    ${product_type_id}
    Get Product Instance Ids From PSM For Upserted Order
    Get And Verify OM SNS Event
    Get And Verify PSM SNS Event
    Get Product Instances From SPB For Accepted State
    Netcracker Validations For Pending State
    Cancel In Flight Order
    Get And Verify OM SNS Event For Cancelled Order
    Get And Verify Product Instance Ids From PSM For Cancelled Order
    Get And Verify PSM SNS Event For Cancelled Order
    Run Keyword And Continue On Failure    Get And Verify Product Instances For Cancelled State From SPB
    Validate Billing Account State From SPB      ${billing_account_id}     Active
    Netcracker Validations For Cancelled Product


Validate New Downgraded Plan Is Processed But Not Activated
    [Documentation]  New customer sign up with randomly selected plan and then cancel order
    [Tags]    future-order    ncs
    Wait For Order To Be Processed     ${new_om_order_id}
    ${result}    Get OM Order    ${new_om_order_id}
    ${new_product_instance_id}    Parse Top Level Product Instance Id From OM    ${result}

    @{product_instance_ids}    ${discount_product_instance_id}    ${contract_product_instance_id}    Get And Validate Product Instance Ids From PSM    ${new_product_instance_id}   ${existing_customer_billing_account_id}   ${discount_prod_type_id}    ${contract_prod_type_id}

    ${pi_file_location_id}    Get SPB PII File Location Id

    #Get OM SNS Event
    ${start_state}    ${end_state}    ${message}    Get Event From OM SNS For Given State    ${new_om_order_id}    Scheduled    Processed
    #Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
    Log    OrderLifecycleEvent is: ${message}

    #Get PSM SNS Event For Accepted State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Accepted State   ${existing_customer_billing_account_id}    ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${new_product_instance_id}    PENDING    ${existing_customer_billing_account_id}
    ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}    Run Keyword And Continue On Failure    Get Product Id And Tariff Id For Main Product    ${new_offer_name}
    Log     ${main_product_tariff_id}, ${contract_tariff_id}, ${discount_tariff_id}, ${main_product_id}, ${contract_product_id}, ${discount_product_id}

    ${product_pid_mapping}    Run Keyword And Continue On Failure    CreatePIDMappingForMainAndSubProducts  ${existing_customer_billing_account_id}  ${subscription_id}  ${nc_customer_ref}  ${new_product_instance_id}  ${contract_product_instance_id}  ${discount_product_instance_id}  ${INTERNET_KIND}  ${CONTRACT_KIND}  ${DISCOUNT_KIND}  ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${high_level_spb_category}  ${contract_spb_price_category}  ${discount_spb_price_category}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}
    Log    ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Pending State
    Set Test Variable    ${expected_row_count}   10
    Run Keyword And Continue On Failure    Verify Products From NC DB    ${existing_customer_billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}    ${subscription_id}

    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${old_product_instance_id}    ACTIVE    ${existing_customer_billing_account_id}

    #Perform Netcracker Validations For Active State
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${existing_customer_billing_account_id}   ${old_product_pid_mapping}   OK   ${expected_row_count}



*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    Set Country Specific Variables
    Log   Configure suite variables here@
   ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    Log To Console  service plan=${service_plan}
    Create PSM SQS Queue
    Create OM SQS Queue
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}    WARN
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}    WARN

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    Delele PSM Queue
    Delele OM Queue

Select Random Offer From POM As Anonymous User
    [Documentation]  Gets the offers first and  randomly selects any offer
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Test Variable   ${advance_payment}
    Log    ${advance_payment}, ${advance_payment_description}
    ${products}   Parse Products From Offers For Specific Plan    ${offers}    ${selected_offer_id}
    ${discount_prod_type_id}    Get Product Type Id From POM    ${products}    ${DISCOUNT_KIND}
    Set Test Variable        ${discount_prod_type_id}
    ${contract_prod_type_id}    Get Product Type Id From POM    ${products}    ${CONTRACT_KIND}
    Set Test Variable        ${contract_prod_type_id}

Add Selected Plan To Cart And validate OFM
    [Documentation]  Create an empty cart and add randomly selected/given offer in the cart
    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    Set Test Variable    ${cart_id}
    Log    NEW CART ID is ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    Set Test Variable    ${cart_item_id}
    ${high_level_spb_category}    Get SPB Category For Top Level Product    ${cart_id}
    Set Test Variable    ${high_level_spb_category}
    Log    ${high_level_spb_category}
    ${discount_spb_price_category}    ${discount_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${DISCOUNT_KIND}
    Set Test Variable    ${discount_spb_price_category}
    Log    ${discount_spb_price_category}, ${discount_spb_price_category_duration}
    ${contract_spb_price_category}    ${contract_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${CONTRACT_KIND}
    Set Test Variable    ${contract_spb_price_category}
    Log    ${contract_spb_price_category}, ${contract_spb_price_category_duration}

Add Customer And Relationships To IRA
    [Documentation]  Add customer info in IRA
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    Set Test Variable    ${party_id}
    ${response}    Add Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${billing_address}   ${PHONE_NUMBER}
    ${returned_email}=   Set Variable    ${response}[data][id1][email]
    ${returned_address}=   Set Variable    ${response}[data][id2][address]
    ${returned_phone_number}=   Set Variable    ${response}[data][id3][phoneNumber]
    ${tin_external_id}=   Set Variable    ${response}[data][id4][value]
    ${reln_id}=   Set Variable    ${response}[data][id5][relnId]
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}
    Set Test Variable    ${reln_id}
    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    Set Test Variable   ${customer_role_id}
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    Set Test Variable   ${payer_role_id}
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Test Variable  ${customer_ref}   ${reln_id}

Get Product Instance Ids From PSM For Upserted Order
    [Documentation]   Get Product Instance Ids From PSM For Upserted Order
    ${result}   Get PSM Instance   ${product_instance_id}
    Log   ${result}
    @{product_instance_ids}    Get Child Product Instance Ids From Response   ${result}    ${product_instance_id}
    Set Test Variable     @{product_instance_ids}
    Log   ${product_instance_ids}
    ${billing_Account_from_psm}    Get Billing Account From PSM    ${result}
    Should Be Equal    ${billing_Account_from_psm}    ${billing_account_id}
    ${discount_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${discount_prod_type_id}
    Log    ${discount_product_instance_id}
    Set Test Variable    ${discount_product_instance_id}
    ${contract_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${contract_prod_type_id}
    Log    ${contract_product_instance_id}
    Set Test Variable    ${contract_product_instance_id}
    ${pi_file_location_id}    Get SPB PII File Location Id
    Set Test Variable    ${pi_file_location_id}

Get And Verify OM SNS Event
    [Documentation]   Get the NewOrder event for the product uspserted in OM
    Log   order ID from OM is: ${om_order_id}
    ${start_state}    ${end_state}    ${message}    Get Event From OM SNS    ${om_order_id}
    Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
    Log    OrderLifecycleEvent is: ${message}

Get And Verify PSM SNS Event
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Accepted State   ${billing_account_id}    ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances From SPB For Accepted State
    [Documentation]  Get Product Instances from SPB
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    PENDING
    ${subscription_id}    Parse Subscription Id From Get PI Response    ${result}
    ${nc_customer_ref}    Get Customer Ref From NC DB    ${billing_account_id}
    ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}    Get Product Id And Tariff Id For Main Product    ${offer_name}
    Log     ${main_product_tariff_id}, ${contract_tariff_id}, ${discount_tariff_id}, ${main_product_id}, ${contract_product_id}, ${discount_product_id}
    Set Test Variable        ${main_product_tariff_id}
    ${product_pid_mapping}    CreatePIDMappingForMainAndSubProducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}  ${product_instance_id}  ${contract_product_instance_id}  ${discount_product_instance_id}  ${INTERNET_KIND}  ${CONTRACT_KIND}  ${DISCOUNT_KIND}  ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${high_level_spb_category}  ${contract_spb_price_category}  ${discount_spb_price_category}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}
    Log    ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

Netcracker Validations For Pending State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}
    Verify PR Mandate From NC DB    ${billing_account_id}    2
    Wait For Account Product Update In PG DB     ${billing_account_id}    ${pi_file_location_id}    @{product_instance_ids}

Cancel In Flight Order
    [Documentation]   cancel the order
    ${result}    Cancel Order In OM    ${om_order_id}
    Wait For Order To Be Canceled     ${om_order_id}

Get And Verify OM SNS Event For Cancelled Order
    [Documentation]   Get OM SNS for cancelled order
    Log   order ID from OM is: ${om_order_id}
    ${start_state}    ${end_state}    ${message}    Get Event From OM SNS For Given State    ${om_order_id}    Canceling    Canceled
    Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
    Log    OrderLifecycleEvent is: ${message}

Get And Verify Product Instance Ids From PSM For Cancelled Order
    [Documentation]   Get Product Instance Ids From PSM For Cancelled Order
    :FOR  ${individual_pid}  IN  @{product_instance_ids}
    \  Run Keyword And Continue On Failure    Validate PSM State Of Product    ${individual_pid}    CANCELED

Get And Verify PSM SNS Event For Cancelled Order
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product cancelled in OM
    ${event}   Get & Verify Event From PSM SNS For Canceled State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get And Verify Product Instances For Cancelled State From SPB
    [Documentation]  Get Product Instances from SPB
    :FOR  ${individual_pid}  IN  @{product_instance_ids}
    #\  Validate SPB State Of Product    ${individual_pid}    TERMINATED
    \  Run Keyword And Continue On Failure    Wait For Order Status To Be Updated    ${individual_pid}    TERMINATED

Netcracker Validations For Cancelled Product
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   TX   ${expected_row_count}
    Verify PR Mandate From NC DB    ${billing_account_id}    2
