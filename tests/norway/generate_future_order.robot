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
NCS With Future Order
    [Documentation]  new customer sign up with future order
    [Tags]     future-order
    #Create S3 Bucket For Future Order
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    Set Test Variable    ${expected_vps_payment_method}
    Set Test Variable    ${expected_vps_recurring_payment_method}
    Select Random Offer From POM As Anonymous User
    Add Selected Plan To Cart And validate OFM
    Add Customer And Relationships To IRA
    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED
    ${cart_data}    Get The Cart Data    ${cart_id}
    
    # Get spb price categories to use in validation phase
    # FOLLOWING CREATES A SUITE VARIABLE ${spb_price_dict} as well as creates suite variables ${high_level_spb_category}  ${contract_spb_price_category} which will be written to file in s3 bucket
    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}   ${child_prod_kinds}
    
    Add One Time And Recurring Payment To VPS
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${VPS_RECURRING_PAYMENT_METHOD}
    Set Test Variable  ${billing_account_id}
    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}
    ${day_gap}    Evaluate	random.randint(1, 10)    modules=random
    ${future_date_time}    generateFutureDatetime    minutes    ${day_gap}
    Log    ${future_date_time}
    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}
    ...   Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}    ${future_date_time}
    Should Contain    ${order_state}    Scheduled
    Add Future Order In Bucket    ${om_order_id}    ${future_date_time}    ${order_state}

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    ${otp_method}   ${rec_method}   Set And Get Payment Methods
    Set Country Specific Variables
    Log   Configure suite variables here@
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    Log To Console  service plan=${service_plan}
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
    Log   Configure suite variables here@
    Delele PSM Queue
    Delele OM Queue

Select Random Offer From POM As Anonymous User
    [Documentation]  Gets the offers first and  randomly selects any offer
    ${offers}    Get Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}

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

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}
    ${otc_from_cart}    Get OTC Price From Cart    ${cart_id}    
    # verify price roll ups must be run before the following in order to get otp totals
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Test Variable   ${advance_payment}
    Log    ${advance_payment}, ${advance_payment_description}

Add Customer And Relationships To IRA
    [Documentation]  Add customer info in IRA
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    Set Test Variable    ${party_id}
    ${response}    Add Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${billing_address}    ${PHONE_NUMBER}
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

Add One Time And Recurring Payment To VPS
    ${vps_request_payment_transaction_id}   ${payment_transaction_id}   Initialize Transaction With VPS    ${reln_id}    ${advance_payment}
    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}
    Set Test Variable    ${vps_request_payment_transaction_id}
    Set Test Variable    ${payment_transaction_id}
