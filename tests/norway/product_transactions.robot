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
Verify Product Transactions
    Get Offers From POM As Anonymous User
    Add Products To Cart And Update POM
    Add Individual And Relationship To IRA
    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED
    Initialize The Transaction With VPS
    ${one_time_payment_id}   Add One Time Payment Method To VPS     ${customer_ref}    ${VPS_PAYMENT_METHOD}
    Set Test Variable  ${one_time_payment_id}
    Add The Recurring Payment Method To VPS
    Add The Billing Account To SPB
    Modify The Payment Transaction Id In VPS
    #Upsert Order To OM  REPLACED WITH
    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}
    ...   Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}
    Get Product Instance Ids From PSM
    Run Keyword And Continue On Failure  Get OM SNS Event    ${om_order_id}
    Run Keyword And Continue On Failure  Get PSM SNS Event For Accepted State
    Run Keyword And Continue On Failure  Get & Verify PSM Product Instance Event   ${product_instance_id}  ACCEPTED
    Run Keyword And Continue On Failure  Get Product Instances For Accepted State From SPB
    Perform Netcracker Validations For Pending State
    Run Keyword If   '${submit_sale_bool}'=='True'  Submit Sale To VPS
    Run Keyword If   '${submit_sale_bool}'=='True'  Add One Time Payment
    Change PI Life Cycle State To ACTIVE
    Run Keyword And Continue On Failure  Get PSM SNS Event For Active State
    Run Keyword And Continue On Failure  Get & Verify PSM Product Instance Event   ${product_instance_id}  ACTIVE
    Run Keyword And Continue On Failure  Get Product Instances For Active State From SPB
    Run Keyword And Continue On Failure  Perform Netcracker Validations For Active State
    Run Keyword And Continue On Failure  Wait For Order State To Be Updated    ${om_order_id}    Closed
    Change PI Life Cycle State To SUSPENDED
    Run Keyword And Continue On Failure  Get PSM SNS Event For Suspended State
    Run Keyword And Continue On Failure  Get & Verify PSM Product Instance Event   ${product_instance_id}  SUSPENDED
    Run Keyword And Continue On Failure  Get Product Instances For Suspended State From SPB
    Run Keyword And Continue On Failure  Perform Netcracker Validations For Suspended State
    Change PI Life Cycle State To RESUME
    Run Keyword And Continue On Failure  Get PSM SNS Event For Resumed State
    Run Keyword And Continue On Failure  Get & Verify PSM Product Instance Event   ${product_instance_id}  ACTIVE
    Run Keyword And Continue On Failure  Get Product Instances For Resume State From SPB
    Run Keyword And Continue On Failure  Perform Netcracker Validations For Resumed State
    Change PI Life Cycle State To DEACTIVATE
    Run Keyword And Continue On Failure  Get PSM SNS Event For Deactivated State
    Run Keyword And Continue On Failure  Get & Verify PSM Product Instance Event   ${product_instance_id}  DEACTIVATED
    Run Keyword And Continue On Failure  Get Product Instances For Deactivated State From SPB
    Perform Netcracker Validations For Deactivated State



*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    ${otp_method}   ${rec_method}   Set And Get Payment Methods
    Set Country Specific Variables
    Set Suite Variable  ${VPS_PAYMENT_METHOD}   ${otp_method}
    Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}   ${rec_method}
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

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    Delele PSM Queue
    Delele OM Queue

Get Offers From POM As Anonymous User
    [Documentation]  Gets the offers first and  randomly selects any offer
    [Tags]    OFM  captureResponseTime
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Suite Variable    ${offer_id}    ${selected_offer_id}
    Set Suite Variable    ${offer_name}    ${selected_name}
    
    #${products}   Parse Products From Offers For Specific Plan    ${offers}    ${selected_offer_id}
    #${discount_prod_type_id}    Get Product Type Id From POM    ${products}    ${DISCOUNT_KIND}
    #Set Suite Variable        ${discount_prod_type_id}
    #${contract_prod_type_id}    Get Product Type Id From POM    ${products}    ${CONTRACT_KIND}
    #Set Suite Variable        ${contract_prod_type_id}
    
    ${nc_ids}   Run Keyword  Get Product Id And Tariff Id For Generic Main Product  ${offer_name}
    Log    ${nc_ids}

Add Products To Cart And Update POM
    [Documentation]  Create an empty cart and add randomly selected/given offer in the cart
    [Tags]   OFM  captureResponseTime
    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    Set Suite Variable    ${cart_id}
    Log    NEW CART ID is ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    #${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    #${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    #Set Suite Variable    ${cart_item_id}
    
    # FOLLOWING CREATES A SUITE VARIABLE ${spb_price_dict} as well as creates suite variables ${high_level_spb_category}  ${contract_spb_price_category}     
    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}   ${child_prod_kinds}        
    Set Suite Variable    ${cart_item_id}
    
    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}
    ${otc_from_cart}    Get OTC Price From Cart    ${cart_id}
    Set Suite Variable   ${otc_from_cart}

    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Suite Variable   ${advance_payment}
    Log    ${advance_payment}, ${advance_payment_description}
    
    #${high_level_spb_category}    Get SPB Category For Top Level Product    ${cart_id}
    #Set Suite Variable    ${high_level_spb_category}
    #Log    ${high_level_spb_category}
    
    #${discount_spb_price_category}    ${discount_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${DISCOUNT_KIND}
    #Set Suite Variable    ${discount_spb_price_category}
    #Log    ${discount_spb_price_category}, ${discount_spb_price_category_duration}
    #${contract_spb_price_category}    ${contract_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${CONTRACT_KIND}
    #Set Suite Variable    ${contract_spb_price_category}
    #Log    ${contract_spb_price_category}, ${contract_spb_price_category_duration}


Add Individual And Relationship To IRA
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
    Set Suite Variable  ${customer_ref}   ${reln_id}

Change Cart Status To Accepted
    [Documentation]  changes cart status to accepted
    [Tags]   OFM  captureResponseTime
    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

Initialize The Transaction With VPS
    [Documentation]   Get payment transaction id and authorize payment info
    [Tags]   vps  captureResponseTime
    Set Suite Variable  ${customer_ref}   ${reln_id}
    ${vps_request_payment_transaction_id}   Create Dictionary
    # deepcopy doesn't seem to work
    :FOR    ${key}    IN    @{VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS.keys()}
    \   Set To Dictionary  ${vps_request_payment_transaction_id}   ${key}=${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}[${key}]

    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${customer_ref}   billingAddress=${VPS_BILLING_ADDRESS}   txnAmount=${advance_payment}
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}
    ${paymentRetrieve Payment}  Retrieve Payment Transaction Id   ${payment_transaction_id}
    Set Suite Variable   ${advance_payment}   ${txnAmount}

Add The One Time Payment Method To VPS
    [Documentation]   Add a payment method for the first payment only
    [Tags]   vps  captureResponseTime
    ${one_time_payment_id}   Request New Payment On File   ${customer_ref}   ${VPS_PAYMENT_METHODS}[${VPS_PAYMENT_METHOD}]
    Log To Console   one_time_payment id=${one_time_payment_id}
    Set Suite Variable   ${one_time_payment_id}

Add The Recurring Payment Method To VPS
    [Documentation]   Add a recurring payment method, required for adding the billing account
    [Tags]   vps  captureResponseTime
    ${method}   Set Variable   ${VPS_PAYMENT_METHODS}[${VPS_RECURRING_PAYMENT_METHOD}]
    Set To Dictionary  ${method}   useForRecurringPayment=True
    ${create_prmandate}   ${rb_payment_method_id}   ${dontcare}      Retrieve Payment Type Info   ${VPS_RECURRING_PAYMENT_METHOD}
    Set Suite Variable    ${create_prmandate}
    ${recurring_payment_id}   Request New Payment On File   ${customer_ref}   ${method}
    Set Suite Variable   ${recurring_payment_id}

Add The Billing Account To SPB
    [Documentation]   Create a billing account in SPB
    [Tags]   spb   captureResponseTime
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${VPS_RECURRING_PAYMENT_METHOD}
    Set Suite Variable  ${billing_account_id}

Modify The Payment Transaction Id In VPS
    [Documentation]   add billing account id to payment transaction
    [Tags]   vps   captureResponseTime   modify
    &{billing_info}   Create Dictionary  billingAccount=${billing_account_id}
    Set To Dictionary   ${vps_request_payment_transaction_id}   additionalDetails=${billing_info}
    Modify VPS Payment Transaction Id   ${vps_request_payment_transaction_id}

Get Product Instance Ids From PSM
    [Documentation]   SW use main product instance id returned from upsert order to get all product instance ids for order Step 8
    [Tags]   PSM  captureResponseTime
    ${result}   Get PSM Instance   ${product_instance_id}
    Log   ${result}
    #@{product_instance_ids}    Get Child Product Instance Ids From Response   ${result}    ${product_instance_id}
    @{product_instance_ids}    Get And Validate All Product Instance Ids From PSM    ${product_instance_id}   ${billing_account_id}   ${child_prod_kinds}
    Set Suite Variable     @{product_instance_ids}

    ${billing_Account_from_psm}    Get Billing Account From PSM    ${result}    
    Should Be Equal    ${billing_Account_from_psm}    ${billing_account_id}
    #${discount_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${discount_prod_type_id}
    #Log    ${discount_product_instance_id}
    #Set Suite Variable    ${discount_product_instance_id}
    #${contract_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${contract_prod_type_id}
    #Log    ${contract_product_instance_id}
    #Set Suite Variable    ${contract_product_instance_id}
    ${pi_file_location_id}    Get SPB PII File Location Id
    Set Suite Variable    ${pi_file_location_id}

Get OM SNS Event
    [Documentation]   Get the NewOrder event for the product uspserted in OM
    [Tags]     OM    sns
    [Arguments]   ${order_id}
    Log   order ID from OM is: ${order_id}
    ${start_state}    ${end_state}    ${message}    Run Keyword And Continue On Failure    Get Event From OM SNS    ${order_id}
    Log    start and end state of OrderLifecycleEvent : ${start_state} & ${end_state}
    Log    OrderLifecycleEvent is: ${message}

Get PSM SNS Event For Accepted State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns    accepted
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get all product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Accepted State   ${billing_account_id}    ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances For Accepted State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime    accepted
    #${result}    Wait For Order Status To Be Updated    ${product_instance_id}   PENDING
    #${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    #Should Be Equal    ${spb_pi_status}    PENDING
    #${subscription_id}    Parse Subscription Id From Get PI Response    ${result}
    #${nc_customer_ref}    Get Customer Ref From NC DB    ${billing_account_id}
    Set Test Variable      ${subscription_id}   None
    Set Test Variable      ${nc_customer_ref}   None
    ${nc_ids}   Run Keyword  Get Product Id And Tariff Id For Generic Main Product  ${offer_name}
    Log    ${nc_ids}
       
    
    #${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}    Get Product Id And Tariff Id For Main Product    ${offer_name}
    #Log     ${main_product_tariff_id}, ${contract_tariff_id}, ${discount_tariff_id}, ${main_product_id}, ${contract_product_id}, ${discount_product_id}
    #Set Suite Variable        ${main_product_tariff_id}
    #${product_pid_mapping}    CreatePIDMappingForMainAndSubProducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}  ${product_instance_id}  ${contract_product_instance_id}  ${discount_product_instance_id}  ${INTERNET_KIND}  ${CONTRACT_KIND}  ${DISCOUNT_KIND}  ${main_product_tariff_id}  ${contract_tariff_id}  ${discount_tariff_id}  ${high_level_spb_category}  ${contract_spb_price_category}  ${discount_spb_price_category}  ${main_product_id}  ${contract_product_id}  ${discount_product_id}

    #  ${nc_ids}  has product_id and tariff_id, ${spb_price_dict} has xxx_spb_price_category, KIND variables are in country_variables
    ${product_pid_mapping}   Create Generic PID Mapping For Main And Subproducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}   ${product_instance_id}
    ...   ${high_level_spb_category}  ${nc_ids}   ${spb_price_dict}

    Log    ${product_pid_mapping}
    Set Suite Variable    ${product_pid_mapping}

Perform Netcracker Validations For Pending State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB    pending
    Set Test Variable    ${expected_row_count}   10
    #Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}
    Run Keyword If  '${create_prmandate}'=='True'   Verify PR Mandate From NC DB    ${billing_account_id}    2
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

Change PI Life Cycle State To ACTIVE
    [Documentation]   Change the PI life cycle state to ACTIVE
    [Tags]   PSM  captureResponseTime  stateChange  active
    Request PI Life Cycle State Change To Active    ${product_instance_id}

Get PSM SNS Event For Active State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns    active
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get all product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Active State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances For Active State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime    active
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    ACTIVE
    ${subscription_id}    Parse Subscription Id From Get PI Response    ${result}
    ${nc_customer_ref}    Get Customer Ref From NC DB    ${billing_account_id}
    ${product_pid_mapping}    updateProductPidMappingWithSubscriptionCustomerInfo    ${subscription_id}  ${nc_customer_ref}   ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

Perform Netcracker Validations For Active State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB    active
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}
    ${otcs}  Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]
    # if there is more than one OTC, ${otc_from_cart} will have to be a lookup
    :FOR  ${otc}  IN   @{otcs.keys()}
    \   Verify OTC From NC DB    ${billing_account_id}    ${otc_from_cart}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS][${otc}][name]
    
Change PI Life Cycle State To SUSPENDED
    [Documentation]   Change the PI life cycle state to SUSPENDED
    [Tags]   PSM  captureResponseTime  stateChange  suspend
    Request PI Life Cycle State Change To Suspended    ${product_instance_id}

Get PSM SNS Event For Suspended State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns    suspend
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get all product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Suspended State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances For Suspended State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime    suspend
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    SUSPENDED


Perform Netcracker Validations For Suspended State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB    suspend
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   SU   ${expected_row_count}

Change PI Life Cycle State To RESUME
    [Documentation]   Change the PI life cycle state to RESUME
    [Tags]   PSM  captureResponseTime  stateChange  resume
    Request PI Life Cycle State Change To Active    ${product_instance_id}

Get PSM SNS Event For Resumed State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns    resume
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Resumed State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances For Resume State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime    resume
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    ACTIVE

Perform Netcracker Validations For Resumed State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB    resume
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}

Change PI Life Cycle State To DEACTIVATE
    [Documentation]   Change the PI life cycle state to RESUME
    [Tags]   PSM  captureResponseTime  stateChange  deactivate
    Request PI Life Cycle State Change To Deactivated    ${product_instance_id}

Get PSM SNS Event For Deactivated State
    [Documentation]   Get the ProductInstanceLifecycleEvent for the product uspserted in OM
    [Tags]     PSM    sns    deactivate
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Get & Verify Event From PSM SNS For Deactivated State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}

Get Product Instances For Deactivated State From SPB
    [Documentation]  Get Product Instances from SPB
    [Tags]    SPB  captureResponseTime    deactivate
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    TERMINATED

Perform Netcracker Validations For Deactivated State
    [Documentation]  Based on customer and payer role ids from IRA, get the NC account # from SPB's Postgress db and then get the customer ref from netcracker DB
    [Tags]     SPB    deactivate
    Set Test Variable    ${expected_row_count}   10
    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   TX   ${expected_row_count}
