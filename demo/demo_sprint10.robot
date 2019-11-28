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
Get Offers From POM As Anonymous User
    [Documentation]  Gets the offers first and  randomly selects any offer
    [Tags]    OFM  captureResponseTime
    Verify Device State In SDP    xxxxx    PENDING
    #Verify And Deprovision Modem    00:A0:BC:6E:B2:F4
    #Verify And Deprovision Modem    00:A0:BC:6E:B2:9C
    #Get Current Realm On Modem    00:A0:BC:6E:B2:F4
    #Verify Realm On Modem     00:A0:BC:6E:B2:F4    aut.res.viasat.com
    #Change Realm On Modem To Given Value    00:A0:BC:6E:B2:F4    mx5.mxres.viasat.com
*** Comments ***
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Suite Variable    ${offer_id}    ${selected_offer_id}
    Set Suite Variable    ${offer_name}    ${selected_name}
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Suite Variable   ${advance_payment}
    Log    ${advance_payment}, ${advance_payment_description}
    ${products}   Parse Products From Offers For Specific Plan    ${offers}    ${selected_offer_id}
    ${discount_prod_type_id}    Get Product Type Id From POM    ${products}    ${DISCOUNT_KIND}
    Set Suite Variable        ${discount_prod_type_id}
    ${contract_prod_type_id}    Get Product Type Id From POM    ${products}    ${CONTRACT_KIND}
    Set Suite Variable        ${contract_prod_type_id}

Add Products To Cart And Update POM
    [Documentation]  Create an empty cart and add randomly selected/given offer in the cart
    [Tags]   OFM  captureResponseTime
    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    Set Suite Variable    ${cart_id}
    Log    NEW CART ID is ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    Set Suite Variable    ${cart_item_id}
    ${high_level_spb_category}    Get SPB Category For Top Level Product    ${cart_id}
    Set Suite Variable    ${high_level_spb_category}
    Log    ${high_level_spb_category}
    ${discount_spb_price_category}    ${discount_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${DISCOUNT_KIND}
    Set Suite Variable    ${discount_spb_price_category}
    Log    ${discount_spb_price_category}, ${discount_spb_price_category_duration}
    ${contract_spb_price_category}    ${contract_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${CONTRACT_KIND}
    Set Suite Variable    ${contract_spb_price_category}
    Log    ${contract_spb_price_category}, ${contract_spb_price_category_duration}
    
Verify Price Roll Ups In Cart
    [Documentation]  verifies the price roll ups in the cart
    [Tags]   OFM   exclude
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1
    ${calculated_total}    Add Up Item Prices From Cart    ${cart_id}
    ${cart_total_price}    Get From Dictionary    ${cart_data}    cartTotalPrices
    ${cart_total}    ${currency}   Get Total Price And Currency From Cart    ${cart_total_price}
    Should Contain    ${currency}    ${EXPECTED_CURRENCY}
    Should Be Equal    ${calculated_total}    ${cart_total}
    
Verify Buy More Is Supported For Given Plan
    [Documentation]  Verify buy more is selected for a given plan
    [Tags]    OFM    BUYMORE  exclude
    Run Keyword And Continue On Failure    Verify Buy More Plans    Clásica 30
    Run Keyword And Continue On Failure    Verify Buy More Plans    Ilimitada 30
    Run Keyword And Continue On Failure    Verify Buy More Plans    Ilimitada 50

Add Item To Existing Empty Cart
    [Documentation]  First creates empty cart and then adds item to this cart
    [Tags]   OFM    captureResponseTime  exclude
    ${updated_cart_name}    Generate Random Cart Name
    ${new_cart_id}    Add Empty Cart    ${updated_cart_name}    ${buyer_id}    ${SELLER_ID}
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    ${result}    Add Items In Existing Cart    ${new_cart_id}     ${buyer_id}    ${SELLER_ID}    ${selected_offer_id}
    ${cart_data}    Get The Cart Data    ${new_cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1

Add & Delete Multiple Items In OFM
    [Documentation]  First creates empty cart and then adds item to this cart
    [Tags]   OFM  exclude
    Add Cart With Single Item & Delete Item
    Test Add And Remove Item Functionality In OFM

OFM Negative Tests
    [Documentation]  This is the negative test for cart
    [Tags]  OFM    negative  exclude
    Get Cart For Invalid Cart Id
    ${empty_cart_id}    Transition Empty Cart To Accepted State
    Add Items To Empty Cart When In Accepted State     ${empty_cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id}
    Verify Get Offer Fails For Not Supported Country     ${buyer_id}    ${SELLER_ID}    CN    {'latitude': 39.9042, 'longitude': 116.4074}

Add Individual And Relationship To IRA
    [Documentation]  SW  Create a new party in IRA with certain Name & Group Association step 4-6
    [Tags]    IRA  captureResponseTime
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    Set Suite Variable    ${party_id}
    Log To Console   billing address in add to ira 2 =${billing_address}
    ${response}    Add Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}   ${billing_address}  ${PHONE_NUMBER}
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

Change Cart Status To Accepted
    [Documentation]  changes cart status to accepted
    [Tags]   OFM  captureResponseTime
    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

Initialize The Transaction With VPS
    [Documentation]   Get payment transaction id and authorize payment info
    [Tags]   vps  captureResponseTime  exclude
    Set Suite Variable  ${customer_ref}   ${reln_id}
    ${vps_request_payment_transaction_id}   copy.deepcopy   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}   txnAmount=${advance_payment}
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}
    ${paymentRetrieve Payment}  Retrieve Payment Transaction Id   ${payment_transaction_id}
    Set Suite Variable   ${advance_payment}   ${txnAmount}

Add The One Time Payment Method To VPS
    [Documentation]   Add a payment method for the first payment only
    [Tags]   vps  captureResponseTime  exclude
    ${one_time_payment_id}   Request New Payment On File   ${customer_ref}   ${VPS_PAYMENT_METHODS}[${VPS_PAYMENT_METHOD}]
    Log To Console   one_time_payment id=${one_time_payment_id}
    Set Suite Variable   ${one_time_payment_id}

Add The Recurring Payment Method To VPS
    [Documentation]   Add a recurring payment method, required for adding the billing account
    [Tags]   vps  captureResponseTime  exclude
    ${method}   Set Variable   ${VPS_PAYMENT_METHODS}[${VPS_RECURRING_PAYMENT_METHOD}]
    Set To Dictionary  ${method}   useForRecurringPayment=True
    ${recurring_payment_id}   Request New Payment On File   ${customer_ref}   ${method} 
    Set Suite Variable   ${recurring_payment_id}

Add The Billing Account To SPB
    [Documentation]   Create a billing account in SPB
    [Tags]   spb   captureResponseTime   billing-account
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${VPS_RECURRING_PAYMENT_METHOD}
    Set Suite Variable  ${billing_account_id}

Modify The Payment Transaction Id In VPS
    [Documentation]   add billing account id to payment transaction
    [Tags]   vps   captureResponseTime   modify  exclude
    &{billing_info}   Create Dictionary  billingAccount=${billing_account_id}
    Set To Dictionary   ${vps_request_payment_transaction_id}   additionalDetails=${billing_info}
    Modify VPS Payment Transaction Id   ${vps_request_payment_transaction_id}


Upsert Order To OM
   [Documentation]   SW Reformat cart contents and upsert order to OM step 7
   [Tags]   OM  captureResponseTime
    #Set Suite Variable    ${billing_account_id}    5000000987
    #Set Test Variable    ${cart_id}    fa34c1ed-efc2-4549-837a-c999b56df699
    #Set Test Variable    ${reln_id}    fa34c1ed-hgty-4549-abcd-c999b56df699

    ${guid}    Generate A GUID
    Set Suite Variable    ${happy_path_order_id}     ${guid}

    ${guid}    Generate A GUID
    Set Suite Variable    ${happy_path_payment_transaction_id}     ${guid}

    
    &{location}   createDictionary  addressLines=${ADDRESS_LINE}  countryCode=${COUNTRY_CODE}  city=${CITY}  regionOrState=${STATE}  latitude=${LATITUDE}  longitude=${LONGITUDE}  zipOrPostCode=${POSTAL_CODE}
    Set Suite Variable    ${om_location}    ${location}

    ${customerRelationshipId}  Set Variable   ${reln_id}

    ${result}   Upsert OM Order   ${happy_path_order_id}    ${cart_id}    ${customerRelationshipId}   ${om_location}   ${happy_path_payment_transaction_id}   ${cart_item_id}    ${billing_account_id}
    Log Response    ${result}

    ${result}    Get OM Order   ${happy_path_order_id}

    ${product_instance_id}    Parse Top Level Product Instance Id From OM    ${result}
    Set Suite Variable   ${product_instance_id}
    Run Keyword And Continue On Failure    Should Not Contain    ${product_instance_id}    None

    ${product_type_id}    Parse Top Level Product Type Id From OM    ${result}
    Set Suite Variable   ${product_type_id}

    ${om_spb_billing_Account}    Parse SPB Billing Account From OM    ${result}
    Set Test Variable   ${om_spb_billing_Account}

    Log    SPB Billing account from OM's getOrder is: ${om_spb_billing_Account}
    Should Be Equal    ${om_spb_billing_Account}    ${billing_account_id}

    Log   product instance id from OM is: ${product_instance_id}


OM Negative Tests
    [Documentation]   SW use main product instance id returned from upsert order to get all product instance ids for order Step 8
    [Tags]   OM    negative  exclude
    ${guid}    Generate A GUID
    Set Test Variable    ${fake_cart_test_order_id}     ${guid}
    ${guid}    Generate A GUID
    Set Test Variable    ${fake_cart_test_transaction_id}     ${guid}

    ${guid}    Generate A GUID
    Set Test Variable    ${empty_cart_test_order_id}     ${guid}
    ${guid}    Generate A GUID
    Set Test Variable    ${empty_cart_test_transaction_id}     ${guid}

    ${guid}    Generate A GUID
    Set Test Variable    ${non_accepted_cart_test_order_id}     ${guid}
    ${guid}    Generate A GUID
    Set Test Variable    ${non_accpeted_cart_test_transaction_id}     ${guid}
    ${empty_cart_id}    Add Empty Cart For Negative Test
    Update And Verify Cart Status To Accepted    ${empty_cart_id}    ACCEPTED
    Verify Upsert With Fake Cart Id    ${fake_cart_test_order_id}    ${fake_cart_id}    ${reln_id}   ${om_location}   ${fake_cart_test_transaction_id}   2019-06-21
    Verify Upsert With Empty Cart    ${empty_cart_test_order_id}    ${empty_cart_id}    ${reln_id}   ${om_location}   ${empty_cart_test_transaction_id}   2019-06-21
    ${in_progress_cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    Verify Upsert With In-Progress Cart    ${non_accepted_cart_test_order_id}    ${in_progress_cart_id}    ${reln_id}   ${om_location}   ${non_accpeted_cart_test_transaction_id}   2019-06-21

Get Product Instance Ids From PSM
    [Documentation]   SW use main product instance id returned from upsert order to get all product instance ids for order Step 8
    [Tags]   PSM  captureResponseTime
    #Set Suite Variable    ${product_instance_id}    1ba29142-48e2-47db-a0ed-6bff8b484cc8
    #Set Suite Variable    ${discount_product_instance_id}    69134781-6f89-489b-82dd-614b1864ff00
    #Set Suite Variable    ${contract_product_instance_id}    69134781-6f89-489b-82dd-614b1864ff01
    ${result}   Get PSM Instance   ${product_instance_id}
    Log   ${result}
    @{product_instance_ids}    Get Child Product Instance Ids From Response   ${result}    ${product_instance_id}
    Set Suite Variable     @{product_instance_ids}
    Log   ${product_instance_ids}
    ${billing_Account_from_psm}    Get Billing Account From PSM    ${result}
    Should Be Equal    ${billing_Account_from_psm}    ${billing_account_id}
    ${discount_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${discount_prod_type_id}
    Log    ${discount_product_instance_id}
    Set Suite Variable    ${discount_product_instance_id}
    ${contract_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${contract_prod_type_id}
    Log    ${contract_product_instance_id}
    Set Suite Variable    ${contract_product_instance_id}
    ${pi_file_location_id}    Get SPB PII File Location Id
    Set Suite Variable    ${pi_file_location_id}

Get OM SNS Event
    [Documentation]   Get the NewOrder event for the product uspserted in OM
    [Tags]     OM    sns
    #Set Suite Variable    ${om_queue_name}    bepe2etest-om741078
    Log   order ID from OM is: ${happy_path_order_id}
   # Set Suite Variable    ${happy_path_order_id}     df87e21c-f6ad-11e9-9722-020fd319bb54
    ${start_state}    ${end_state}    ${message}    Get Event From OM SNS    ${happy_path_order_id}
    Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
    Log    OrderLifecycleEvent is: ${message}

#Get PSM SNS Event For Accepted Temp
#    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
#    [Tags]     PSM    sns    buy
#    Log PSM SNS Events


Get PSM SNS Event For Accepted State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns
    #@{product_instance_ids}   Create List     9ba5bbdb-cce4-4eed-94e2-66a894e27b49     93c6da40-a34d-46dd-80ed-d113a2d9c293   6da2b917-e6a5-4f2c-96da-cf3ac65c6e33
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Accepted State   ${billing_account_id}    ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}


#Get SISM SNS Event
#    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
#    [Tags]     PSM    sns    exclude
#    #Set Suite Variable    ${product_instance_id}     3d7e2e8c-bb8d-469e-b270-ab83d6dfbec3
#    sleep    10s
#    ${state_type}    ${message}    Get Event From SISM SNS    ${product_instance_id}
#    Log    state type of ProductInstanceLifecycleEvent in SISM is: ${state_type}
#    Log    SISM Event is: ${message}



Get Product Instances For Accepted State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime
    #Set Suite Variable    ${product_instance_id}    4a49922f-5851-4a3c-a4b4-8be271dccf32
    ${result}    Wait For Order Status To Be Updated    ${product_instance_id}   PENDING
    ${subscription_id}    Parse Subscription Id From Get PI Response    ${result}
    ${nc_customer_ref}    Get Customer Ref From NC DB    ${billing_account_id}

    ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}    Get Product Id And Tariff Id For Main Product    ${offer_name}
    Log     ${main_product_tariff_id}, ${contract_tariff_id}, ${discount_tariff_id}, ${main_product_id}, ${contract_product_id}, ${discount_product_id}
    Set Suite Variable        ${main_product_tariff_id}

    ${product_pid_mapping}    CreatePIDMappingForMainAndSubProducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}  ${product_instance_id}  ${contract_product_instance_id}  ${discount_product_instance_id}  ${INTERNET_KIND}  ${CONTRACT_KIND}  ${DISCOUNT_KIND}  ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${high_level_spb_category}  ${contract_spb_price_category}  ${discount_spb_price_category}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}
    Log    ${product_pid_mapping}
    Set Suite Variable    ${product_pid_mapping}


Perform Netcracker Validations For Pending State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}
    Verify PR Mandate From NC DB    ${billing_account_id}    2
    Validate Payment Method Id In NC DB   ${billing_account_id}    ${VPS_RECURRING_PAYMENT_METHOD}


Submit Sale To VPS
    [Documentation]  Invoke sale for payment transaction id already obtained. 
    [Tags]   vps  captureResponseTime
    ${vps_sale}   Create Dictionary   paymentOnFileId=${one_time_payment_id} 
    VPS Sale   ${vps_sale}

Add One Time Payment
    [Documentation]   Report one time payment to SPB
    [Tags]   spb   vps   captureResponseTime
    ${result}   useSpbApi   addOneTimePayment   ${payment_transaction_id}    ${PAYMENT_REFERENCE_TYPE}[${VPS_INSTANCE}]
    ${status}   ${message}    Should Be True   ${result}[0]
    ${status}   ${message2}     Should Not Contain   ${result}[1]   errors    ${message}
    Verify Account Balance   ${billing_account_id}

Get Install Appointments In 3 Day Window
    [Documentation]  Request appointment within timespan of 3 days
    [Tags]   fo  captureResponseTime
    Get Available Install Dates   ${service_address}  3

Get Install Appointments In 1 Week Window
    [Documentation]  Request appointment within timespan of 7 days
    [Tags]   fo  captureResponseTime
    Get Available Install Dates   ${service_address}  7

Get Install Appointments In 1 Month Window
    [Documentation]  Request appointment within timespan of 30 days
    [Tags]   fo  captureResponseTime
    Get Available Install Dates   ${service_address}  30

Change PI Life Cycle State
    [Documentation]   Change the PI life cycle state to ACTIVE
    [Tags]   PSM  captureResponseTime  stateChange  active
    #Set Suite Variable    ${product_instance_id}     3f6faf20-bf9f-11e9-ad9e-9b784760db55
    #Set Suite Variable    ${product_instance_id}     f193a3b0-bfa3-11e9-9018-1103407bc694
    Request PI Life Cycle State Change To Active    ${product_instance_id}


#Get PSM SNS Event For Active Temp
#    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
#    [Tags]     PSM    sns
#    Log PSM SNS Events
#    sleep    30s
#    Log PSM SNS Events


Get PSM SNS Event For Active State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns    active
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Active State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances For Active State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime    active
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    ACTIVE

Perform Netcracker Validations For Active State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB    active
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}
    Wait For Account Product Update In PG DB     ${billing_account_id}    ${pi_file_location_id}    @{product_instance_ids}


*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    ${otp_method}   ${rec_method}   Set And Get Payment Methods
    Set Country Specific Variables
    Set Suite Variable  ${VPS_PAYMENT_METHOD}   ${otp_method}
    Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}   ${rec_method}
    #Set Suite Variable  ${VPS_PAYMENT_METHOD}   Diners Club
    #Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}   SEPA
    Log   Configure suite variables here@
    # if global variables not present for IDs, generate them
    #Set Suite Variable    ${selected_service_plan}    Viasat 12 Mbps
    #Set ID If It Does Not Exist   \${ORDER_ID}
    Set ID If It Does Not Exist   \${CUSTOMER_RELATIONSHIP_ID}
    Set ID If It Does Not Exist   \${PRODUCT_ITEM_ID}
    Set ID If It Does Not Exist   \${PRODUCT_ID}
    Set ID If It Does Not Exist   \${ORDER_LINE_ID}
    Set ID If It Does Not Exist   \${PAYMENT_TRANSACTION_ID}
    #ResVNO Smoke
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    Log To Console  service plan=${service_plan}
    Create PSM SQS Queue
    #Create SISM SQS Queue
    Create OM SQS Queue
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}    WARN
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}    WARN


Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    Delele PSM Queue
    #Delele SISM Queue
    Delele OM Queue

Set ID If It Does Not Exist
    [Arguments]   ${name}
    ${status}  ${message} =  Run Keyword And Ignore Error  Variable Should Exist  ${name}
    ${guid}    Generate A GUID
    Run Keyword If  "${status}" == "FAIL"  Set Suite Variable  ${name}  ${guid}

Get Cart For Invalid Cart Id
    ${guid}    Generate A GUID
    Set Suite Variable    ${fake_cart_id}     ${guid}
    ${cart_data}    Verify Invalid Cart    ${fake_cart_id}
    Log    Cart Data is ${cart_data}

Transition Empty Cart To Accepted State
    ${empty_cart_id}    Add Empty Cart For Negative Test
    ${result}    Update Cart Status To Accepted     ${empty_cart_id}    ACCEPTED
    Log     ${result}
    ${response}=   Set Variable    ${result}[data][addOrUpdateCart]
    Run Keyword And Ignore Error    Should Contain     ${response}     error
    [return]     ${empty_cart_id}

Add Items To Empty Cart When In Accepted State
    [Arguments]   ${empty_cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id}
    ${result}    Add Items In Existing Cart    ${empty_cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id}
    ${response}=   Set Variable    ${result}[errors]
    Log    ${response}

Add Cart With Single Item & Delete Item
    ${updated_cart_name}    Generate Random Cart Name
    Log   buyer id is: ${buyer_id}
    ${cart_id}    Add Cart With Item   ${updated_cart_name}    ${buyer_id}    ${SELLER_ID}    ${offer_id}
    Log    NEW CART ID is ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1
    ${cart_item_id1}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    #Set Suite Variable    ${cart_item_id}
    Delete Items From Cart    ${cart_id}     ${cart_item_id1}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  0

Test Add And Remove Item Functionality In OFM
    Set Test Variable    ${offer_id1}    a99aaf0b-4589-419f-83b1-70038d02188b     #classica 30
    Set Test Variable    ${offer_id2}    16b58ac6-872f-457a-b5aa-a742a5dacb5f      #ilimitada 30
    Set Test Variable    ${offer_id3}    f5b09d68-0cb4-4835-9a70-18d2186f4bd2      #ilimitada 50


    # Add offer1 in cart and validate cart
    ${new_cart_name}    Generate Random Cart Name
    ${cart_id}    Add Cart With Item   ${new_cart_name}    ${buyer_id}    ${SELLER_ID}    ${offer_id1}
    Log    NEW CART ID is ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1
    ${cart_item_id1}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id1}
    #Set Suite Variable    ${cart_item_id1}

    # Add offer2 in cart and validate cart
    ${result}    Add Items In Existing Cart    ${cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id2}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  2
    ${cart_item_id2}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id2}
    #Set Suite Variable    ${cart_item_id2}

    # Add offer3 in cart and validate cart
    ${result}    Add Items In Existing Cart    ${cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id3}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  3
    ${cart_item_id3}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id3}
    #Set Suite Variable    ${cart_item_id3}

    # delete offer1 from cart and validate cart
    Delete Items From Cart    ${cart_id}     ${cart_item_id1}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  2

    # delete offer3 from cart and validate cart
    Delete Items From Cart    ${cart_id}     ${cart_item_id3}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1

    # add offer1 in cart and validate cart, now cart should have offer 1 and offer2
    ${result}    Add Items In Existing Cart    ${cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id1}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  2
    ${cart_item_id1}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id1}
    #Set Suite Variable    ${cart_item_id4}

    # delete offer1 from cart and validate cart, now cart has only offer2
    Delete Items From Cart    ${cart_id}     ${cart_item_id1}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1

    # delete offer2 from cart and now cart should be empty
    Delete Items From Cart    ${cart_id}     ${cart_item_id2}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  0
