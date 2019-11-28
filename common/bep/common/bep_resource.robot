*** Settings ***
Documentation     A bep resource file with reusable keywords and variables.
...               The system specific keywords created here form our own
...               domain specific language.
Resource     ../common/resource.robot
Library      String
Library      ../../vps/vps_api.py
Library     ../../../python_libs/s3lib.py
Library     ./bep_resource.py
Resource    ../spb/spb_resource.robot

*** Keywords ***
Log Response
    [Documentation]    This keyword is for pretty print response of graphql quries.
    [Arguments]    ${result}
    ${json_string}=    evaluate    json.dumps(${result})    json
    ${response}    To Json    ${json_string}    pretty_print=True
    Log    ${response}

Select Random CC
    ${method}    Evaluate  random.choice($VPS_CC_SELECTIONS)  random
    [return]   ${method}

Select Random External Id Type
    ${method}    Evaluate  random.choice($IRA_EXTERNAL_ID_SELECTIONS)  random
    [return]   ${method}

Select Random Any Payment Type
    ${methods}  Set Variable   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PAYMENT_METHODS]
    ${method}    Evaluate  random.choice($methods)  random
    [return]   ${method}

Set Random OTP Method
    #type is CC, SEPA or ACH, method is specific CC (Visa etc), SEPA, ACH
    ${method}   Run Keyword If  '${VPS_PAYMENT_TYPE_OTP}[${COUNTRY_CODE}]'=='CC'   Select Random CC  
    ...   ELSE   Select Random Any Payment Type  
    [return]   ${method}

Generate A GUID
    ${result}=   common_library.generateGuid
    [return]    ${result}

Set and Get Payment Methods
    [Documentation]   Return default or random payment methods, depending on randomization settings
    ${random_method}   Set Random OTP Method
    ${otp_method}   Set Variable If  '${RANDOMIZE_OTP}'=='True'   ${random_method}    ${VPS_PAYMENT_METHOD}
    ${random_rec_method}    Select Random Any Payment Type
    ${rec_method}   Set Variable If  '${RANDOMIZE_RECURRING_PAYMENT}'=='True'   ${random_rec_method}    ${VPS_RECURRING_PAYMENT_METHOD}
    Log To Console  otp_method=${otp_method}
    Log To Console  rec_method=${rec_method}
    Set Suite Variable  ${VPS_PAYMENT_METHOD}   ${otp_method}
    Set Suite Variable  ${VPS_RECURRING_PAYMENT_METHOD}   ${rec_method}
    [return]   ${otp_method}   ${rec_method}

Set And Get IRA External Id
    [Documentation]   Return default or random external id depending on randomization settings
    ${random_type_name}   Select Random External Id Type
    ${external_id_type}   Set Variable If  '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][RANDOMIZE_IRA_EXTERNAL_ID]'=='True'   ${random_type_name}    ${IRA_EXTERNAL_ID}
    ${external_id_type_name}    ${external_id_value}=    Run Keyword If    '${external_id_type}' == 'VAT'    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][VAT_GENERATOR]
    ...    ELSE IF    '${external_id_type}' == 'TIN'    Run Keyword   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN_GENERATOR]
    Log    IRA external type and values are: ${external_id_type} ${external_id_value}
    Set Suite Variable    ${EXTERNAL_ID_TYPE_NAME}    ${external_id_type_name}
    [return]   ${external_id_type_name}   ${external_id_value}

Use Norway TIN Generator
    ${type}   ${value}   generateNorwayTin
    [return]    ${type}   ${value}

Use Poland TIN Generator
    ${type}   ${value}   generatePolandTin
    [return]    ${type}   ${value}

Use Poland PESEL VAT Generator
    ${type}   ${value}   generatePolandPesel
    [return]    ${type}   ${value}

Use Norway VAT Generator
    ${value}   generateNorwayLegalEntityNumber
    ${value}   Catenate   SEPARATOR=   ${value}   MVA
    # Norway VAT goes to both tin and vat external ids, so push to tin external id here. VAT part rejected by IRA (BEPIRA-275) so skip for now
    ${status}  ${result}   useIraApi   addExternalId  ${party_id}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]   ${value}
    Should Be Equal As Strings   ${status}   True   Could not add Norway MVA string as TIN external ID
    [return]   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][VAT]  ${value}
    #[return]   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]  ${value}

Generate External Id For VAT
    [Documentation]   Generate External Id Value for VAT
    ${value1}    Set Variable If  '${COUNTRY_CODE}'=='ES'   ES   ${EMPTY}
    ${value2}    Generate Random String  8  [NUMBERS]
    ${value}    Set Variable    ${value1}${value2}
    [return]   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][VAT]    ${value}

Generate External Id For TIN
    [Documentation]   Generate External Id Value for VAT
    ${number_length}  Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN_RULES][digits]
    ${letter_length}  Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN_RULES][letters]
    ${value1}    Generate Random String  ${number_length}  [NUMBERS]
    ${value2}    Generate Random String  ${letter_length}  [LETTERS]
    ${value2}    Convert To Uppercase    ${value2}
	${value}    Set Variable    ${value1}${value2}
    [return]   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]    ${value}

Set Country Specific Variables
    [Documentation]    This keyword is to set country specific variables
    
    # VPS instance is country-dependent
    Set Suite Variable   ${VPS_INSTANCE}   ${VPS_INSTANCES}[${COUNTRY_CODE}]
    Set Suite Variable   ${VPS_SYSTEM_NAME}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][VPS_SYSTEM_NAME]
    ${status}   ${message}   Run Keyword And Ignore Error   Dictionary Should Contain Key  ${VPS_INFO}[${VPS_SYSTEM_NAME}]   spbSystemName
    ${SPB_VPS_SYSTEM_NAME}  Set Variable If  '${status}'=='PASS'  ${VPS_INFO}[${VPS_SYSTEM_NAME}][spbSystemName]     ${VPS_SYSTEM_NAME}
    Set Suite Variable    ${SPB_VPS_SYSTEM_NAME}

    ${VPS_INIT_INPUT}   Create Dictionary    vpsSystemName=${VPS_SYSTEM_NAME}
    Set Suite Variable   ${VPS_INIT_INPUT}
    :FOR    ${key}    IN    @{VPS_PAYMENT_METHODS.keys()}
    \   Set To Dictionary   ${VPS_PAYMENT_METHODS}[${key}]   systemName=${VPS_SYSTEM_NAME}
    
    # all countries will have to have the same set of country specific variables even if some are not used by each country
    Set Suite Variable    ${GROUPS}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PROVIDER_GROUP]
    #Set Suite Variable    ${EXTERNAL_ID_TYPE_NAME}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]
    Set Suite Variable    ${SELLER_ID}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][ORG_ID]
 
    Set Suite Variable    ${INTERNET_KIND}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]   
    ${status}   ${message}   Run Keyword And Ignore Error   Dictionary Should Contain Key   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TOTAL_PLANS]    ${INTERNET_KIND}
    ${EXPECTED_TOTAL_PLANS_IN_OFFERS}   Set Variable If   '${status}'=='PASS'   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TOTAL_PLANS][${INTERNET_KIND}]    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TOTAL_PLANS]
    Set Suite Variable    ${EXPECTED_TOTAL_PLANS_IN_OFFERS}   
    Set Suite Variable    ${EXPECTED_SUB_PRODUCT_COUNT}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TOTAL_SUB_PRODUCTS]
    Set Suite Variable    ${EXPECTED_CHILD_PRODUCTS_KIND}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][CHILD_PRODUCTS]
    Set Suite Variable    ${EXPECTED_CURRENCY}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][CURRENCY]
    Set Suite Variable    ${EXPECTED_CURRENCY_DICT}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][CURRENCY_DICT]
    Set Suite Variable    ${INVOICING_ORG}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INVOICING_ORG]

    Set Suite Variable    ${CONTRACT_KIND}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SERVICE_CONTRACT_KIND]
    Set Suite Variable    ${DISCOUNT_KIND}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][DISCOUNT_KIND]
    Set Suite Variable    ${DISCOUNT_KIND}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][DISCOUNT_KIND]
    Set Suite Variable    ${EQUIPMENT_LEASE_FEE_KIND}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][EQUIPMENT_LEASE_FEE_KIND]
    Set Suite Variable    ${CONTRACT_TEMPLATE_ID}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][CONTRACT_TEMPLATE_ID]
    Set Suite Variable    ${INVITE_SIGNER}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INVITE_SIGNER]
    Set Suite Variable    ${SERTIFI_API_CODE}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SERTIFI_API_CODE]
    Set Suite Variable    ${DEALER_ID}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][DEALER_ID]


    ${address}     Run Keyword If    '${REAL_MODEM}' == 'True'
    ...    Evaluate  random.choice(${COUNTRY_VARIABLES}[${COUNTRY_CODE}][REAL_MODEM_ADDRESSES])  random
    ...  ELSE
    ...    Evaluate  random.choice(${COUNTRY_VARIABLES}[${COUNTRY_CODE}][ADDRESSES])  random



    # randomize number of street
    ${random int} =	Evaluate	random.randint(1, 100)	random
    Convert To String   ${random int}
    ${temp}   Catenate   ${address}[addressLine][0]   ${random int}
    Set List Value   ${address}[addressLine]   0   ${temp}
    Set Suite Variable  ${service_address}   ${address}
    
    ${random_address}    Evaluate  random.choice(${COUNTRY_VARIABLES}[${COUNTRY_CODE}][BILLING_ADDRESSES])  random
    ${billing_address}   Set Variable If   '${DIFFERENT_BILLING_ADDRESS}'=='True'   ${random_address}    ${address}
    Set Suite Variable  ${billing_address}
    
    Log     service address = ${service_address}
    Log     billing address = ${billing_address}

    Set Suite Variable    ${ADDRESS_LINE}    ${address}[addressLine]   
    Set Suite Variable    ${CITY}    ${address}[municipality]
    ${status}   ${msg}  Run Keyword And Ignore Error   Dictionary Should Contain Key   ${service_address}   coordinates
    Run Keyword If  '${status}'=='PASS'   Set Suite Variable    ${LATITUDE}    ${service_address}[coordinates][latitude]   
    Run Keyword If  '${status}'=='PASS'   Set Suite Variable    ${LONGITUDE}    ${service_address}[coordinates][longitude]
    ${status}   ${message}   Run Keyword And Ignore Error   Dictionary Should Contain Key   ${address}   region
    Run Keyword If  '${status}'=='PASS'   Set Suite Variable    ${STATE}    ${address}[region]
    ...   ELSE    Set Suite Variable    ${STATE}   ${EMPTY}
    Set Suite Variable    ${POSTAL_CODE}    ${address}[postalCode]   

    # alternate service address format
    ${service_location}   Create Dictionary
    ${address}   Create Dictionary
    ...   addressLine=${service_address}[addressLine]  municipality=${service_address}[municipality]  region=${service_address}[region]
    ...   postalCode=${service_address}[postalCode]  countryCode=${COUNTRY_CODE} 
    Set To Dictionary   ${service_location}   address=${address}
    ${status}   ${message}   Run Keyword And Ignore Error   Dictionary Should Contain Key   ${service_address}   coordinates
    Run Keyword If  '${status}'=='PASS'  Set To Dictionary   ${service_location}   coordinates=${service_address}[coordinates]
    Set Suite Variable   ${service_location} 

    ${LAST_NAME_PREFIX}   Set Variable If  '${UTN}'=='True'   ${TEST_NAME_PREFIX}   ${USERNAME_TEST_NAME_PREFIX}
    ${FULL_NAME}    Generate Random String   1  [UPPER]
    ${FIRST_REST}         Generate Random String   7  [LOWER]
    ${LAST_FIRST}    Set Variable   ${LAST_NAME_PREFIX}
    ${LAST_REST}         Generate Random String   5  [LOWER]
    ${LAST_NAME}     Catenate    SEPARATOR=  ${LAST_FIRST}   ${LAST_REST}
    ${FULL_NAME}     Catenate    SEPARATOR=  ${FULL_NAME}  ${FIRST_REST}  ${SPACE}  ${LAST_NAME} 
    Set Suite Variable   ${FIRST_REST}
    Set Suite Variable   ${LAST_NAME}    
    Set Suite Variable   ${FULL_NAME}
    
    # We only have one address for both customer and billing - if that changes this needs to reflect that
    ${VPS_BILLING_ADDRESS}   Copy Dictionary  ${billing_address}
    Remove From Dictionary  ${VPS_BILLING_ADDRESS}  houseNumberOrName
    Set To Dictionary   ${VPS_BILLING_ADDRESS}   country  ${billing_address}[countryCode]
    Remove From Dictionary  ${VPS_BILLING_ADDRESS}   countryCode
    Set Suite Variable   ${VPS_BILLING_ADDRESS}
    
    ${PHONE_NUMBER}   Generate Random String   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PHONE_NUMBER_LENGTH]   [NUMBERS]
    ${PHONE_NUMBER}   Catenate  SEPARATOR=   +   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][PHONE_COUNTRY_CODE]   ${PHONE_NUMBER}
    Set Suite Variable   ${PHONE_NUMBER}
    
    ${EMAIL_ADDRESS_NAME}   Generate Random String   5
    ${EMAIL_ADDRESS_NAME}   Catenate   SEPARATOR=   ${LAST_NAME_PREFIX}   ${EMAIL_ADDRESS_NAME}
    ${EMAIL_ADDRESS}        Catenate   SEPARATOR=@  ${EMAIL_ADDRESS_NAME}    viasat.com
    Set Suite Variable   ${EMAIL_ADDRESS}
    
    ${customer}   Create Dictionary   firstName=${FIRST_REST}  lastName=${LAST_NAME}    emailAddress=${EMAIL_ADDRESS}   primaryPhoneNumber=${PHONE_NUMBER}
    Set Suite Variable  ${customer}
    
    ${child_prod_kinds}   Create List
     ${otcs}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS] 
    :FOR  ${prod}  IN   @{otcs.keys()}
    \   Run Keyword Unless    '${COUNTRY_CODE}' == 'MX'    Append To List  ${child_prod_kinds}  ${prod}
    ${subproducts}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SUBPRODUCTS] 
    :FOR  ${prod}  IN   @{subproducts.keys()}
    \   Append To List  ${child_prod_kinds}  ${prod}

    Set Suite Variable  ${child_prod_kinds}

    ${MODEM_MAC}    Run Keyword If    '${REAL_MODEM}' == "False"    generateRandomMacAddress
    Set Suite Variable  ${MODEM_MAC}
    Log   ${MODEM_MAC}

Locate Active Customers
    [Documentation]  Find customers from specified country whose last name starts with "Bepe2e_" (but not Bepe2e_az), whose accounts were created within a specified date window,
    ...   and whose NC status=ok .  Date format is yyyy-mm-dd
    [Arguments]   ${country_code}   ${date_end}   ${date_start}=2019-10-18 
    # get PII entries from IRA - payer role id is in 2nd position
    ${result}   getIraPii   Bepe2e   ${country_code}
    
    # search Postgres billing_account table
    ${payer_role_ids}   Create List
    ${payer_role_dict}   Create Dictionary
    :FOR   ${entry}   IN   @{result}
    \   Append To List   ${payer_role_ids}   ${entry}[1]
    ${accounts}   Get Billing Accounts By Payer Role Id And Creation Date   ${payer_role_ids}   ${date_start}  ${date_end}
    
    # NC doesn't allow more than 1000 accounts here (or maybe less?) so truncate results if necessary
    ${accounts_length}   Get Length  ${accounts}
    ${accounts_max}   Set Variable If   ${accounts_length}>500   499     ${accounts_length}
    ${accounts}   Get Slice From List  ${accounts}  0  ${accounts_max}
    
    ${filtered_accounts}   Locate NC Accounts With Filter     ${accounts}   EU Internet
    Should Be Equal As Strings   ${filtered_accounts}[0]   Pass   Customer account retrieval failed with error=${filtered_accounts}[1]
    [return]   ${filtered_accounts}[1]
