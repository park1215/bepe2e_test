*** Settings ***
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
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
${buyer_id}

*** Test Cases ***
NCS With Random OTP And Recurring Payments
    [Documentation]  new customer sign up with OTP as CC and recurrring as same CC
    [Tags]    ncs   test
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    ${one_time_payment_method}   Set Suite Variable  ${expected_vps_payment_method}
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}

    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}

    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}

    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}

    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    # FOLLOWING CREATES A SUITE VARIABLE ${spb_price_dict} as well as creates suite variables ${high_level_spb_category}  ${contract_spb_price_category} 
    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}   ${child_prod_kinds}

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}


    ${otc_from_cart}    Get OTC Price From Cart    ${cart_id}
    
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}    ${otc_from_cart} 
    Set Test Variable    ${advance_payment}
    
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    Set Suite Variable   ${party_id}
    ${returned_email}  ${returned_address}  ${returned_phone_number}  ${tin_external_id}  ${reln_id}  Add And Get Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${ADDRESS_LINE}
    ...   ${CITY}   ${STATE}   ${POSTAL_CODE}   ${PHONE_NUMBER}
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}

    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Test Variable  ${customer_ref}   ${reln_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

    ${vps_request_payment_transaction_id}   copy.deepcopy   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}   txnAmount=${advance_payment}   txnType=Sale
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}

    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}

    #Add Billing Account To SPB
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
    Set Test Variable  ${billing_account_id}
 
    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}
    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}
    ...   Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}

    #  This also creates suite variable, dictionary ${prod_instance_dict}
    @{product_instance_ids}    Get And Validate All Product Instance Ids From PSM    ${product_instance_id}   ${billing_account_id}   ${child_prod_kinds}

    ${pi_file_location_id}    Get SPB PII File Location Id
    #Get OM SNS Event
    ${start_state}    ${end_state}    ${message}    Run Keyword And Continue On Failure    Get Event From OM SNS    ${om_order_id}
    Log    OrderLifecycleEvent is: ${message}

    #Get PSM SNS Event For Accepted State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get all product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Accepted State   ${billing_account_id}    ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

    Set Test Variable      ${subscription_id}   None
    Set Test Variable      ${nc_customer_ref}   None

    ${nc_ids}   Run Keyword  Get Product Id And Tariff Id For Generic Main Product  ${offer_name}
    Log    ${nc_ids}

    #  ${nc_ids}  has product_id and tariff_id, ${spb_price_dict} has xxx_spb_price_category, KIND variables are in country_variables
    ${product_pid_mapping}   Create Generic PID Mapping For Main And Subproducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}   ${product_instance_id}
    ...   ${high_level_spb_category}  ${nc_ids}   ${spb_price_dict}

    Log    ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Pending State
    Set Test Variable    ${expected_row_count}   10
    Run Keyword And Continue On Failure    Validate Payment Method Id In NC DB   ${billing_account_id}    ${expected_vps_recurring_payment_method}

    Run Keyword If   '${submit_sale_bool}'=='true'  Submit Sale To VPS    ${one_time_payment_id}

    Run Keyword If   '${submit_sale_bool}'=='true'  Add One Time Payment To SPB    ${payment_transaction_id}   ${billing_account_id}
 
    Request PI Life Cycle State Change To Active    ${product_instance_id}

    #Get PSM SNS Event For Active State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Active State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

    #Get Product Instances For Active State From SPB
    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    ACTIVE    ${billing_account_id}
    ${product_pid_mapping}    updateProductPidMappingWithSubscriptionCustomerInfo    ${subscription_id}  ${nc_customer_ref}   ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Active State
    Set Test Variable    ${expected_row_count}   10

    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}

    ${otcs}  Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]
    :FOR  ${otc}  IN   @{otcs.keys()}
    \   Verify OTC From NC DB    ${billing_account_id}    ${otc_from_cart}   ${otcs}[${otc}][name]
    
    # Verify next bill date from getBillingAccount is correct
    ${day_of_month}   Get Current Date   UTC   result_format=%d
    Verify Next Bill Date   ${billing_account_id}  ${day_of_month}
    Wait For Order State To Be Updated    ${om_order_id}    Closed

NCS With Random Plan Selection And Change Plan Selection
    [Documentation]  new customer sign up with Random Plan Selection And Change Plan Selection
    [Tags]    ncs   exclude
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    ${offers}    Get Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${temp_selected_offer_id}   ${temp_selected_name}     Select Random Offer From GetOffers    ${offers}
    @{child_prod_kinds}   Create List    ACTIVATION_FEE    SERVICE_CONTRACT    EQUIPMENT_LEASE_FEE

    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${temp_selected_offer_id}    ${temp_selected_name}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    ${high_level_spb_category}   ${equipment_lease_spb_price_category}  ${contract_spb_price_category}    Get Cart Item Id And SPB categories From Cart For Norway
    ...  ${cart_id}   ${cart_data}  ${temp_selected_offer_id}

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}

    Delete Items From Cart    ${cart_id}    ${cart_item_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}

    ${selected_offer_id}   ${selected_name}    Wait Until Keyword Succeeds    10s    1s    Select New Random Plan      ${offers}    ${temp_selected_offer_id}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Test Variable    ${advance_payment}
    #${discount_prod_type_id}   ${contract_prod_type_id}    Get Discount And Contract Product Type Ids    ${offers}    ${selected_offer_id}

    Add Items In Existing Cart    ${cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}

    Verify Price In Cart For NO    ${cart_id}    ${offer_name}

    ${cart_item_id}    ${high_level_spb_category}   ${equipment_lease_spb_price_category}  ${contract_spb_price_category}    Get Cart Item Id And SPB categories From Cart For Norway
    ...  ${cart_id}   ${cart_data}  ${offer_id}

    #Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}

    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    Set Test Variable    ${party_id}
    ${returned_email}  ${returned_address}  ${returned_phone_number}  ${tin_external_id}  ${reln_id}  Add And Get Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${ADDRESS_LINE}
    ...   ${CITY}   ${STATE}   ${POSTAL_CODE}   ${PHONE_NUMBER}
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}
    #Set Test Variable    ${reln_id}
    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    #Set Test Variable   ${customer_role_id}
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    #Set Test Variable   ${payer_role_id}
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Test Variable  ${customer_ref}   ${reln_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

    ${vps_request_payment_transaction_id}   ${payment_transaction_id}   Initialize Transaction With VPS    ${reln_id}    ${advance_payment}
    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}

    #Add Billing Account To SPB
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
    Set Test Variable  ${billing_account_id}

    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}

    ${om_order_id}    ${product_instance_id}    ${product_type_id}     ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}
    ...   Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}

    @{product_instance_ids}    Get And Validate All Product Instance Ids From PSM    ${product_instance_id}   ${billing_account_id}   ${child_prod_kinds}
    ${activation_fee_product_instance_id}    Get From List    ${product_instance_ids}    1
    ${contract_product_instance_id}    Get From List    ${product_instance_ids}   2
    ${equipment_lease_product_instance_id}    Get From List    ${product_instance_ids}    3
    
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

    Set Test Variable      ${subscription_id}   None
    Set Test Variable      ${nc_customer_ref}   None
    ${main_product_tariff_id}  ${contract_tariff_id}  ${equipment_lease_tariff_id}  ${main_product_id}  ${contract_product_id}  ${equipment_lease_product_id}
    ...  Run Keyword And Continue On Failure    Get Product Id And Tariff Id For Norway Main Product    ${offer_name}
    Log     ${main_product_tariff_id}, ${contract_tariff_id}, ${equipment_lease_tariff_id}, ${main_product_id}, ${contract_product_id}, ${equipment_lease_product_id}

    ${product_pid_mapping}    Run Keyword And Continue On Failure    CreatePIDMappingForMainAndSubProducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}
    ...  ${product_instance_id}  ${contract_product_instance_id}  ${equipment_lease_product_instance_id}  ${INTERNET_KIND}  ${CONTRACT_KIND}  ${EQUIPMENT_LEASE_FEE_KIND}
    ...  ${main_product_tariff_id}  ${contract_tariff_id}  ${equipment_lease_tariff_id}  ${high_level_spb_category}  ${contract_spb_price_category}  ${equipment_lease_spb_price_category}
    ...   ${main_product_id}  ${contract_product_id}  ${equipment_lease_product_id}
 
    Log    ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Pending State
    Set Test Variable    ${expected_row_count}   10
    Run Keyword And Continue On Failure    Validate Payment Method Id In NC DB   ${billing_account_id}    ${expected_vps_recurring_payment_method}
    #Wait For Account Product Update In PG DB     ${billing_account_id}    ${pi_file_location_id}    @{product_instance_ids}
    Run Keyword If   '${submit_sale_bool}'=='True'  Submit Sale To VPS    ${one_time_payment_id}

    Run Keyword If   '${submit_sale_bool}'=='True'  Add One Time Payment To SPB    ${payment_transaction_id}   ${billing_account_id}

    Request PI Life Cycle State Change To Active    ${product_instance_id}

    #Get PSM SNS Event For Active State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Active State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

    #Get Product Instances For Active State From SPB
    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    ACTIVE    ${billing_account_id}
    ${product_pid_mapping}    updateProductPidMappingWithSubscriptionCustomerInfo    ${subscription_id}  ${nc_customer_ref}   ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Active State
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}
    Wait For Order State To Be Updated    ${om_order_id}    Closed

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

Select New Random Plan
    [Arguments]    ${offers}    ${temp_selected_offer_id}
    ${selected_offer_id2}   ${selected_name2}     Select Random Offer From GetOffers    ${offers}
    Should Not Be Equal    ${selected_offer_id2}    ${temp_selected_offer_id}
    [return]    ${selected_offer_id2}   ${selected_name2}
