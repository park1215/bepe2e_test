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
Resource    ../../common/bep/cms/cms_resource.robot
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
    # NEED TO CONSIDER IF THIS IS LARGE (5XX) OR SMALL (7XX) BEAM
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}   ${service_location}[coordinates]

    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}

    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}
    ##### ADD FULFILLMENT PRODUCT AND FIXED SATELLITE INTERNET TO CART #####
    ${fulfillment_offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}   ${service_location}[coordinates]    FULFILLMENT
    Log   Installation product type id, name and fee are: ${INSTALLATION_PRODUCT_TYPE_ID}, ${INSTALLATION_FEE}, ${INSTALLATION_PRODUCT_NAME}

    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}    ${INSTALLATION_PRODUCT_TYPE_ID}
    Set Suite Variable   ${MONTHLY_LEASE_OPTION}   True
    Log   ${product_candidate_ids_dict}

    ${dest_pc_id}    Get From Dictionary    ${product_candidate_ids_dict}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]
    ${src_pc_id}    Get From Dictionary    ${product_candidate_ids_dict}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}   ${child_prod_kinds}
    Log    ${spb_price_dict}

    ##### ADD equipment lease option to cart  #####
    ${options_exist}   ${options}   Get Equipment Lease Options From Cart   ${cart_id}
    ${equipment_prod_type_id}    Run Keyword If  '${options_exist}'=='PASS'  Select Lease Option   ${options}
    Add New Item To Existing Cart    ${cart_id}     ${cart_item_id}    ${equipment_prod_type_id}
    Log    ${MONTHLY_LEASE_OPTION}
    Log     ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]

    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    # FOLLOWING CREATES A SUITE VARIABLE ${spb_price_dict} as well as creates suite variables ${high_level_spb_category}  ${contract_spb_price_category}
    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}   ${child_prod_kinds}
    Log    ${spb_price_dict}
    ${fulfillment_cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${INSTALLATION_PRODUCT_TYPE_ID}
    ${fulfillment_spb_price_category}    Get SPB Category For Top Level Product     e7b687eb-d798-477c-9f70-041d519d8269    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]
    Log   ${fulfillment_spb_price_category}
    Set Suite Variable   ${fulfillment_spb_price_category}

    ${otc_from_cart}    Get OTC Price From Cart    ${cart_id}
    Verify OTC From Cart      ${otc_from_cart}

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
    Set Test Variable  ${reln_id}
    Set Suite Variable  ${customer_ref}  ${reln_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED
    Set Suite Variable    ${advance_payment}    ${INSTALLATION_FEE}

    ${vps_request_payment_transaction_id}   copy.deepcopy   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Set To Dictionary   ${vps_request_payment_transaction_id}   customerRef=${reln_id}   billingAddress=${VPS_BILLING_ADDRESS}   txnAmount=${INSTALLATION_FEE}   txnType=Authorize
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${payment_transaction_id}   Request VPS Payment Transaction Id   ${vps_request_payment_transaction_id}

    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}

    #Add Billing Account To SPB
    ${billing_account_id}    Add Billing Account    ${reln_id}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
    Set Test Variable  ${billing_account_id}
    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}
    ${auth_dict}   Create Dictionary  paymentOnFileId=${one_time_payment_id}
    Authorize Payment Method    ${auth_dict}

    ${contract_id}     Send CMS Customer Agreement

    ${om_order_id}    ${product_instance_id}    ${product_type_id}    ${order_state}    ${om_payment_transaction_id}   ${om_execution_date}    ${om_service_location}
    ...   Create And Upsert Order To OM    ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}   contract_id=${contract_id}   fulfillment_cart_item_id=${fulfillment_cart_item_id}    dest_pc_id=${dest_pc_id}   src_pc_id=${src_pc_id}   is_expected_open=True

    Should Contain    ${order_state}    Open

    Sign CMS Customer Agreement
    Wait For Order To Be Processed    ${om_order_id}
    ${product_instance_id}    ${product_type_id}    Wait Until Keyword Succeeds     100s    3s    Get Product Instance And Type Id From OM   ${om_order_id}


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
    Log     ${pid_mapping}
    Log    ${event}

    # the following also randomly selects from available appointments (${selected_appointment}) and sets ${schedule_bool} to 0 or 1 - both are suite variables
    ${appointments}   Get Available Install Dates   ${service_address}  10

    # upsert creates suite variable ${external_work_order_id} 
    ${status}  ${external_work_order_id}   Run Keyword And Continue On Failure    Run Keyword If   ${schedule_bool}==0   Upsert Work Order To FO    ELSE   Upsert Work Order To FO    ${selected_appointment}
    ${fulfillment_pids}   Create List   ${external_work_order_id}
    Run Keyword If  '${status}'=='True'  Run Keywords
    ...   Run Keyword And Continue On Failure    Wait Until Keyword Succeeds   6x  5s  Verify FO Work Order  ${external_work_order_id}  AND
    ...   Run Keyword And Continue On Failure    Wait Until Keyword Succeeds   3x  5s  Verify Fulfillment Product Instance State   ACCEPTED   UNSCHEDULED  AND
    ...   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Given State For Fulfillment Product   ${billing_account_id}    ${pi_file_location_id}    ACCEPTED     ${fulfillment_pids}

    ${fulfill_instance}   Get PSM Instance  ${external_work_order_id}
    ${fulfill_state}   Set Variable    ${fulfill_instance}[data][getProductInstances][productInstances][0][state]
    ${fulfill_accepted_status}   ${message}   Run Keyword And Ignore Error  Should Be Equal As Strings   ${fulfill_state}   ACCEPTED
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${fulfill_accepted_status}   PASS   fulfillment product instance is in ${fulfill_state} state instead of ACCEPTED

    #${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    PENDING    ${billing_account_id}
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
    Run Keyword If    ${MONTHLY_LEASE_OPTION} == True     Set Test Variable    ${expected_row_count}   10    ELSE   Set Test Variable    ${expected_row_count}   7

    Run Keyword And Continue On Failure    Validate Payment Method Id In NC DB   ${billing_account_id}    ${expected_vps_recurring_payment_method}

    Run Keyword If   '${submit_sale_bool}'=='true'  Submit Sale To VPS    ${one_time_payment_id}

    Run Keyword If   '${submit_sale_bool}'=='true'  Run Keyword And Continue On Failure    Add One Time Payment To SPB    ${payment_transaction_id}   ${billing_account_id}
    #Run Keyword If    '${REAL_MODEM}'=='True'    Verify Device State In SDP    ${product_instance_id}    PENDING
 
    Run Keyword And Continue On Failure    Request Upsert Characteristics    ${product_instance_id}    MODEM_MAC_ADDRESS     ${MODEM_MAC}
    ${psm_event}    Run Keyword And Continue On Failure   Get & Verify Event From PSM SNS For Upsert Characteristics    ${product_instance_id}    MODEM_MAC_ADDRESS     ${MODEM_MAC}
    Log    ${psm_event}
    Request PI Life Cycle State Change To Active    ${product_instance_id}

    #Get PSM SNS Event For Active State
    ${product_instance_ids_count}=    Get length    ${product_instance_ids}
    Should Be Equal As Strings      ${product_instance_ids_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      Could not get 3 product instance ids ${product_instance_ids}
    ${event}   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Active State   ${billing_account_id}   ${pi_file_location_id}     @{product_instance_ids}
    Log    ${event}
    Log     ${pid_mapping}

    #Get Product Instances For Active State From SPB
    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    ACTIVE    ${billing_account_id}
    ${product_pid_mapping}    updateProductPidMappingWithSubscriptionCustomerInfo    ${subscription_id}  ${nc_customer_ref}   ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Active State
    Run Keyword And Continue On Failure    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   OK   ${expected_row_count}

    # if fulfillment product made it to accepted state, see if processed event happened
    Run Keyword If  '${fulfill_accepted_status}'=='PASS'   Run Keyword And Continue On Failure    Get & Verify Event From PSM SNS For Given State For Fulfillment Product   ${billing_account_id}    ${pi_file_location_id}   PROCESSED   ${fulfillment_pids}
    ${fulfill_instance}   Get PSM Instance  ${external_work_order_id}
    ${fulfill_state}   Set Variable    ${fulfill_instance}[data][getProductInstances][productInstances][0][state]
    Run Keyword And Continue On Failure  Should Be Equal As Strings    ${fulfill_state}   PROCESSED   fulfillment product instance is in ${fulfill_state} instead of PROCESSED

    
    ${otcs}  Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]
    :FOR  ${otc}  IN   @{otcs.keys()}
    \   Run Keyword And Continue On Failure    Verify OTC From NC DB    ${billing_account_id}    ${otc_from_cart}   ${otcs}[${otc}][name]
    
    # Verify next bill date from getBillingAccount is correct
    ${day_of_month}   Get Current Date   UTC   result_format=%d
    Verify Next Bill Date   ${billing_account_id}  ${day_of_month}
    Wait For Order State To Be Updated    ${om_order_id}    Closed

*** Comments ***
NCS With Random Plan Selection And Change Plan Selection
    [Documentation]  new customer sign up with Random Plan Selection And Change Plan Selection
    [Tags]    ncs   exclude
    [Documentation]  new customer sign up with Random Plan Selection And Change Plan Selection
    [Tags]    ncs
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    ${offers}    Get Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}
    ${temp_selected_offer_id}   ${temp_selected_name}     Select Random Offer From GetOffers    ${offers}

    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${temp_selected_offer_id}    ${temp_selected_name}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${temp_selected_offer_id}   ${child_prod_kinds}


    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${temp_selected_name}
    Set Test Variable    ${advance_payment}

    ##### ADD LEASE OPTION AND FULFILLMENT PRODUCT ####

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}    ${advance_payment}

    Delete Items From Cart    ${cart_id}    ${cart_item_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}

    ${selected_offer_id}   ${selected_name}    Wait Until Keyword Succeeds    10s    1s    Select New Random Plan      ${offers}    ${temp_selected_offer_id}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    Set Test Variable    ${offer_id}    ${selected_offer_id}
    Set Test Variable    ${offer_name}    ${selected_name}


    Add Items In Existing Cart    ${cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id}
    ##### ADD LEASE OPTION AND FULFILLMENT PRODUCT ####    
    
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}

    ${cart_price}    Add Cart With Item And Verify Cart    ${cart_id}    ${offer_name}

    ${cart_item_id}    ${spb_price_sub_categories}   Get Cart Item Id And SPB Price Categories From Cart    ${cart_id}   ${cart_data}  ${offer_id}   ${child_prod_kinds}

    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${offer_name}
    Set Test Variable    ${advance_payment}

    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}    ${advance_payment}

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
    Set Test Variable  ${reln_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

    ${vps_request_payment_transaction_id}   ${payment_transaction_id}   Initialize Transaction With VPS    ${reln_id}    ${advance_payment}
    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}

    #Add Billing Account To SPB
    ${billing_account_id}    Add Billing Account    ${reln_id}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
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

    ${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    PENDING    ${billing_account_id}
    ${nc_ids}   Run Keyword  Get Product Id And Tariff Id For Generic Main Product  ${offer_name}
    Log    ${nc_ids}

    ${product_pid_mapping}   Create Generic PID Mapping For Main And Subproducts  ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}   ${product_instance_id}
    ...   ${high_level_spb_category}  ${nc_ids}   ${spb_price_dict}

    Log    ${product_pid_mapping}
    Set Test Variable    ${product_pid_mapping}

    #Perform Netcracker Validations For Pending State
    Set Test Variable    ${expected_row_count}   10
    Run Keyword And Continue On Failure    Verify Products From NC DB    ${billing_account_id}   ${product_pid_mapping}   PE   ${expected_row_count}
    Run Keyword And Continue On Failure    Validate Payment Method Id In NC DB   ${billing_account_id}    ${expected_vps_recurring_payment_method}
    Wait For Account Product Update In PG DB     ${billing_account_id}    ${pi_file_location_id}    @{product_instance_ids}
    Run Keyword If   '${submit_sale_bool}'=='true'  Submit Sale To VPS    ${one_time_payment_id}

    Run Keyword If   '${submit_sale_bool}'=='true'  Add One Time Payment To SPB    ${payment_transaction_id}   ${billing_account_id}

    ### COMMENTING OUT NEXT ###
    #Request PI Life Cycle State Change To Active    ${product_instance_id}
    #   UPSERT WORK ORDER with or without appointment?
    #   SCHEDULE APPOINTMENT if not already done
    #   DO SOMETHING HERE TO ACTIVATE MODEM, REAL OR FAKE

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
    Create CMS SQS Queue
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}    WARN
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}    WARN
    ${result}    usePomApi  getVersion
    Log    OFM Preprod Version: ${result}    WARN
    #Run Keyword If    "${REAL_MODEM}" == "True"  Modem Setup    ${modem_mac}

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    Delele PSM Queue
    Delele OM Queue
    Delete CMS Queue

Select New Random Plan
    [Arguments]    ${offers}    ${temp_selected_offer_id}
    ${selected_offer_id2}   ${selected_name2}     Select Random Offer From GetOffers    ${offers}
    Should Not Be Equal    ${selected_offer_id2}    ${temp_selected_offer_id}
    [return]    ${selected_offer_id2}   ${selected_name2}

Send CMS Customer Agreement
    [Documentation]  CMS Customer Agreement
    ${contract_instance_id}    Generate A GUID
    Set Test Variable    ${contract_instance_id}
    Set Test Variable    ${email}    beptest@bepe2e.viasat.io
    ${address_line2} =   Catenate    SEPARATOR=,   ${CITY}   	${STATE}    ${POSTAL_CODE}
    ${first_name}    ${last_name}    Split String	${FULL_NAME}
    Set Test Variable    ${first_name}
    Set Test Variable    ${last_name}
    ${contract_instance_id}    Create Contract Instance    ${contract_instance_id}    ${reln_id}    ${first_name}   ${last_name}    ${PHONE_NUMBER}    ${email}    ${ADDRESS_LINE}[0]    ${address_line2}
    ${signer_url}    Get And Verify Contract Instance    ${contract_instance_id}
    Set Test Variable    ${signer_url}
    ${cms_file_id}    ${cms_pdf_id}    cms_resource.Get And Verify CMS DB Entry    ${contract_instance_id}    ${reln_id}    False
    Set Test Variable    ${cms_file_id}
    Set Test Variable    ${cms_pdf_id}
    Log    ${first_name}, ${last_name}
    Verify Email Received To Sign  ${first_name}    ${last_name}
    [return]    ${contract_instance_id}

Sign CMS Customer Agreement
    Add Signature With Sertifi API    ${cms_file_id}     ${cms_pdf_id}    ${first_name}     ${last_name}    ${email}
    ${cms_file_id}    ${cms_pdf_id}   Wait For CMS DB Update For Contract Instance    ${contract_instance_id}    ${reln_id}    True
    ${event_signed_status}    ${message}    Get And Verify Event From CMS SNS    ${contract_instance_id}    Signed
    Log    cms event is: ${message}
    Verify Email Received For Signed Confirmation  ${first_name}    ${last_name}
