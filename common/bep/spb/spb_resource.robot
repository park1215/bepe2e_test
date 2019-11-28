*** Settings ***
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Resource   ./nc_resource.robot
Library    OperatingSystem
Library    Process
Library   ./spb_api.py
Library   ./spb_postgres_db.py
Library   ./spb_nc_db.py
Library   ./spb_sftp.py
Library   ../../../python_libs/bep_common.py
Library   ../common/bep_resource.py
Variables   ./spb_parameters.py

*** Keywords ***
Get SPB Version
    [Documentation]     Get version of SPB deployed in preprod environment
    ${result}    useSpbApi   getVersion
    ${result}    Convert To String   ${result}    
    [return]     ${result}


Upsert to SPB
    [Documentation]     Robot keyword to upsert to SPB
    [Arguments]    ${HL_P_ID}    ${EQ_P_ID}    ${customer_id}    ${buyer_id}    ${customer_rel_id}
    Log To Console    Upsert To SPB
    ${status}  ${result}    useSpbApi    upsertProductInstance  ${HL_P_ID}    ${EQ_P_ID}    ${customer_id}    ${buyer_id}    ${customer_rel_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${response}=   Set Variable    ${result}[data][upsertProductInstance]
    Log    ${response}
    [return]    ${response}

Add Billing Account
    [Documentation]     Robot keyword to add billing account
    [Arguments]    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${given_vps_recurring_payment_method}
    ${guid}    Generate A GUID
    &{billing_account_dict}   Create Dictionary   deduplicationId=${guid}   invoicingOrgId=${INVOICING_ORG}   paymentReferenceTypeName=${SPB_VPS_SYSTEM_NAME}   paymentReferenceValue=${customer_ref}
    Set To Dictionary   ${billing_account_dict}   recurringPaymentMethodType=${given_vps_recurring_payment_method}   billingPIIRefId=${payer_role_id}   mailingPIIRefId=${customer_role_id}   piiFileLocationId=2
    ${status}    ${billing_account_id}   useSpbApi   addBillingAccount   ${billing_account_dict}
    Should Be True    ${status}    addBillingAccount failed in SPB with ${billing_account_id}
    Should Not Contain    ${billing_account_id}    addBillingAccount:Error
    [return]    ${billing_account_id}
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Get And Validate Product Instance Ids From SPB
    [Documentation]     Robot keyword to Get And Validate Product Instance Ids From PSM
    [Arguments]    ${product_instance_id}    ${expected_product_status}    ${billing_account_id}
    #${result}    Validate Product Status In SPB    ${product_instance_id}    ${expected_product_status}
    #${result}    Wait For Order Status To Be Pending    ${product_instance_id}    ${expected_product_status}
    ${result}    Wait For Order Status To Be Updated    ${product_instance_id}    ${expected_product_status}
    ${subscription_id}    Parse Subscription Id From Get PI Response    ${result}
    ${nc_customer_ref}    Get Customer Ref From NC DB    ${billing_account_id}
    [return]    ${subscription_id}  ${nc_customer_ref}

Validate Product Status In SPB
    [Documentation]     Robot keyword to Get And Validate Product Instance Ids From PSM
    [Arguments]    ${product_instance_id}    ${expected_product_status}
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    ${expected_product_status}
    [return]    ${result}

Add One Time Payment To SPB
    [Documentation]     Robot keyword to Add One Time Payment To SPB
    [Arguments]    ${payment_transaction_id}   ${billing_account_id}
    ${result}   useSpbApi   addOneTimePayment   ${payment_transaction_id}    ${SPB_VPS_SYSTEM_NAME}
    ${status}   ${message}    Should Be True   ${result}[0]
    ${status}   ${message2}     Should Not Contain   ${result}[1]   errors    ${message}
    Verify Account Balance   ${billing_account_id}

Get SPB Instance
    [Documentation]     Robot keyword to get Full Instance From SPB
    [Arguments]    ${product_instance_id}
    ${status}  ${result}    useSpbApi    getProductInstance  ${product_instance_id}
    Log Response    ${result}
    Should Be True    ${status}    getProductInstance failed in SPB with ${result}
    [return]    ${result}
    #[Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Get Payment Method Type From Get Billing Account
    [Documentation]     Robot keyword to Get Payment Method Type From Get Billing Account
    [Arguments]    ${billing_account}
    ${result}    Get Billing Account From SPB    ${billing_account}
    ${payment_method_type}    Parse Recurring Payment Method Type From Get PI Response   ${result}
    [return]   ${payment_method_type}

Validate Billing Account State From SPB
    [Documentation]     Robot keyword to Validate Billing Account State From SPB
    [Arguments]    ${billing_account}    ${expected_state}
    ${result}    Get Billing Account From SPB    ${billing_account}
    ${received_state}    Parse Account Status In SPB   ${result}
    Should Be Equal    ${received_state}    ${expected_state}

Parse Subscription Id From Get PI Response
    [Documentation]    Parse Top Level Product Type Id From OM's get Order response
    [Arguments]     ${result}
    Set Test Variable   ${subscription_id}   ${result}[data][getProductInstance][subscriptionId]
    Run Keyword And Continue On Failure    Should Not Contain    ${subscription_id}    None
    [return]   ${subscription_id}

Parse Recurring Payment Method Type From Get PI Response
    [Documentation]    Parse Recurring Payment Method Type From Get PI Response
    [Arguments]     ${result}
    Set Test Variable   ${payment_method_type}   ${result}[recurringPaymentMethodType]
    [return]   ${payment_method_type}

Parse Account Status In SPB
    [Documentation]     Robot keyword to parse product state
    [Arguments]    ${result}
    Set Test Variable   ${account_state}   ${result}[accountStatus]
    [return]   ${account_state}

Validate SPB State Of Product
    [Documentation]     Robot keyword to Validate SPB State Of Product
    [Arguments]    ${individual_pid}    ${expected_state}
    ${result}    Get SPB Instance    ${individual_pid}
    ${received_state}    Parse Product Instance Status From Get PI Response   ${result}
    Should Be Equal    ${received_state}    ${expected_state}

Parse Product Instance Status From Get PI Response
    [Documentation]     Robot keyword to Parse Product Instance Status From Get PI Response of spb
    [Arguments]    ${result}
    Set Test Variable   ${spb_pi_status}  ${result}[data][getProductInstance][productInstanceStatus]
    [return]   ${spb_pi_status}

Parse Billing Account From Get PI Response
    [Documentation]     Robot keyword toParse Billing Account From Get PI Response
    [Arguments]    ${result}
    Set Test Variable   ${billing_account}  ${result}[data][getProductInstance][accountNumber]
    [return]   ${billing_account}

#Get Customer Party Id From Postgres
#    [Documentation]     Robot keyword to get customer party id from PG Db to use later to get NC account #Query SPB Batch Request Table
#    [Arguments]    ${customer_party_role_id}
#    ${customer_party_id}  useSpbPgApi    queryCustomerPartyId    ${customer_party_role_id}
#    Log    ${customer_party_id}
#    ${status}   ${message}   Should Not Contain   ${customer_party_id}   Error   ${customer_party_id}
#    [return]    ${customer_party_id}

#Get Payer Party Id From Postgres
#    [Documentation]     Robot keyword to get payer party id from PG Db to use later to get NC account #
#    [Arguments]    ${payer_party_role_id}
#    ${payer_party_id}  useSpbPgApi    queryPayerPartyId    ${payer_party_role_id}
#    Log    ${payer_party_id}
#    ${status}   ${message}   Should Not Contain   ${payer_party_id}   Error   ${payer_party_id}
#    [return]    ${payer_party_id}

#Get NC Account & Customer Payer Map Id From Postgres
#    [Documentation]     Robot keyword to Get NC Account & Customer Payer Map Id From Postgres
#    [Arguments]    ${customer_party_role_id}    ${payer_party_role_id}

#    ${customer_party_id}    Get Customer Party Id From Postgres    ${customer_party_role_id}
 #   ${payer_party_id}    Get Payer Party Id From Postgres    ${payer_party_role_id}
 #   ${nc_account_number}    ${customer_payer_map_id}   useSpbPgApi    queryCustomerMapTable    ${customer_party_id}    ${payer_party_id}
 #   Log    Netcracker Account # is: ${nc_account_number}
 #   Log    Customer Payer Map Id is: ${customer_payer_map_id}
 #   [return]    ${nc_account_number}     ${customer_payer_map_id}

#Get Billing Account From Postgres
#    [Documentation]     Robot keyword to get product From Postgres
#    [Arguments]    ${billing_account}
#    ${account_group_id}    useSpbPgApi    queryBillingAccountTable    ${billing_account}
#    Log    customer ref is: ${account_group_id}
#    [return]    ${account_group_id}

Verify PostGress For Account Products
    [Documentation]     Gets the mapping of billing account id and billing account reference from PG DB and validatie account product with product instance id
    [Arguments]    ${billing_account}   ${pii_file_ref_id}    @{expected_product_instance_ids}
    Log    ${expected_product_instance_ids}
    ${expected_account_id}    Get Billing Account Reference From PG DB    ${billing_account}
    : FOR    ${product_instance_id}    IN    @{expected_product_instance_ids}
    \   Log    ${product_instance_id}
    \   ${billing_account_data}    useSpbPgApi    queryAccountProductsTable    ${product_instance_id}
    \   Log    account_group_id ref is: ${billing_account_data}
    \   ${received_account_id}    Get From List    ${billing_account_data}   1
    \   ${received_pii_ref_file_id}    Get From List    ${billing_account_data}   3
    \   Should Be Equal As Strings    ${expected_account_id}    ${received_account_id}
    \   Should Be Equal As Strings    ${pii_file_ref_id}    ${received_pii_ref_file_id}

Get Billing Account Reference From PG DB
    [Documentation]     Robot keyword to fet maapinf between billing account id and billing account reference
    [Arguments]    ${billing_account}
    ${billing_account_data}    useSpbPgApi    queryBillingAccountTable    ${billing_account}
    Log    billing_account_data is: ${billing_account_data}
    ${received_account_id}    Get From List    ${billing_account_data}   0
    [return]    ${received_account_id}

Get SPB PII File Location Id
    [Documentation]     Robot keyword to get Get SPB PII File Location Id From Postgres
    ${spb_pii_file_location_id}    useSpbPgApi    getPiiFileLocationId
    Log    spb_pii_file_location_id is ${spb_pii_file_location_id}
    [return]    ${spb_pii_file_location_id}

Get Customer Ref From NC DB
    [Documentation]     Robot keyword to Get Customer Ref From NC DB
    [Arguments]    ${nc_account_number}
    ${nc_customer_ref}    useSpbNcApi    queryNcAccountTable    ${nc_account_number}
    Log    nc_customer_ref: ${nc_customer_ref}
    Run Keyword And Continue On Failure    Should Not Contain    ${nc_customer_ref}    None
    [return]    ${nc_customer_ref}

Get Existing Customer And Active Product Info
    [Documentation]     Robot keyword to Get Existing Customer And Active Product Info
    [Arguments]    ${plan_name}
    ${account_info}    useSpbNcApi    queryNcToFindActiveAccount    ${plan_name}
    Log    Randomly selected active plan is ${account_info}
    ${existing_customer_reln_id}   Get From List   ${account_info}  12
    ${existing_customer_billing_account_id}   Get From List   ${account_info}  2
    [return]    ${existing_customer_reln_id}    ${existing_customer_billing_account_id}

Get Account Payment History 
    [Documentation]  get list of payments made to a specified account number
    [Arguments]   ${billing_account}
    ${params}   Create Dictionary   accountNumber=${billing_account}
    ${status}   ${payments}  useSpbApi   getPaymentHistory   ${params}
    Should Be Equal As Strings  ${status}   True   ${payments}
    [return]   ${payments}[data][getPaymentHistory]

Verify SPB Account Payment History
    [Documentation]   Verifies the account payment history query returns the correct info. Order in list returned is newest to oldest payment, so check payment at index 0.
    ...   This needs to be invoked very soon after payment is made so it is the first in the list
    [Arguments]   ${billing_account}   ${amount}   ${payment_method}

    ${is_refund}   Set Variable If  ${amount}>0   False   True

    ${payments}   Get Account Payment History   ${billing_account}
    
    ${dontcare1}   ${dontcare2}   ${payment_method_name}   Retrieve Payment Type Info    ${payment_method}
    
    ${payment_amount}  Set Variable  ${payments}[0][paymentAmount] 
    Should Be Equal As Numbers  ${amount}   ${payment_amount}[value]   Payment amount is not in payment history
    Should Be Equal As Strings  ${EXPECTED_CURRENCY}   ${payment_amount}[currency][name]
    Should Be Equal As Strings  ${payment_method_name}   ${payments}[0][paymentType]
    
    Should Be Equal As Strings  Created  ${payments}[0][paymentStatus]
    Should Be Equal As Strings  ${is_refund}  ${payments}[0][isRefund]

Verify Products From NC DB
    [Documentation]     Robot keyword to Check Products From NC DB
    [Arguments]    ${nc_account_number}   ${product_pid_mapping}   ${expected_status}    ${expected_row_count}    ${subscription_ref}=None
    ${status}    ${product_rows}    useSpbNcApi    queryNcProductTable    ${nc_account_number}    ${expected_status}    ${subscription_ref}
    Should Be True    ${status}
    ${row_count}    Get length    ${product_rows}
    Run Keyword And Continue On Failure    Should Be True	${row_count} >= ${expected_row_count}
    :FOR    ${product_instance_id}    IN    @{product_pid_mapping.keys()}
    \   Log    ${product_instance_id}
    \   ${values}    Set Variable   ${product_pid_mapping["${product_instance_id}"]}
    \   ${customer_ref_value}     Validate Product Details from NC Response    ${product_rows}    ${values}    ${product_instance_id}
    Verify Customer Contract In NC DB    ${customer_ref_value}

Verify Customer Contract In NC DB
    [Documentation]     Robot keyword Verify Customer Contract In NC DB
    [Arguments]    ${customer_ref_value}
    ${status}    ${contract_rows}    useSpbNcApi    queryNcCustomerContractTable    ${customer_ref_value}
    Should Be True    ${status}
    ${row_count}    Get length    ${contract_rows}
    Run Keyword And Continue On Failure    Should Be True	${row_count} >= 1
    ${row}    Get From list    ${contract_rows}    0
    ${received_contract_term}    Get From list    ${row}    4
    Should Be Equal As Strings     ${received_contract_term}  ${CONTRACT_TERM}

Wait For OTC Update In NC DB
    [Documentation]     Robot keyword to Wait For OTC Update In NC DB
    [Arguments]    ${nc_account_number}  ${expected_otc_value}   ${buy_more_offer_name}   ${expected_otc_status}
    Wait Until Keyword Succeeds     15s    1s    Verify OTC Is Added In NC DB For Buy More    ${nc_account_number}  ${expected_otc_value}   ${buy_more_offer_name}   ${expected_otc_status}

Wait For Account Product Update In PG DB
    [Documentation]     Robot keyword to Wait For Account Product Update In PG DB
    [Arguments]    ${billing_account}   ${pii_file_ref_id}    @{expected_product_instance_ids}
    Wait Until Keyword Succeeds     15s    1s    Verify PostGress For Account Products    ${billing_account}   ${pii_file_ref_id}    @{expected_product_instance_ids}

Verify OTC Is Added In NC DB For Buy More
    [Documentation]     Robot keyword to Verify OTC Is Added In NC DB For Buy More
    [Arguments]    ${nc_account_number}  ${expected_otc_value}   ${buy_more_offer_name}   ${expected_otc_status}
    ${otc_name}   Set Variable   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][BUY_MORE_DICT][${buy_more_offer_name}][OTC_NAME]
    Log   ${otc_name}
    ${expected_otc_id}    Get OTC ID From NC DB    ${otc_name}
    ${status}    ${otc_row}    useSpbNcApi    queryNcAccHasOTCTable    ${nc_account_number}
    Should Be True    ${status}
    ${row_count}    Get length    ${otc_row}
    Run Keyword And Continue On Failure    Should Not Be True	${row_count} == 0
    Log   ${otc_row}
    ${received_acct_id}   Get From List   ${otc_row}  0
    ${received_otc_id}   Get From List   ${otc_row}  3
    ${received_otc_value}   Get From List   ${otc_row}  5
    ${expected_otc_value}    Evaluate     ${expected_otc_value} * 1000
    Log   ${received_otc_value}
    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${nc_account_number}  ${received_acct_id}
    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_otc_id}  ${received_otc_id}
    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_otc_value}  ${received_otc_value}
    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_otc_status}  1

Verify OTC From NC DB
    [Documentation]     Robot keyword to Verify OTC Is Added In NC DB.
    [Arguments]    ${nc_account_number}    ${expected_otc_value}   ${expected_otc_name}
    ${expected_otc_id}    Get OTC ID From NC DB    ${expected_otc_name}
    ${status}    ${otc_row}    useSpbNcApi    queryNcAccHasOTCTable    ${nc_account_number}
    Should Be True    ${status}
    ${row_count}    Get length    ${otc_row}
    Run Keyword And Continue On Failure    Should Not Be True	${row_count} == 0
    Log   ${otc_row}
    ${received_otc_id}   Get From List   ${otc_row}  3
    ${received_otc_value}   Get From List   ${otc_row}  5
    ${expected_otc_value}    Evaluate     ${expected_otc_value} * 1000
    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${received_otc_id}  ${expected_otc_id}
    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_otc_value}  ${received_otc_value}

Get OTC ID From NC DB
    [Documentation]     Robot keyword to get OTC ID for buy more
    [Arguments]    ${otc_name}   
    ${status}    ${otc_row}    useSpbNcApi    queryNcOneTimeChargeTable    ${otc_name}
    Should Be True    ${status}
    ${row_count}    Get length    ${otc_row}
    Run Keyword And Continue On Failure    Should Not Be True	${row_count} == 0
    Log   ${otc_row}
    ${otc_id}   Get From List   ${otc_row}  0
    [return]   ${otc_id}

Validate Payment Method Id In NC DB
    [Documentation]   Verifies prmandate table entry is correct (or is not there at all if VPS doesn't handle payment method).  ${rb_payment_method_id} set in "Add Recurring Payment Method To VPS"
    [Arguments]     ${billing_account}    ${payment_method}
    ${status}    ${row}    useSpbNcApi    queryNcPRMandateTable    ${billing_account}
    Should Be True    ${status}
    ${row_count}    Get length    ${row}
    
    Get PR Mandate Presence and RB Payment Method Id    ${billing_account}
     
    Run Keyword If   '${create_prmandate}'=='False'    Run Keyword And Continue On Failure    Should Be True	${row_count} == 0  
    Run Keyword If   '${create_prmandate}'=='True'    Run Keyword And Continue On Failure    Should Be True	   ${row_count} > 0
    Run Keyword If   '${create_prmandate}'=='True'    Run Keyword And Continue On Failure    Should Be Equal As Strings   ${row}[2]    ${rb_payment_method_id}

Get PR Mandate Presence and RB Payment Method Id
    [Arguments]   ${billing_account}
    ${payment_method}   Get Payment Method Type From Get Billing Account   ${billing_account}
    ${result}  getRbPaymentMethodInfo   ${payment_method}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INVOICING_ORGANIZATION]
    Convert To List  ${result}[0]
    Set Suite Variable  ${create_prmandate}  ${result}[0][0]
    Set Suite Variable   ${rb_payment_method_id}   ${result}[0][1]
    Set Suite Variable  ${rb_payment_method_name}   ${result}[0][2]

Verify PR Mandate From NC DB
    [Documentation]     Robot keyword to Verify PR Mandate From NC DB
    [Arguments]    ${nc_account_number}   ${expected_status}
    Get PR Mandate Presence and RB Payment Method Id    ${nc_account_number}
    ${status}    ${row}    useSpbNcApi    queryNcPRMandateTable    ${nc_account_number}
    Should Be True    ${status}
    ${row_count}    Get length    ${row}
    Run Keyword If   '${create_prmandate}'=='True'  Run Keywords
    ...   Run Keyword And Continue On Failure    Should Be True	${row_count} > 0   AND
    ...   Set Test Variable   ${received_status}   ${row}[5]   AND
    ...   Should Be Equal As Strings   ${received_status}    ${expected_status}

Wait For Order Status To Be Updated
    [Documentation]    wait until Order Status is Pending
    [Arguments]     ${product_instance_id}    ${expected_product_status}
    ${result}     Wait Until Keyword Succeeds     15s    1s    Verify Order State Is Updated    ${product_instance_id}    ${expected_product_status}
    [return]   ${result}

Verify Order State Is Updated
    [Documentation]   Verify Order State Is Pending
    [Arguments]     ${product_instance_id}    ${expected_product_status}
    ${result}   Get SPB Instance   ${product_instance_id}
    ${spb_pi_status}    Parse Product Instance Status From Get PI Response    ${result}
    Should Be Equal    ${spb_pi_status}    ${expected_product_status}
    [return]   ${result}


Query NC For Id
    [Documentation]   query specified NC table for specified item to get id. Store result in test variable.
    [Arguments]   ${query_name}   ${item_name}
    ${status}   ${id}   useSpbNcApi   ${query_name}  ${item_name}   ${COUNTRY_CODE}
    Should Be True   {$status}    Failure using ${query_name} for ${item_name}
    Set To Dictionary   ${nc_ids}   ${item_name}=${id}

Get Product Id And Tariff Id For Generic Main Product
    [Documentation]     Robot keyword to Get Prod Id And Tariff Id For Main Product
    [Arguments]    ${plan_name}
    ${nc_ids}   Create Dictionary  
    Set Test Variable  ${nc_ids}
    ${modified_plan_name}=    Run Keyword If    '${plan_name}' == 'Clásica 30'   Set Test Variable    ${given_plan_name}    Clasica 30
    ...    ELSE IF    '${COUNTRY_CODE}' == 'MX'    Catenate    ${plan_name}    -    MX
    ...    ELSE    Set Test Variable    ${given_plan_name}    ${plan_name}
    Run Keyword If    '${COUNTRY_CODE}' == 'MX'    Set Test Variable    ${given_plan_name}    ${modified_plan_name}

    Log     ${given_plan_name}
    ${subproducts}   copy.deepcopy   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SUBPRODUCTS] 
    Set To Dictionary   ${subproducts}   internet=${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INTERNET_NAME]
    Set To Dictionary  ${subproducts}[internet]   tariffName=${given_plan_name}

    :FOR   ${kind}  IN  @{subproducts.keys()}
    \     Run Keyword   Query NC For Id   queryNcTariffTable   ${subproducts}[${kind}][tariffName]
    \     Run Keyword   Query NC For Id   getProductId   ${subproducts}[${kind}][name] 

    [return]   ${nc_ids}
    
Get Product Id And Tariff Id For Main Product
    [Documentation]     Robot keyword to Get Prod Id And Tariff Id For Main Product
    [Arguments]    ${plan_name}
    Run Keyword If    '${plan_name}' == 'Clásica 30'    Set Test Variable    ${given_plan_name}    Clasica 30    ELSE    Set Test Variable    ${given_plan_name}    ${plan_name}
    ${status}    ${main_product_tariff_id}    useSpbNcApi    queryNcTariffTable    ${given_plan_name}    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${contract_tariff_id}    useSpbNcApi    queryNcTariffTable    12 Month Contract - 30/mo ETF    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${discount_tariff_id}    useSpbNcApi    queryNcTariffTable    €10 off for 3 months    ${COUNTRY_CODE}
    Should Be True    ${status}

    ${status}    ${main_product_id}    useSpbNcApi    getProductId    EU Internet    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${contract_product_id}    useSpbNcApi    getProductId    Contract    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${discount_product_id}    useSpbNcApi    getProductId    Discount    ${COUNTRY_CODE}
    Should Be True    ${status}

    [return]   ${main_product_tariff_id}  ${contract_tariff_id}   ${discount_tariff_id}  ${main_product_id}   ${contract_product_id}  ${discount_product_id}

Get Product Id And Tariff Id For Norway Main Product
    [Documentation]     Robot keyword to Get Prod Id And Tariff Id For Main Product
    [Arguments]    ${given_plan_name}
    ${status}    ${main_product_tariff_id}    useSpbNcApi    queryNcTariffTable    ${given_plan_name}    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${contract_tariff_id}    useSpbNcApi    queryNcTariffTable    12 Month Contract    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${equipment_lease_tariff_id}    useSpbNcApi    queryNcTariffTable    Equipment Lease Fee    ${COUNTRY_CODE}
    Should Be True    ${status}

    ${status}    ${main_product_id}    useSpbNcApi    getProductId    EU Internet    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${contract_product_id}    useSpbNcApi    getProductId    Contract    ${COUNTRY_CODE}
    Should Be True    ${status}
    ${status}    ${equipment_lease_product_id}    useSpbNcApi    getProductId    Lease Fee - Monthly    ${COUNTRY_CODE}
    Should Be True    ${status}

    [return]   ${main_product_tariff_id}  ${contract_tariff_id}   ${equipment_lease_tariff_id}  ${main_product_id}   ${contract_product_id}  ${equipment_lease_product_id}

Validate Product Details from NC Response
    [Documentation]     Robot keyword to Validate Product Details from NC Response for things like spb category, account, id, cust ref, subcription id, product id, tariff id, prod instance id
    [Arguments]    ${product_rows}   ${expected_values}   ${expected_product_instance_id}
    ${expected_product_kind}   Get From List   ${expected_values}  0
    ${expected_spb_cat}   Get From List   ${expected_values}  1
    ${expected_account_id}   Get From List   ${expected_values}  2
    ${expected_cust_ref}   Get From List   ${expected_values}  3
    ${expected_subscription_id}   Get From List   ${expected_values}  4
    ${expected_product_id}   Get From List   ${expected_values}  5
    ${expected_tariff_id}   Get From List   ${expected_values}  6
    :FOR    ${row}    IN    @{product_rows}
    \   Log    ${row}
    \   ${received_wb_ref}   Get From List   ${row}  7
    \   ${received_cust_ref}   Get From List   ${row}  1
    \   ${received_acct_id}   Get From List   ${row}  2
    \   ${received_subscription_id}   Get From List   ${row}  3
    \   ${received_product_id}   Get From List   ${row}  5
    \   ${received_tariff_id}   Get From List   ${row}  6
    \   ${received_name}   Get From List   ${row}  8
    \   Continue For Loop If    '${received_name}' == 'Service Subscription - Tax Inclusive' or '${received_name}' == 'Service Subscription'
    \   Run Keyword If    '${received_wb_ref}' == '${expected_product_instance_id}' or '${received_wb_ref}' == '${expected_product_kind}'   Run Keywords
    \   ...    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_account_id}  ${received_acct_id}    AND
    \   ...    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_cust_ref}  ${received_cust_ref}    AND
    \   ...    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_subscription_id}  ${received_subscription_id}    AND
    \   ...    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_product_id}  ${received_product_id}    AND
    \   ...    Run Keyword And Continue On Failure    Should Be Equal As Strings     ${expected_tariff_id}  ${received_tariff_id}
    [return]     ${received_cust_ref}

Get Ledger Balance From NC DB
    [Documentation]     Robot keyword to Get ledger balance From NC DB
    [Arguments]    ${nc_account_number}
    ${ledger_balance}  ${currency}  useSpbNcApi    getLedgerBalance    ${nc_account_number}
    Should Not Be Equal  ${ledger_balance}   Fail   Unable to obtain ledger balance
    Log To Console  ${ledger_balance}
    [return]    ${ledger_balance}  ${currency}

Get Billing Account From SPB
    [Documentation]   Get Billing Account From SPB
    [Arguments]   ${billing_account_id}
    ${status}   ${spb_account_data}   useSpbApi  getBillingAccountData   ${billing_account_id}
    Should Be True   ${status}    ${spb_account_data}
    [return]    ${spb_account_data}

Get Cust Rel Id From Billing Account
    [Documentation]   Get Cust Rel Id From Billing Account
    [Arguments]   ${billing_account_id}
    ${spb_account_data}    Get Billing Account From SPB    ${billing_account_id}
    Set Test Variable   ${customer_rel_id}   ${spb_account_data}[paymentReference][value]
    [return]    ${customer_rel_id}

Get Physical Payment From NC DB
    [Documentation]     Robot keyword to Get ledger balance From NC DB
    [Arguments]    ${nc_account_number}
    ${physical_payment_mny}  ${payment_method_id}  ${currency_code}  useSpbNcApi    getPhysicalPaymentEntry    ${nc_account_number}
    Should Not Be Equal  {physical_payment_mny}   Fail   Unable to obtain physical payment info
    [return]    ${physical_payment_mny}  ${payment_method_id}  ${currency_code}
        
Create SPB SQS Queue
    [Documentation]     creates a sqs queue to subscribe SPB topic
    ${status}    ${spb_queue_name}    ${spb_subscription_arn}    createQueueAndSubscribe    bepe2etest-spb    ${SPB_SNS_TOPIC}
    Should Be True    ${status}
    Set Suite Variable    ${spb_queue_name}
    Set Suite Variable    ${spb_subscription_arn}
    Log    ${spb_queue_name}

Delele SPB Queue
    [Documentation]     Deletes the queue
    ${status}   ${repsonse}    deleteSubscription     ${spb_subscription_arn}
    Should Be True    ${status}
    ${status}   ${repsonse}    deleteQueue    ${spb_queue_name}
    Should Be True    ${status}

Verify Account Balance
    [Documentation]   compare SPB's getLedgerBalance response to NC data
    [Arguments]   ${billing_account_id}   ${first_payment}=True
    ${ledger_balance}  ${currency}    Get Ledger Balance From NC DB   ${billing_account_id}
    Log   NC ledger balance = ${ledger_balance}
    ${status}   ${spb_account_data}   useSpbApi  getBillingAccountData   ${billing_account_id}
    ${status2}  ${message}   Should Be True   ${status}    ${spb_account_data}
    ${account_group_number}  Set Variable   ${spb_account_data}[accountGroupNumber]
    ${spb_account_balance}  Set Variable    ${spb_account_data}[currentBalance]
    ${value}   Set Variable  ${spb_account_balance}[value]
    Convert To Number    ${value}   2
    Convert To Number    ${advance_payment}   2
    ${current_balance_1000}   Evaluate    ${value} * 1000
    
    # compare SPB account balance to NC account balance
    Should Be Equal   ${current_balance_1000}   ${ledger_balance}   SPB current balance != NC current balance
    
    ${spb_currency}   Set Variable   ${spb_account_balance}[currency]
    :FOR   ${key}   IN  @{EXPECTED_CURRENCY_DICT.keys()}
    \      Should Be Equal   ${EXPECTED_CURRENCY_DICT}[${key}]    ${spb_currency}[${key}]

    #### The rest of the keyword is only applicable if this is the first payment made on the account  ###
    
    ${diff}   Evaluate  ${value}+${advance_payment} 
    # check physicalpayment table
    ${physical_payment_mny}  ${payment_method_id}  ${currency_code}  Get Physical Payment From NC DB   ${account_group_number}   
    ${physical_payment_mny}   Evaluate  ${physical_payment_mny}*-1.0   
    
    #Log   billingCycleDayOfMonth, totalAmountUnbilledOneTimeCharges, nextBillPeriodStartDate not yet implemented   WARN
    #Log   totalAmountUnbilledAdjustments, totalAmountPendingDisputes not applicable
    Run Keyword If   '${first_payment}'=='True'   Run Keywords
    ...   Should Be Equal As Numbers  ${diff}   0.0   SPB account balance does not reflect advance payment   AND
    ...   Should Be Equal   ${spb_currency}[alphabeticCode]   ${currency}   SPB currency != NC account table currency   AND
    ...   Should Be Equal   ${current_balance_1000}   ${physical_payment_mny}    SPB current balance != -NC physical payment   AND
    ...   Should Be Equal   ${spb_currency}[alphabeticCode]  ${currency_code}    SPB currency != NC physical payment currency

Create Payment Request Filename
    [Documentation]   create a payment request filename that consists solely of a timestamp
    [Arguments]   ${request_prefix}  ${payment_request_id}
    ${time}    Get Current Date   UTC  result_format=datetime
    ${timenew}   Convert Date   ${time}   result_format=%Y%m%d%H%M%S
    [return]   ${request_prefix}${payment_request_id}_${timenew}.txt
    
Create Payment Request Entry
    [Documentation]   create a single csv entry for a payment request from NC to SPB
    [Arguments]   ${index_2_currency}   ${index_13_customer_ref}  ${index_14_account_num}  ${index_17_payment_method_id}  ${index_29_customer_ref}  ${index_35_payment_amount}  ${index_37_payment_request_id}
    ${entry}   Set Variable   2.0,${index_2_currency},,,,,,,,,,,${index_13_customer_ref},${index_14_account_num},,,${index_17_payment_method_id},,,,,,,,,,,,${index_29_customer_ref},,,,,,${index_35_payment_amount},,${index_37_payment_request_id},,,,,,,
    [return]   ${entry}
 
Query SPB Batch Request Table
    [Documentation]  Query SPB batch request table for provided filenae
    [Arguments]   ${spb_db_instance}   ${filename}
    ${result}  Call Method    ${spb_db_instance}    queryBatchRequestTable   ${filename}
    Log  queryBatchRequestTable result = ${result}
    ${status}   ${message}   Should Not Be Equal   ${result}   ${None}     Payment request missing from SPB database
    ${status}   ${message}    Run Keyword If   '${result}'!='None'  Should Be Equal  ${result}   Complete   Payment incomplete after waiting period
    [return]  ${status}   ${message}
    
Write File to NC SFTP Server
    [Documentation]   Write a file (as in batch request) to SFTP server
    [Arguments]   ${filename}
    ${status}   ${message}    spb_sftp.putFile   ${filename}
    ${status2}  ${message2}   Should Be True   ${status}   ${message}
    
Get IRA PII File
    [Documentation]  Get files from IRA's S3 bucket for PII
    ${s3_instance}=   Run Keyword   useS3Bucket   ${S3_IRA_PII_FILE_BUCKET} 
    ${result}  Call Method    ${s3_instance}    readFileFromBucket   ${S3_IRA_PII_FILENAME}
    Should Be Equal As Strings   True  ${result}[0]   Could not read file ${S3_IRA_PII_FILENAME}
    @{delimiter_list}   Create List   \r\n   ;
    @{inputList}   Create List   ${result}[1]
    @{outputList}  Create List
    ${content_lists}   bep_common.convertStringToList   ${inputList}  ${delimiter_list}   0   ${outputList}
    [return]  ${content_lists}

Get PSM PII File
    [Documentation]  Get files from PSM's S3 bucket for PII
    ${s3_instance}=   Run Keyword   useS3Bucket   ${S3_PSM_PII_FILE_BUCKET} 
    ${result}  Call Method    ${s3_instance}    readFileFromBucket   ${S3_PSM_PII_FILENAME}
    Should Be Equal As Strings   True  ${result}[0]   Could not read file ${S3_PSM_PII_FILENAME}
    @{delimiter_list}   Create List   \r\n   ;
    @{inputList}   Create List   ${result}[1]
    @{outputList}  Create List
    ${content_lists}   bep_common.convertStringToList   ${inputList}  ${delimiter_list}   0   ${outputList}
    [return]  ${content_lists}

Verify IRA PII Entry
    [Documentation]   given expected billing pii info for one payer role id, verify entry in PII file
    [Arguments]   ${billing_party_info}
    ${pii_entries}   Get IRA PII File
    # BA, payer role id, user name, address line, city, locality, state/province, country, postal code, phone #, email, company name, national id, vat
    ${payer_role_id}   Get From Dictionary   ${billing_party_info}   payer_role_id
    :FOR  ${entry}   IN   @{pii_entries}
    \   Exit For Loop IF   '${entry}[1]'=='${payer_role_id}'
    # verify entry was found
    Should Be Equal As Strings   ${entry}[1]   ${billing_party_info}[payer_role_id]   account not present in billing PII file
    # billing PII has an extra empty field at the end
    Remove From List   ${entry}   -1
    # verify entries are correct
    ${expected_entry}   Create List   BA   ${payer_role_id}   ${billing_party_info}[name]   ${billing_party_info}[address]   ${billing_party_info}[city]   ${billing_party_info}[locality]   ${billing_party_info}[state]
    ...   ${billing_party_info}[country]   ${billing_party_info}[postal_code]   ${billing_party_info}[phone_number]  
    ...    ${billing_party_info}[email_address]   ${billing_party_info}[company_name]   ${billing_party_info}[tin]   ${billing_party_info}[vat]
    ${index}   Set Variable  0
    :FOR   ${item}  IN   @{entry}
    \   Should Be Equal As Strings   ${item}   ${expected_entry}[${index}]    billing pii info: ${item} not equal to ${expected_entry}[${index}]
    \   ${index}   Evaluate   ${index}+1
    
Verify PSM PII Entry
    [Documentation]   given expected service location pii info for one product instance id, verify entry in PII file
    [Arguments]   ${product_instance_location_info}
    ${pii_entries}   Get PSM PII File
    # SA, prod inst id, user name, address line, city, locality, state/province, country, postal code, phone #, email
    ${product_instance_id}   Get From Dictionary   ${product_instance_location_info}   product_instance_id
    :FOR  ${entry}   IN   @{pii_entries}
    \   Exit For Loop IF   '${entry}[1]'=='${product_instance_id}'
    # verify entry was found
    Should Be Equal As Strings   ${entry}[1]   ${product_instance_location_info}[product_instance_id]   product instance id not present in service location PII file
    # PII has an extra empty field at the end
    Remove From List   ${entry}   -1
    # verify entries are correct
    ${expected_entry}   Create List   SA   ${product_instance_id}   ${product_instance_location_info}[name]   ${product_instance_location_info}[address]   ${product_instance_location_info}[city]
    ...   ${product_instance_location_info}[locality]   ${product_instance_location_info}[state]
    ...   ${product_instance_location_info}[country]   ${product_instance_location_info}[postal_code]   ${product_instance_location_info}[phone_number]  
    ...    ${product_instance_location_info}[email_address]
    ${index}   Set Variable  0
    # the following items in the list are optional - for now 2 (name) is in the process of becoming optional.
    ${optionals}   Create List   2   5   6   7   8   9   10
    :FOR   ${item}  IN   @{entry}
    \   ${exp}   Set Variable  ${expected_entry}[${index}] 
    \   ${status}   ${message}   Run Keyword And Ignore Error  Should Be Equal As Strings   ${item}   ${exp}   billing pii info: ${item} not equal to ${expected_entry}[${index}]
    \   ${str_index}  Convert To String   ${index}
    \   ${status2}   ${message2}  Run Keyword If    '${status}'=='FAIL'   Run Keywords
    ...   List Should Contain Value  ${optionals}   ${str_index}   AND
    ...   Should Be Equal As Strings  ${item}  ${EMPTY}   ${item}!=${exp}
    \   ${index}   Evaluate   ${index}+1    
    
Get Subproduct From Netcracker By SubId
    [Documentation]   Each subproduct has 3 entries in the custproductattrdetails table,  with product_attribute_subid values of 7,8, and 10.
    ...  For example for the service contract, the product_attribute_subid:attribute_value combos are
    ...   7:SERVICE_CONTRACT   8:4ef2f3bd-47c4-4572-9bba-e9c8d50fc833   10:Fixed Satellite 12 Mo Contract CFS
    ...   This keyword takes as input the product_attribute_subid, status (eg OK, PE), and account number (500x) and returns all of the matching subproducts
    [Arguments]    ${subid}   ${status}   ${account_num}
    ${response}    getSubproductsByAttributeId   ${subid}   ${status}   ${account_num}
    Should Be Equal As Strings   ${response}[0]   Pass   ${response}[1]
    [return]   ${response}[1]
    
Get Subproduct From Netcracker By Name
    [Documentation]   Like "Get Subproduct From Netcracker By SubId" but search by attribute value and return all items with same product id and account number
    ...   This keyword takes as input the attribute value, status (eg OK, PE), and account number (500x) 
    [Arguments]    ${attribute_value}   ${status}   ${account_num}
    ${response}    getSubproductsByAttributeValue   ${attribute_value}   ${status}   ${account_num}
    Should Be Equal As Strings   ${response}[0]   Pass   ${response}[1]
    [return]   ${response}[1]
    
Verify SPB New Balance
    [Documentation]   Get balance from SPB and compare to expected
    [Arguments]   ${account}   ${expected_balance}
    ${spb_after}   Get Billing Account From SPB   ${account}
    ${spb_balance_after}    Set Variable   ${spb_after}[currentBalance][value]
    ${spb_balance_after}   Convert To Number  ${spb_balance_after}
    Should Be Equal As Numbers  ${expected_balance}   ${spb_balance_after}   SPB balance does not equal expected value after refund
    [return]   ${spb_balance_after}
    
Verify SPB Recurring Payment Method
    [Documentation]   Query SPB and verify recurring payment method is updated
    [Arguments]   ${account}   
    ${spb_result}   Get Billing Account From SPB   ${account}
    Should Be Equal As Strings   ${spb_result}[recurringPaymentMethodType]   ${new_recurring_payment_method}

Get Billing Accounts By Payer Role Id And Creation Date
    [Documentation]  Given list of payer role ids and date window, find all accounts
    [Arguments]    ${payer_role_ids}   ${creation_date_earliest}   ${creation_date_latest}
    ${accounts}   getAccountNumbersByPayerRoleIds   ${payer_role_ids}   ${creation_date_earliest}   ${creation_date_latest}
    [return]  ${accounts}   

Verify Next Bill Date
    [Documentation]  given the account's activation date, the current date, and the country, determine what should be in the nextBillPeriodStartDate field
    ...   ${activation_date} = day of month. This keyword assumes next bill date is within one month, so will not work for accounts that have been billed ahead.
    [Arguments]   ${billing_account_id}  ${activation_date}
    
    ${activation_date}  stringToInt   ${activation_date}
    # determine day of month for bill
    ${bill_dates}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][BILL_DATES]
    ${number_bill_dates}   Get Length   ${bill_dates}
    Append To List  ${bill_dates}   ${28}
    ${last_interval}   Evaluate  ${number_bill_dates}-1
    ${one}   Create List   ${1}
    ${all_dates}   Combine Lists   ${one}  ${bill_dates}
    Log To Console  bill dates = ${all_dates}

    :FOR    ${i}    IN RANGE    ${number_bill_dates}
    \   Set Test Variable  ${interval}   ${i}
    \   Run Keyword If   ${all_dates}[${i}] <= ${activation_date} < ${all_dates}[${i+1}]    Exit For Loop
    \   Set Test Variable  ${interval}  ${None} 

    #Run Keyword If  ${activation_date}==${all_dates}[${i+1}]   Set Test Variable  ${interval}   ${last_interval}
    Run Keyword If  ${interval}==${None}  Set Test Variable  ${interval}  0
    ${bill_date}   Set Variable  ${bill_dates}[${interval}]
    ${bill_date}  stringToInt   ${bill_date}
    Log  BILL DATE = ${bill_date}
  
    # get current date
    ${day_of_month}   Get Current Date   UTC   result_format=%d
    ${month}   Get Current Date   UTC   result_format=%m
    ${year}   Get Current Date   UTC   result_format=%Y
    ${day_of_month}   stringToInt   ${day_of_month}
    ${month}   stringToInt  ${month}
    ${year}   stringToInt  ${year}
    
    # adjust year and month of next bill date if necessary
    ${month_incr}  Set Variable If  ${day_of_month}>=${bill_date}   1  0
    ${month}  Evaluate  ${month}+${month_incr}
    ${year}  Run Keyword If  ${month}==13  Evaluate  ${year}+1
    ...  ELSE  Set Variable  ${year}
    ${month}  Set Variable If  ${month}==13   1  ${month}
    
    ${month}  numberToString   ${month} 
    ${year}  numberToString   ${year}     
    ${bill_date}  numberToString   ${bill_date} 
    
    ${next_bill_period_start_date}   Set Variable  ${year}-${month}-${bill_date}
    Log  next bill date = ${next_bill_period_start_date}
    
    ${status}  ${result}   useSpbApi  getBillingAccountData    ${billing_account_id}
    Should Be Equal As Strings  ${status}   True   getBillingAccountData to SPB failed
    Log   billData = ${result}
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${result}[nextBillPeriodStartDate]   ${next_bill_period_start_date}
    
 Retrieve Payment Type Info
    [Documentation]   Get prmandate update boolean and RB payment method id  
    [Arguments]  ${payment_method}
    ${result}  getRbPaymentMethodInfo   ${payment_method}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INVOICING_ORGANIZATION]
    Convert To List  ${result}[0]
    ${create_prmandate}   Set Variable   ${result}[0][0]
    ${payment_method_id}   Set Variable   ${result}[0][1]
    ${payment_method_name}   Set Variable   ${result}[0][2]
    [return]   ${create_prmandate}   ${payment_method_id}   ${payment_method_name}

Create Generic PID Mapping For Main And Subproducts
    [Documentation]   for each product/subproduct, create a list of identifying info to compare to NC contents
    ...   Goal is to product something like (Norway example, could be different for each country having other subproducts)
    ...   productMapping = {
    ...   highLevelProdInstanceId:[internetKind, highLevelSpbCat,billingAccountId, ncCustomerRef, subscriptionId, mainProdId, mainProdTariffId],
    ...   contractProdInstanceId:[contractKind, contractSpbCat,billingAccountId, ncCustomerRef, subscriptionId, contractProdId, contractTariffId],
    ...   equipmentLeaseProdInstanceId:[equipmentLeaseKind, equipmentLeaseSpbCat,billingAccountId,ncCustomerRef, subscriptionId, equipmentLeaseProdId, equipmentLeaseTariffId]}
    [Arguments]    ${billing_account_id}  ${subscription_id}  ${nc_customer_ref}   ${product_instance_id}   ${high_level_spb_category}  ${nc_ids}   ${spb_price_dict}

    ${main_product_id}   Get From Dictionary  ${nc_ids}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PRODUCT_PLAN]
    ${main_product_tariff_id}   Get From Dictionary  ${nc_ids}   ${given_plan_name}
    ${main_list}   Create List   ${INTERNET_KIND}   ${high_level_spb_category}   ${billing_account_id}   ${nc_customer_ref}   ${subscription_id}    ${main_product_id}  ${main_product_tariff_id}
    ${product_mapping}   Create Dictionary      ${product_instance_id}=${main_list}
        
    ${spb_price_dict_copy}   copy.deepcopy   ${spb_price_dict}
    # we don't want OTCs here
    ${otcs}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]
    :FOR  ${item}   IN  @{otcs.keys()}
    \   Remove From Dictionary  ${spb_price_dict_copy}   ${item}
    
    ${empty_list}   Create List

    :FOR  ${kind}  IN  @{spb_price_dict_copy.keys()}
    \      Set Test Variable  ${name}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SUBPRODUCTS][${kind}][name]
    \      Set Test Variable  ${tariff_name}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SUBPRODUCTS][${kind}][tariffName]
    \      ${new_list}   copy.deepcopy  ${empty_list}              
    \      Append To List  ${new_list}    ${kind}   ${spb_price_dict_copy}[${kind}]  ${billing_account_id}  ${nc_customer_ref}  ${subscription_id}  ${nc_ids}[${name}]   ${nc_ids}[${tariff_name}]
    \      Set Test Variable  ${pid}   ${prod_instance_dict}[${kind}]
    \      Set To Dictionary  ${product_mapping}   ${pid}=${new_list}
    [return]   ${product_mapping}
    

    
    
    