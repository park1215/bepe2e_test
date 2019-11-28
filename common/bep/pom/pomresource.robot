*** Settings ***
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Library    OperatingSystem
Library    Process
Library   ./pom_api.py

*** Keywords ***
Get And Validate Offers From POM
    [Documentation]     Robot keyword to get Offers From POM
    [Arguments]    ${buyer_id}=''    ${seller_id}=${SELLER_ID}    ${country_code}=${COUNTRY_CODE}    ${coordinates}=None   ${type}=FIXED_SATELLITE_INTERNET
    Set Test Variable  ${buyer_id}
    ${offers}    Get Offers From POM    ${buyer_id}    ${seller_id}    ${country_code}    ${coordinates}   ${type}
    Run Keyword And Continue On Failure    Validate Get Offers Response     ${offers}   ${type}
    [return]   ${offers}

Get Offers From POM
    [Arguments]     ${buyer_id}=''    ${seller_id}=${SELLER_ID}    ${country_code}=${COUNTRY_CODE}    ${coordinates}=None   ${type}=FIXED_SATELLITE_INTERNET
    ${status}  ${result}    usePomApi    getOffers  ${buyer_id}    ${seller_id}   ${country_code}   ${coordinates}   ${type}
    Log Response    ${result}
    Should Be True    ${status}
    ${offers}=   Set Variable    ${result}[data][getOffers]
    ${offers_list_count}=    Get length    ${offers}
    Should Not Be Equal As Strings      ${offers_list_count}  0    getOffers response is empty list
    [return]   ${offers}
    #[Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Get Discount And Contract Product Type Ids
    [Arguments]    ${offers}   ${selected_offer_id}
    ${products}   Parse Products From Offers For Specific Plan    ${offers}    ${selected_offer_id}
    ${discount_prod_type_id}    Get Product Type Id From POM    ${products}    ${DISCOUNT_KIND}
    ${contract_prod_type_id}    Get Product Type Id From POM    ${products}    ${CONTRACT_KIND}
    [return]   ${discount_prod_type_id}   ${contract_prod_type_id}

Get Cart Item Id And SPB categories From Cart
    [Arguments]    ${cart_id}   ${cart_data}  ${offer_id}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    ${high_level_spb_category}    Get SPB Category For Top Level Product    ${cart_id}
    Log    ${high_level_spb_category}
    ${discount_spb_price_category}    ${discount_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${DISCOUNT_KIND}
    Log    ${discount_spb_price_category}, ${discount_spb_price_category_duration}
    ${contract_spb_price_category}    ${contract_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${CONTRACT_KIND}
    Log    ${contract_spb_price_category}, ${contract_spb_price_category_duration}
    Set Test Variable   ${high_level_spb_category}
    Set Test Variable   ${discount_spb_price_category}
    Set Test Variable   ${contract_spb_price_category}
    [return]    ${cart_item_id}    ${high_level_spb_category}   ${discount_spb_price_category}  ${contract_spb_price_category}

Get Cart Item Id And SPB categories From Cart For Norway
    [Arguments]    ${cart_id}   ${cart_data}  ${offer_id}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    ${high_level_spb_category}    Get SPB Category For Top Level Product    ${cart_id}
    Log    ${high_level_spb_category}
    ${equipment_lease_spb_price_category}    ${equipment_lease_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${EQUIPMENT_LEASE_FEE_KIND}
    Log    ${equipment_lease_spb_price_category}, ${equipment_lease_spb_price_category_duration}
    ${contract_spb_price_category}    ${contract_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${CONTRACT_KIND}
    Log    ${contract_spb_price_category}, ${contract_spb_price_category_duration}
    Set Test Variable   ${high_level_spb_category}
    Set Test Variable   ${equipment_lease_spb_price_category}
    Set Test Variable   ${contract_spb_price_category}
    [return]    ${cart_item_id}    ${high_level_spb_category}   ${equipment_lease_spb_price_category}  ${contract_spb_price_category}
    
Get Cart Item Id And SPB Price Categories From Cart
    [Documentation]     get SPB price category for main and for given list of child products based on kind, returns list with 1st element as high level and same order as inpur list
    [Arguments]    ${cart_id}   ${cart_data}  ${offer_id}  ${child_prod_kinds}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${offer_id}
    ${high_level_spb_category}    Get SPB Category For Top Level Product    ${cart_id}
    Set Suite Variable   ${high_level_spb_category}
    Log    ${high_level_spb_category}
    @{spb_price_categories}   Create List    ${high_level_spb_category}
    ${spb_price_dict}   Create Dictionary
    : FOR    ${child_product}    IN    @{child_prod_kinds}
    \   ${child_product_spb_price_category}    ${child_product_spb_price_category_duration}    Get SPB Category For Child Product    ${cart_id}    ${child_product}
    \   Append To List	${spb_price_categories}	${child_product_spb_price_category}
    \   Set To Dictionary  ${spb_price_dict}   ${child_product}=${child_product_spb_price_category}
    \   Run Keyword If  '${child_product}'=='${CONTRACT_KIND}'   Set Suite Variable  ${contract_spb_price_category}   ${child_product_spb_price_category}
    \   Run Keyword If  '${child_product}'=='${DISCOUNT_KIND}'   Set Suite Variable  ${discount_spb_price_category}   ${child_product_spb_price_category}
    \   Run Keyword If  '${child_product}'=='${EQUIPMENT_LEASE_FEE_KIND}'   Set Suite Variable  ${equipment_lease_spb_price_category}   ${child_product_spb_price_category}
    Log    ${spb_price_dict}
    Set Suite Variable  ${spb_price_dict}
    [return]    ${cart_item_id}    ${spb_price_categories}

Get Advance Payment Info From Offers
    [Documentation]     Robot keyword to Get Advance Payment Info From Offers
    [Arguments]    ${given_plan}   ${once_total}=0
    ${characteristics}    Get Characteristics From Offers    ${given_plan}
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${characteristic_name}    Get From Dictionary    ${characteristic}    name
    \   ${advance_payment}    Run Keyword If    '${characteristic_name}'=='ADVANCE_PAYMENT'    Get From Dictionary    ${characteristic}    value
    \   Run Keyword If    '${characteristic_name}'=='ADVANCE_PAYMENT'     Exit For Loop
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${characteristic_name}    Get From Dictionary    ${characteristic}    name
    \   ${advance_payment_description}    Run Keyword If    '${characteristic_name}'=='ADVANCE_PAYMENT_DESCRIPTION'    Get From Dictionary    ${characteristic}    value
    \   Run Keyword If    '${characteristic_name}'=='ADVANCE_PAYMENT_DESCRIPTION'     Exit For Loop
    # Check for activation fee in cart totals - need to move this keyword past the "cart totals" calculation in all tests so we don't need to check for country code
    ${advance_payment}   Evaluate  ${advance_payment}+${once_total} 
    [return]   ${advance_payment}    ${advance_payment_description}

Verify Price Roll Ups In Cart
    [Documentation]     Robot keyword to Get SPB Category For Top Level Product
    [Arguments]    ${cart_id}    ${advance_payment}=None
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be True	${cart_item_list_count} >= 1
    ${calculated_total}    Add Up Item Prices From Cart    ${cart_id}
    ${cart_total_price}    Get From Dictionary    ${cart_data}    cartTotalPrices
    ${cart_total}    ${currency}   Get Total Price And Currency From Cart    ${cart_total_price}
    Should Contain    ${currency}    ${EXPECTED_CURRENCY}
    Run Keyword And Continue On Failure     Should Be Equal    ${calculated_total}    ${cart_total}
    Run Keyword Unless    '${advance_payment}' == 'None'    Should Be Equal    ${advance_payment}    ${cart_total}

Get SPB Category For Top Level Product
    [Documentation]     Robot keyword to Get SPB Category For Top Level Product by default. If given_kindis provided, get SPB price of that.
    [Arguments]    ${cart_id}    ${given_kind}=None
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cartItems}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item}=   Run Keyword If    '${given_kind}'=='None'    Set Variable    ${cartItems}[0]   ELSE   Get Cart Item Details    ${cartItems}    ${given_kind}
    Log   ${cart_item}
    ${high_level_prices}=   Set Variable    ${cart_item}[product][prices]
    : FOR    ${high_level_price}    IN    @{high_level_prices}
    \   ${name}    Get From Dictionary    ${high_level_price}    name
    \   ${characteristics}    Run Keyword If    '${name}' == 'Package Charge' or '${name}' == 'Buy More Charge' or '${name}' == 'Appointment Charge'    Get From Dictionary    ${high_level_price}    characteristics
    \   ${value}    Run Keyword If    '${name}' == 'Package Charge' or '${name}' == 'Buy More Charge' or '${name}' == 'Appointment Charge'     Iterate And Get Value    ${characteristics}    SPB_PRICE_CATEGORY
    \   Run Keyword If    '${name}' == 'Package Charge' or '${name}' == 'Buy More Charge' or '${name}' == 'Appointment Charge'    Exit For Loop
    [return]   ${value}

Get Cart Item Details
    [Documentation]     Robot keyword to Get Cart Item Details based on given kind
    [Arguments]    ${cart_items}   ${given_kind}
    : FOR    ${cart_item}    IN    @{cart_items}
    #\   Run Keyword If    '${cart_item}[product][kind]'=='${given_kind}'    Exit For Loop
    \   Return From Keyword If    '${cart_item}[product][kind]' == '${given_kind}'    ${cart_item}
    #[return]   ${cart_item}

Get Product Type Id From getOffers
    [Documentation]     Robot keyword to Get Product Type Id From getOffers for a given plan
    [Arguments]    ${given_plan}   ${buyer_id}    ${seller_id}   ${country_code}   ${coordinates}=${None}
    ${offers}    Get Offers From POM   ${buyer_id}    ${seller_id}   ${country_code}   ${coordinates}
    : FOR    ${offer}    IN    @{offers}
    \   ${offer_name}    Get From Dictionary    ${offer}    name
    \   ${product_type_id}    Run Keyword If    '${offer_name}'=='${given_plan}'    Get From Dictionary    ${offer}    id
    \   Run Keyword If    '${offer_name}'=='${given_plan}'     Exit For Loop
    [return]   ${product_type_id}
    
Get SPB Category For Child Product
    [Documentation]     Robot keyword to get SPB category for a given child product, input this can be either DISCOUNT or SERVICE_CONTRACT. This returns "duration" for DISCOUNT
    [Arguments]    ${cart_id}   ${child_product_kind}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${item}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_items}=   Set Variable    ${item}[0]
    ${products}=   Set Variable    ${cart_items}[product][products]
    ${spb_price_category}  Set Variable  0
    ${spb_price_category_duration}  Set Variable  0
    : FOR    ${product}    IN    @{products}
    \   ${kind}    Get From Dictionary    ${product}    kind
    \   ${sub_products}     Get From Dictionary    ${product}    products
    \   ${sub_products_length}    Get Length   ${sub_products}
    \   ${kind} =	Set Variable If    '${kind}' == 'OPTION_GROUP'	 ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][EQUIPMENT_LEASE_FEE_KIND]	${kind}
    \   Log    ${kind}
    \   Log   ${child_product_kind}
    \   Continue For Loop If    '${kind}' != '${child_product_kind}'
    \   ${prices}     Get From Dictionary    ${product}    prices
    \   ${prices_length}    Get Length   ${prices}
    \   Run Keyword If  ${prices_length}>0    Run Keywords
    \   ...    Set Test Variable   ${prices_field}    ${prices}[0]   AND
    \   ...    Set Test Variable   ${characteristics}   ${prices_field}[characteristics]  
    \   ${spb_price_category}    Run Keyword If    ('${child_product_kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][EQUIPMENT_LEASE_FEE_KIND]' and ${sub_products_length}>0)     Iterate Through Option Group Products    ${sub_products}    ELSE    Iterate And Get Value    ${characteristics}    SPB_PRICE_CATEGORY
    \   ${spb_price_category_duration}    Run Keyword If    '${child_product_kind}' == '${DISCOUNT_KIND}'    Iterate And Get Value    ${characteristics}    Duration
    [return]   ${spb_price_category}    ${spb_price_category_duration}

Iterate Through Option Group Products
    [Documentation]     Iterates through option group sub-product to get SPB cat of selected lease option.
    [Arguments]    ${sub_products}
    Log    ${MONTHLY_LEASE_OPTION}
    ${expected_name} =	Set Variable If    '${MONTHLY_LEASE_OPTION}' == 'True'    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][MONTHLY_LEASE_NAME]    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][LIFETIME_LEASE_NAME]
    : FOR    ${sub_product}    IN    @{sub_products}
    \   Set Test Variable   ${characteristics}    ${sub_product}[prices][0][characteristics]
    \   Set Test Variable   ${name}    ${sub_product}[name]
    \   ${spb_cat}    Run Keyword If    '${name}' =='${expected_name}'    Iterate And Get Value    ${characteristics}   SPB_PRICE_CATEGORY
    \   Run Keyword If    '${name}' =='${expected_name}'    Set Suite Variable   ${EQUIPMENT_LEASE_PRICE}    ${sub_product}[prices][0][amount][value]
    \   Run Keyword If    '${name}' =='${expected_name}'    Exit For Loop
    Log    ${spb_cat}
    [return]   ${spb_cat}

Iterate And Get Value
    [Documentation]     Generalized Robot keyword to value from given list, assumes input is list of dict with "name" and "value"
    [Arguments]    ${items_list}   ${key}
    : FOR    ${item}    IN    @{items_list}
    \   ${name}    Get From Dictionary    ${item}    name
    \   ${value}    Run Keyword If    '${name}' == '${key}'    Get From Dictionary    ${item}    value
    \   Run Keyword If    '${name}' == '${key}'    Exit For Loop
     [return]   ${value}

Get Characteristics From Offers
    [Documentation]     Robot keyword to Get Characteristics From Offers
    [Arguments]    ${given_plan}
    ${status}   ${msg}   Run Keyword And Ignore Error  Dictionary Should Contain Key  ${service_location}   coordinates  
    ${offers}  Run Keyword If  '${status}'=='PASS'  Get Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}   ${service_location}[coordinates]
    ...   ELSE  Run Keyword   Get Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}  
    : FOR    ${offer}    IN    @{offers}
    \   ${offer_name}    Get From Dictionary    ${offer}    name
    \   ${characteristics}    Run Keyword If    '${offer_name}'=='${given_plan}'    Get From Dictionary    ${offer}    characteristics
    \   Run Keyword If    '${offer_name}'=='${given_plan}'     Exit For Loop
    [return]   ${characteristics}

Verify Buy More Plans
    [Documentation]     Robot keyword to Verify Buy More plans for a given plan
    [Arguments]    ${given_plan}    ${buyer_id}=''    ${seller_id}=${SELLER_ID}    ${country_code}=${COUNTRY_CODE}    ${coordinates}=None
    ${expected_buy_more_count}    getBuyMorePlanFromRequirement  ${given_plan}    ${country_code}
    ${product_type_id}    Get Product Type Id From getOffers    ${given_plan}  ${buyer_id}    ${seller_id}   ${country_code}   ${coordinates}
    ${status}  ${result}    usePomApi    getOffersBuyMore    ${given_plan}    ${product_type_id}    ${country_code}
    Log Response    ${result}
    Should Be True    ${status}
    ${buymore}=   Set Variable    ${result}[data][buymore]
    ${buymore_count}    Get length    ${buymore}
    Should Be Equal As Strings      ${buymore_count}    ${expected_buy_more_count}    buy more plan count should be ${expected_buy_more_count} instead of ${buymore_count}

Get Buy More Plans
    [Documentation]     Robot keyword to get Buy More plans for a given plan
    [Arguments]    ${given_plan}    ${given_product_type_id}
    ${status}  ${result}    usePomApi    getOffersBuyMore    ${given_plan}    ${given_product_type_id}    ${COUNTRY_CODE}
    Log Response    ${result}
    Should Be True    ${status}
    ${buymore_plans}=   Set Variable    ${result}[data][buymore]
    [return]   ${buymore_plans}

Select Random Buy More Plan
    [Documentation]     Robot keyword to get and select random Buy More plan for a given plan
    [Arguments]    ${given_plan}    ${given_product_type_id}
    ${buymore_plans}    Get Buy More Plans  ${given_plan}    ${given_product_type_id}
    ${selected_plan}    Evaluate  random.choice($buymore_plans)  random
    Log    ${selected_plan}
    ${buymore_plan_id}=   Set Variable    ${selected_plan}[id]
    ${buymore_plan_name}=   Set Variable    ${selected_plan}[name]
    [return]   ${buymore_plan_id}    ${buymore_plan_name}

Verify Get Offer Fails For Not Supported Country
    [Documentation]     Robot keyword to get Offers From POM
    [Arguments]    ${buyer_id}    ${seller_id}    ${country_code}    ${lat}=None   ${long}=None
    ${status}  ${result}    usePomApi    getOffers  ${buyer_id}    ${seller_id}   ${country_code}    ${lat}    ${long}
    Log Response    ${result}
    Should Be True    ${status}
    ${offers}=   Set Variable    ${result}[data][getOffers]
    ${offers_legth}=    Get length    ${offers}
    Should Be Equal As Strings      ${offers_legth}  0

Validate Get Offers Response
    [Documentation]     Robot keyword to validate get Offers response From POM (should not have buy more and detail validation of each plan)
    [Arguments]    ${offers}   ${type}=FIXED_SATELLITE_INTERNET
    ${offers_list_count}=    Get length    ${offers}
    ${expected_total_offers}   Set Variable If  '${type}'=='FULFILLMENT'   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TOTAL_PLANS][FULFILLMENT]    ${EXPECTED_TOTAL_PLANS_IN_OFFERS}
    Run Keyword And Continue On Failure    Should Be Equal As Strings      ${offers_list_count}    ${expected_total_offers}    getOffers response does not have the correct count of offers
    #Run Keyword If   '${type}'=='FULFILLMENT'   Run Keyword And Continue On Failure   Validate Fulfillment Offers   ${offers}
    : FOR    ${offer}    IN    @{offers}
    \   ${offer_name}    Get From Dictionary    ${offer}    name
    \   Run Keyword And Continue On Failure    Should Not Contain    ${offer_name}    Bono
    \   Run Keyword If   '${type}'=='${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]'   Run Keyword And Continue On Failure    Validate Individual Plan    ${offer_name}    ${offer}
    \   Run Keyword If   '${type}'=='FULFILLMENT'   Run Keyword And Continue On Failure   Validate Fulfillment Offers   ${offer}

Validate Fulfillment Offers
    [Documentation]   Check plans retrieved with type=fulfillment
    [Arguments]   ${offer}
    #${offers_length}   Get Length  ${offers}
    #${exp_offers_length}   Get Length  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_OFFERS]
    #Should Be Equal As Integers   ${offers_length}   ${exp_offers_length}
    ${expected_offers}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_OFFERS]
    #:FOR  ${offer}  IN  @{offers}
    #\   Validate One Fulfillment Offer  ${offer}
    ${id}=   Set Variable    ${offer}[id]
    ${name}=   Set Variable    ${offer}[name]
    Log    ${name}
    Run Keyword If     '${name}'=='Cargo por Activaci贸n'    Set Test Variable    ${name}    Cargo por Activación
    ${kind}=   Set Variable    ${offer}[kind]
    ${expected_fo_product_id}    getFOProductIdFromRequirement   ${name}
    ${characteristics}=   Set Variable    ${offer}[characteristics]
    ${products}=   Set Variable    ${offer}[products]
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${kind}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]
    Run Keyword And Continue On Failure    Should Contain Any	${name}    @{expected_offers}
    #${installation_product}    Run Keyword And Return Status    Should Contain    ${name}    Cargo por
    #Run Keyword If   ${installation_product}    Set Test Variable    ${INSTALLATION_PRODUCT_TYPE_ID}   ${id}
    Run Keyword If   '${name}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INSTALLATION_PRODUCT_NAME]'    Set Suite Variable    ${INSTALLATION_PRODUCT_TYPE_ID}   ${id}
    Run Keyword If   '${name}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INSTALLATION_PRODUCT_NAME]'    Set Suite Variable    ${INSTALLATION_FEE}   ${offer}[prices][0][amount][value]
    Run Keyword If   '${name}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INSTALLATION_PRODUCT_NAME]'    Set Suite Variable    ${INSTALLATION_PRODUCT_NAME}   ${name}
    Run Keyword And Continue On Failure   Verify Fulfillment Characteristics    ${characteristics}    ${name}
    Run Keyword And Continue On Failure   Verify Fulfillment Offer FO Product Id    ${products}[0][characteristics]      ${expected_fo_product_id}
    ${expected_price}    getProductRateFromRequirement    ${INSTALLATION_PRODUCT_NAME}
    Run Keyword And Continue On Failure    Should Be Equal    ${expected_price}    ${INSTALLATION_FEE}
    Set Suite Variable    ${INSTALLATION_PRODUCT_TYPE_ID}
    Set Suite Variable    ${INSTALLATION_FEE}
    Set Suite Variable    ${INSTALLATION_PRODUCT_NAME}

Verify Fulfillment Characteristics
    [Documentation]   Validates one offer at top level only
    [Arguments]   ${characteristics}   ${expected_name}
    :FOR  ${characteristic}  IN  @{characteristics}
    \   ${name}=   Set Variable    ${characteristic}[name]
    \   ${value}=   Set Variable    ${characteristic}[value]
    \   Run Keyword If   '${name}'=='PSM_REQUIRES_RELATIONSHIP'   Run Keyword And Continue On Failure    Should Be Equal As Strings   ${value}   FULFILLS
    \   Run Keyword If   '${name}'=='PSM_PRODUCT_KIND'   Run Keyword And Continue On Failure    Should Be Equal As Strings   ${value}   FULFILLMENT

Validate One Fulfillment Offer
    [Documentation]   Validates one offer at top level only 
    [Arguments]   ${offer}
    ${expected_offers}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_OFFERS]
    :FOR   ${exp_offer}   IN  @{expected_offers.keys()}
    \     Exit For Loop If   '${exp_offer}'=='${offer}[name]'
    Should Be Equal As Strings   ${exp_offer}   ${offer}[name]
    ${exp_offer_params}   Set Variable  ${expected_offers}[${exp_offer}]
    :FOR  ${key}   IN    @{exp_offer_params.keys()}
    \   Should Be Equal As Strings  ${exp_offer_params}[key]   ${offer}[key]  

Verify Fulfillment Offer FO Product Id
    [Documentation]   Verify Fulfillment Offer FO Product Id from characteristics
    [Arguments]   ${characteristics}    ${expected_fo_product_id}
    :FOR  ${characteristic}  IN  @{characteristics}
    \   ${name}=   Set Variable    ${characteristic}[name]
    \   ${value}=   Set Variable    ${characteristic}[value]
    \   Run Keyword If   '${name}'=='FO_PRODUCT_ID'   Run Keyword And Continue On Failure    Should Be Equal As Strings   ${value}   ${expected_fo_product_id}
    \   Run Keyword If   '${name}'=='FO_PRODUCT_ID'    Exit For Loop

Get Contract Term For A Given Plan
    [Documentation]     Robot keyword to validate get Offers response From POM (should not have buy more and detail validation of each plan)
    [Arguments]    ${plan_name}
    ${offers}    Get Offers From POM
    : FOR    ${offer}    IN    @{offers}
    \   ${offer_name}    Get From Dictionary    ${offer}    name
    \   Run Keyword And Continue On Failure    Should Not Contain    ${offer_name}    Bono
    \   ${characteristics}    Run Keyword If    '${offer_name}' == "${plan_name}"   Get From Dictionary    ${offer}    characteristics
    \   ${value}    Run Keyword If    '${offer_name}' == "${plan_name}"   Iterate And Get Value    ${characteristics}    CONTRACT_TERM
    \   Run Keyword If    '${offer_name}' == "${plan_name}"    Exit For Loop
    [return]   ${value}

Validate Individual Plan
    [Documentation]     Robot keyword to validate individual plan (validates name, contract and discount render)
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword IF       "${COUNTRY_CODE}" == 'MX'         Validate Mexico Plan    ${plan_name}    ${plan_details}
    ...        ELSE IF   '${COUNTRY_CODE}'=='NO'           Validate Norway Plans    ${plan_name}    ${plan_details}
    ...        ELSE IF   '${COUNTRY_CODE}'=='ES'           Validate Spain Plans    ${plan_name}    ${plan_details}
    ...        ELSE IF   '${COUNTRY_CODE}'=='PL'           Validate Poland Plans    ${plan_name}    ${plan_details}
    ...  ELSE
    ...    Log    UNKNOWN COUNTRY   WARN

Validate Spain Plans
    [Documentation]     Robot keyword to validate individual plan (validates name, contract and discount render)
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword IF       "${plan_name}" == 'Clásica 30'         Validate Clasica 30 Plan    ${plan_name}    ${plan_details}
    ...        ELSE IF   '${plan_name}'=='Ilimitada 30'         Validate Ilimitada 30 Plan    ${plan_name}    ${plan_details}
    ...        ELSE IF   '${plan_name}'=='Ilimitada 50'         Validate Ilimitada 50 Plan    ${plan_name}    ${plan_details}

Validate Norway Plans
    [Documentation]     Robot keyword to validate individual plan (validates name, contract and discount render)
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword And Continue On Failure    Validate Child Products For NO    ${plan_name}    ${plan_details}
    Validate Characteristics Of Product   ${plan_name}    ${plan_details}

Validate Poland Plans
    [Documentation]     Robot keyword to validate individual plan (validates name, contract and discount render)
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword And Continue On Failure    Validate Child Products For PL    ${plan_name}    ${plan_details}
    Validate Characteristics Of Product   ${plan_name}    ${plan_details}

Validate Child Products For NO
    [Documentation]     Robot keyword to validate child products and PSM kinds
    [Arguments]    ${plan_name}    ${plan_details}
    ${products}    Get From Dictionary    ${plan_details}    products
    ${product_list_count}=    Get length    ${products}
    Should Be Equal As Strings      ${product_list_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      getOffers response does not have the correct count of sub products for ${plan_name}, it should be ${EXPECTED_SUB_PRODUCT_COUNT} instead of ${product_list_count}
    : FOR    ${product}    IN    @{products}
    \   ${kind}    Get From Dictionary    ${product}    kind
    \   Run Keyword And Continue On Failure    Should Contain Any	${kind}    @{EXPECTED_CHILD_PRODUCTS_KIND}
    \   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == 'FIXED_SATELLITE_SERVICE'    Validate Satellite Service Details For EU    ${product}
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'SERVICE_CONTRACT'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Fixed Satellite 12 Mo Contract CFS
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'ACTIVATION_FEE'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Setup Fee
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'EQUIPMENT_LEASE_FEE'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Fixed Satellite Monthly Lease Fee

Validate Child Products For PL
    [Documentation]     Robot keyword to validate child products and PSM kinds
    [Arguments]    ${plan_name}    ${plan_details}
    ${products}    Get From Dictionary    ${plan_details}    products
    ${product_list_count}=    Get length    ${products}
    Should Be Equal As Strings      ${product_list_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      getOffers response does not have the correct count of sub products for ${plan_name}, it should be ${EXPECTED_SUB_PRODUCT_COUNT} instead of ${product_list_count}
    : FOR    ${product}    IN    @{products}
    \   ${kind}    Get From Dictionary    ${product}    kind
    \   Run Keyword And Continue On Failure    Should Contain Any	${kind}    @{EXPECTED_CHILD_PRODUCTS_KIND}
    \   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == 'FIXED_SATELLITE_SERVICE'    Validate Satellite Service Details For EU    ${product}
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'SERVICE_CONTRACT'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Fixed Satellite 24 Mo Contract CFS
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'DISCOUNT'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Recurring Discount
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'ACTIVATION_FEE'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Setup Fee
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'EQUIPMENT_LEASE_FEE'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Fixed Satellite Monthly Lease Fee

Validate Child Products
    [Documentation]     Robot keyword to validate child products
    [Arguments]    ${plan_name}    ${plan_details}
    ${products}    Get From Dictionary    ${plan_details}    products
    ${product_list_count}=    Get length    ${products}
    Should Be Equal As Strings      ${product_list_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      getOffers response does not have the correct count of sub products for given plan ${plan_details}
    : FOR    ${product}    IN    @{products}
    \   ${kind}    Get From Dictionary    ${product}    kind
    \   Run Keyword And Continue On Failure    Should Contain Any	${kind}    @{EXPECTED_CHILD_PRODUCTS_KIND}
    \   Run Keyword And Continue On Failure    Run Keyword Unless      '${kind}' == 'FIXED_SATELLITE_SERVICE'    Validate Characteristics Of Child Product   ${product}

Validate Child Products For MX
    [Documentation]     Robot keyword to validate child products and PSM kinds
    [Arguments]    ${plan_name}    ${plan_details}
    ${products}    Get From Dictionary    ${plan_details}    products
    ${product_list_count}=    Get length    ${products}
    Should Be Equal As Strings      ${product_list_count}    ${EXPECTED_SUB_PRODUCT_COUNT}      getOffers response does not have the correct count of sub products for ${plan_name}, it should be ${EXPECTED_SUB_PRODUCT_COUNT} instead of ${product_list_count}
    ${expected_sism_product_id}    getSISMProductIdFromRequirement   ${plan_name}
    : FOR    ${product}    IN    @{products}
    \   ${kind}    Get From Dictionary    ${product}    kind
    \   Run Keyword And Continue On Failure    Should Contain Any	${kind}    @{EXPECTED_CHILD_PRODUCTS_KIND}
    \   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == 'FIXED_SATELLITE_SERVICE'    Validate Satellite Service Details For MX   ${product}    ${expected_sism_product_id}
    \   Run Keyword And Continue On Failure    Run Keyword If      '${kind}' == 'SERVICE_CONTRACT'    Validate Child Product Details   ${product}  BILLING    DEPENDS_ON   Fixed Satellite 12 Mo Contract CFS
    #################### Following is TBD until design is finalized ################
    #\   Run Keyword And Continue On Failure    Run Keyword Unless      '${kind}' == 'OPTION_GROUP'    Validate Equipment Lease Details For MX   ${product}


Validate Satellite Service Details For EU
    [Documentation]     Robot keyword to validate child products and PSM kinds
    [Arguments]    ${product}
    ${characteristics}    Get From Dictionary    ${product}    characteristics
    ${characteristics_count}=    Get length    ${characteristics}
    Run Keyword And Ignore Error    Should Be Equal As Strings      ${characteristics_count}    2      getOffers response missing characetristics for FIXED_SATELLITE_SERVICE ${characteristics}
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${name}    Get From Dictionary    ${characteristic}    name
    \   ${value}    Get From Dictionary    ${characteristic}    value
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == 'PSM_PRODUCT_KIND'    Should Be Equal As Strings      ${value}    NONE    In getOffers response PSM_PRODUCT_KIND for FIXED_SATELLITE_SERVICE is ${value} instead of NONE
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == 'PSM_PRODUCT_RELATIONSHIP'    Should Be Equal As Strings      ${value}    CONFIGURES    In getOffers response PSM_PRODUCT_RELATIONSHIP for FIXED_SATELLITE_SERVICE is ${value} instead of CONFIGURES


Validate Satellite Service Details For MX
    [Documentation]     Robot keyword to validate child products and PSM kinds
    [Arguments]    ${product}    ${expected_sism_product_id}
    ${characteristics}    Get From Dictionary    ${product}    characteristics
    ${characteristics_count}=    Get length    ${characteristics}
    Run Keyword And Continue On Failure    Should Be Equal As Strings      ${characteristics_count}    3      getOffers response missing characetristics for FIXED_SATELLITE_SERVICE ${characteristics}
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${name}    Get From Dictionary    ${characteristic}    name
    \   ${value}    Get From Dictionary    ${characteristic}    value
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == 'PSM_PRODUCT_KIND'    Should Be Equal As Strings      ${value}    NONE    In getOffers response PSM_PRODUCT_KIND for FIXED_SATELLITE_SERVICE is ${value} instead of NONE
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == 'PSM_PRODUCT_RELATIONSHIP'    Should Be Equal As Strings      ${value}    CONFIGURES    In getOffers response PSM_PRODUCT_RELATIONSHIP for FIXED_SATELLITE_SERVICE is ${value} instead of CONFIGURES
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == 'SISM_PRODUCT_ID'    Should Be Equal As Strings      ${value}    ${expected_sism_product_id}    In getOffers response SISM_PRODUCT_ID for FIXED_SATELLITE_SERVICE is ${value} instead of ${expected_sism_product_id}

Validate Characteristics Of Child Product
    [Documentation]     Robot keyword to validate Characteristics Of Product (PSM_PRODUCT_KIND and PSM_PRODUCT_RELATIONSHIP)
    [Arguments]    ${child_product}
    ${characteristics}    Get From Dictionary    ${child_product}    characteristics
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${name}    Get From Dictionary    ${characteristic}    name
    \   ${psm_relantionship_value}    Run Keyword And Continue On Failure    Run Keyword If    '${name}' == "PSM_PRODUCT_RELATIONSHIP"   Get From Dictionary    ${characteristic}    value
    \   Run Keyword If    '${name}' == "PSM_PRODUCT_RELATIONSHIP"    Should Be Equal As Strings    ${psm_relantionship_value}    DEPENDS_ON
    \   ${psm_kind_value}    Run Keyword And Continue On Failure    Run Keyword If    '${name}' == "PSM_PRODUCT_KIND"   Get From Dictionary    ${characteristic}    value
    \   Run Keyword If    '${name}' == "PSM_PRODUCT_KIND"    Should Be Equal As Strings    ${psm_kind_value}    BILLING

Validate Child Product Details
    [Documentation]     Robot keyword to validate Characteristics Of Product (PSM_PRODUCT_KIND and PSM_PRODUCT_RELATIONSHIP)
    [Arguments]    ${child_product}  ${expected_psm_product_kind}    ${expected_psm_product_relationship}   ${expected_child_offer_name}
    ${characteristics}    Get From Dictionary    ${child_product}    characteristics
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${name}    Get From Dictionary    ${characteristic}    name
    \   ${value}    Get From Dictionary    ${characteristic}    value
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == "PSM_PRODUCT_KIND"    Should Be Equal As Strings    ${value}    ${expected_psm_product_kind}    In getOffers response PSM_PRODUCT_KIND for SERVICE_CONTRACT is ${value} instead of BILLING
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == "PSM_PRODUCT_RELATIONSHIP"    Should Be Equal As Strings    ${value}    ${expected_psm_product_relationship}    In getOffers response PSM_PRODUCT_RELATIONSHIP for SERVICE_CONTRACT is ${value} instead of DEPENDS_ON
    \   Run Keyword And Continue On Failure    Run Keyword If    '${name}' == "OFFER_NAME"    Should Be Equal As Strings    ${value}    ${expected_child_offer_name}    In getOffers response OFFER_NAME for SERVICE_CONTRACT is ${value} instead of Fixed Satellite 12 Mo Contract CFS

Validate Data Cap
    [Documentation]     Robot keyword to validate data cap
    [Arguments]    ${plan_name}    ${given_data_cap}
    ${expected_data_cap}    getDataCapFromRequirement   ${plan_name}    ${COUNTRY_CODE}
    Log    expected_data_cap is: ${expected_data_cap}
    Should Be Equal As Strings    ${given_data_cap}    ${expected_data_cap}

Validate Contract Term
    [Documentation]     Robot keyword to Validate Contract Term
    [Arguments]    ${plan_name}    ${given_contract_term}
    ${expected_contract_term}    getContractTermFromRequirement   ${plan_name}   ${COUNTRY_CODE}
    Log    expected_contract_term is: ${expected_contract_term}
    Should Be Equal As Strings    ${given_contract_term}    ${expected_contract_term}
    Set Suite Variable    ${CONTRACT_TERM}    ${given_contract_term}

Validate Download Speed
    [Documentation]     Robot keyword to Validate Download Speed
    [Arguments]    ${plan_name}    ${given_download_speed}
    ${expected_download_speed}    getDownloadSpeedFromRequirement   ${plan_name}    ${COUNTRY_CODE}
    Log    expected_download_speed is: ${expected_download_speed}
    Should Be Equal As Strings    ${given_download_speed}    ${expected_download_speed}

Validate Upload Speed
    [Documentation]     Robot keyword to Validate Download Speed
    [Arguments]    ${plan_name}    ${given_upload_speed}
    ${expected_upload_speed}    getUploadSpeedFromRequirement   ${plan_name}    ${COUNTRY_CODE}
    Log    expected_upload_speed is: ${expected_upload_speed}
    Should Be Equal As Strings    ${given_upload_speed}    ${expected_upload_speed}

Validate Characteristics Of Product
    [Documentation]     Robot keyword to validate Characteristics Of Product (data cap, contract term, download speed)
    [Arguments]    ${plan_name}    ${plan_details}
    ${characteristics}    Get From Dictionary    ${plan_details}    characteristics
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${name}    Get From Dictionary    ${characteristic}    name
    \   ${value}    Get From Dictionary    ${characteristic}    value
    \   Run Keyword If    '${name}' == "DATA_CAP_GB"    Run Keyword And Continue On Failure   Validate Data Cap    ${plan_name}    ${value}
    \   Run Keyword If    '${name}' == "CONTRACT_TERM"    Run Keyword And Continue On Failure   Validate Contract Term  ${plan_name}    ${value}
    \   Run Keyword If    '${name}' == "DOWNLOAD_RATE"    Run Keyword And Continue On Failure   Validate Download Speed  ${plan_name}    ${value}
    \   Run Keyword If    '${name}' == "UPLOAD_RATE"    Run Keyword And Continue On Failure   Validate upload Speed  ${plan_name}    ${value}
    \   Run Keyword If    '${name}' == "PSM_PRODUCT_KIND"    Run Keyword And Continue On Failure   Should Be Equal As Strings    ${value}    ${INTERNET_KIND}
    \   Run Keyword If    ("${COUNTRY_CODE}" == "MX" and "${name}" == "SERVICE_DELIVERY_PARTNER")    Validate Service Delivery Partner For MX Product    ${plan_name}    ${value}

Validate Service Delivery Partner For MX Product
    [Documentation]     Robot keyword to Validate Service Delivery Partner For MX Product
    [Arguments]    ${plan_name}    ${received_service_delivery_partner}
    ${expected_service_delivery_partner}    getServiceDeliveryPartnerFromRequirement   ${plan_name}
    Log    expected_service_delivery_partner is: ${expected_service_delivery_partner}
    Should Be Equal As Strings    ${received_service_delivery_partner}    ${expected_service_delivery_partner}

Validate Clasica 30 Plan
    [Documentation]     Robot keyword to validate classica 30 plan
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword And Continue On Failure    Validate Child Products    ${plan_name}    ${plan_details}
    Validate Characteristics Of Product   ${plan_name}    ${plan_details}

Validate Ilimitada 30 Plan
    [Documentation]     Robot keyword to validate Ilimitada 30 plan
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword And Continue On Failure    Validate Child Products    ${plan_name}    ${plan_details}
    Validate Characteristics Of Product   ${plan_name}    ${plan_details}

Validate Ilimitada 50 Plan
    [Documentation]     Robot keyword to validate Ilimitada 50 plan
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword And Continue On Failure    Validate Child Products    ${plan_name}    ${plan_details}
    Validate Characteristics Of Product   ${plan_name}    ${plan_details}

Validate Mexico Plan
    [Documentation]     Robot keyword to validate Viasat 12 Mbps plan
    [Arguments]    ${plan_name}    ${plan_details}
    Run Keyword And Continue On Failure    Validate Child Products For MX    ${plan_name}    ${plan_details}
    Validate Characteristics Of Product   ${plan_name}    ${plan_details}


Generate Random Cart Name
    [Documentation]     Robot keyword to generate random cart name
    ${value} =  Generate Random String  5  [NUMBERS]
    ${updated_cart_name} =	Catenate	SEPARATOR=	 BEPE2E's Cart	${value}
    Log   CART NAME IS ${updated_cart_name}
    [return]   ${updated_cart_name}

Get Product Type Id From POM
    [Documentation]    get prod type if for given product/sub-product filtering by kind
    [Arguments]     ${products}    ${kind}
    ${prod_type_id}    getProductTypeIdByKind    ${products}    ${kind}
    [return]   ${prod_type_id}

Parse Products From Offers For Specific Plan
    [Documentation]    Parse Products From Offers For Specific given Plan
    [Arguments]     ${offers}    ${given_offer_id}
    : FOR    ${offer}    IN    @{offers}
    \   ${offer_id}    Get From Dictionary    ${offer}    id
    \   ${products}    Run Keyword If    '${offer_id}' == '${given_offer_id}'    Get From Dictionary    ${offer}    products
    \   Run Keyword If    '${offer_id}' == '${given_offer_id}'    Exit For Loop
    [return]   ${products}

Select Random Offer From GetOffers
    [Documentation]     Robot keyword to get select random offer From get offers response of POM. Filters are optional, and filter OUT
    [Arguments]    ${offers}   ${filters}=${None}
    ${filters}   Run Keyword If  ${filters}==${None}   Create List
    ...   ELSE  Set Variable  ${filters}
    @{offer_ids}=    Create List
    @{offer_names}=    Create List
    ${sel_status}  ${sel_msg}   Run Keyword And Ignore Error  Should Not Be Equal As Strings   ${SELECTED_PLAN}   None
    : FOR    ${offer}    IN    @{offers}
    \   #Log   offer is ${offer}
    \   ${offer_id}    Get From Dictionary    ${offer}    id
    \   ${offer_name}    Get From Dictionary    ${offer}    name
    \   ${status}   ${msg}   Run Keyword And Ignore Error  List Should Contain Value  ${filters}  ${offer_name}
    \   Continue For Loop If  '${status}'=='PASS'
    \   Append To List    ${offer_ids}    ${offer_id}
    \   Append To List    ${offer_names}    ${offer_name}
    \   Exit For Loop If  '${sel_status}'=='PASS' and '${offer_name}'=='${SELECTED_PLAN}'

    Log    Final List of IDS is ${offer_ids}
    Log    Final List of names is ${offer_names}
    # if selected plan exists and was found, use that
    ${selected_offer}    Run Keyword If  ('${sel_status}'=='PASS' and '${offer_name}'=='${SELECTED_PLAN}')  Set Variable   ${offer_id}
    ...   ELSE     Evaluate  random.choice($offer_ids)  random
    ${index}	Get Index From List	${offer_ids}	${selected_offer}
    ${selected_name}    Get From List    ${offer_names}    ${index}

    [return]   ${selected_offer}    ${selected_name}

Get Cart Item Id from Cart Item List
    [Documentation]     Robot keyword to get high level cart item id from cart
    [Arguments]    ${cart_items}    ${expected_offer_id}
    : FOR    ${cart_item}    IN    @{cart_items}
    \   Log   offer is ${cart_item}
    \   ${offer_id}=   Set Variable    ${cart_item}[product][id]
    \   ${cart_item_id}    Run Keyword If    "${expected_offer_id}"=="${offer_id}"    Get From Dictionary    ${cart_item}    id
    \   Run Keyword If    "${expected_offer_id}"=="${offer_id}"    Exit For Loop
    Log    ${cart_item_id}
    [return]   ${cart_item_id}

Get Offers & Add In Cart One By One
    [Documentation]     Robot keyword to get offers. Add each offer in separate cart and validate it's being added
    [Arguments]    ${buyer_id}    ${seller_id}    ${country_code}
    ${offers}    Get Offers From POM    ${buyer_id}    ${seller_id}    ${country_code}
    : FOR    ${offer}    IN    @{offers}
    \   Log   offer is ${offer}
    \   ${offer_id}    Get From Dictionary    ${offer}    id
    \   Log   offer id is ${offer_id}
    \   ${value} =  Generate Random String  5  [NUMBERS]
    \   ${updated_cart_name} =	Catenate	SEPARATOR=	test	${value}
    \   Log    updated_cart_name: ${updated_cart_name}
    \   ${cart_id}    Add Cart With Item    ${updated_cart_name}    ${buyer_id}    ${seller_id}    ${offer_id}
    \   Log   cart id is ${cart_id}}
    \   ${cart_data}    Get The Cart Data    ${cart_id}
    \   Log    Cart Data is ${cart_data}
    \   ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    \   ${cart_item_list_count}=    Get length    ${cart_items}
    \   Log    cart_item_list_count ${cart_item_list_count}
    \   Run Keyword And Continue On Failure    Should Be Equal As Strings      ${cart_item_list_count}  1
    \  # Log    **********************************************************     WARN

Update And Verify Cart Status To Accepted
   [Documentation]     Robot keyword to change cart status to accpted, aslo verifies.
   [Arguments]    ${cart_id}     ${cart_status}
    ${result}    Update Cart Status To Accepted     ${cart_id}    ${cart_status}
    ${response}=   Set Variable    ${result}[data][addOrUpdateCart]
    ${cart_status}    Get From Dictionary    ${response}    status
    Log    ${cart_status}
    Should Contain    ${cart_status}    ACCEPTED    Cart Is Not In Accepted State ${result}
    #[Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Add Items In Existing Cart
    [Documentation]     Robot keyword to Add Items In The Cart
    [Arguments]    ${empty_cart_id}     ${buyer_id}    ${seller_id}    ${cart_item_id}
    ${status}  ${result}    usePomApi    addOrUpdateExistingCart  ${empty_cart_id}     ${buyer_id}    ${seller_id}    ${cart_item_id}
    Should Be True    ${status}
    Log Response    ${result}
    [return]   ${result}

Delete Items From Cart
    [Documentation]     Robot keyword to delete Items From Cart
    [Arguments]    ${cart_id}  ${cart_item_id}
    Log To Console    delete Items From Cart
    ${status}  ${result}    usePomApi    deleteCartItem  ${cart_id}  ${cart_item_id}
    Should Be True    ${status}
    Log Response    ${result}

Add Cart With Item
    [Documentation]     Robot keyword to Create And Add Items In Cart
    [Arguments]    ${cart_name}    ${buyer_id}    ${seller_id}    ${cart_item_id}     ${cart_item_id2}=None
    ${status}  ${result}    usePomApi    addOrUpdateCart  ${cart_name}    ${buyer_id}    ${seller_id}    ${cart_item_id}   ${cart_item_id2}
    Log Response    ${result}
    ${status2}   ${message}   Should Be True    ${status}   addOrUpdateCart response from POM is ${result}
    ${response}=   Set Variable    ${result}[data][addOrUpdateCart]
    ${cart_id}    Get From Dictionary    ${response}    id
    [return]   ${cart_id}
    #Log     ${KEYWORD_STATUS}    WARN
    #[Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Add Cart With Item And Verify Cart
    [Documentation]     Robot keyword to Create And Add Items In Cart and validates the cart
    [Arguments]    ${buyer_id}    ${seller_id}    ${offer_id}    ${plan_name}   ${offer_id2}=None
    ${updated_cart_name}    Generate Random Cart Name
    Log   buyer id is: ${buyer_id}
    ${cart_id}    Add Cart With Item    ${updated_cart_name}    ${buyer_id}    ${seller_id}    ${offer_id}    ${offer_id2}
    Log    NEW CART ID is ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be True	${cart_item_list_count} >= 1
    ${buy_more_product}    Run Keyword And Return Status    Should Contain    ${plan_name}   Bono
    ${cart_item_price}    Run Keyword If   ${buy_more_product}    Validate Buy More Price In Cart    ${cart_id}    ${plan_name}    ELSE    Run Keyword And Continue On Failure    Verify Main Product Price And Discount In Cart    ${cart_id}    ${plan_name}
    Set Suite Variable    ${cart_item_price}
    [return]   ${cart_id}

Verify Main Product Price And Discount In Cart
    [Documentation]     Robot keyword to Verify Price And Discount In Cart based on country code
    [Arguments]    ${cart_id}    ${plan_name}
    ${cart_price}     Run Keyword IF       "${COUNTRY_CODE}" == 'ES'         Verify Price And Discount In Cart For EU    ${cart_id}    ${plan_name}
    ...        ELSE IF   '${COUNTRY_CODE}'=='MX'            Verify Price And Product Candidate Graph In Cart For MX    ${cart_id}    ${plan_name}
    ...        ELSE IF   '${COUNTRY_CODE}'=='NO'            Verify Price In Cart For NO    ${cart_id}    ${plan_name}
    ...        ELSE IF   '${COUNTRY_CODE}'=='PL'            Verify Price And Discount In Cart For EU    ${cart_id}    ${plan_name}

Verify Price And Discount In Cart For EU
    [Documentation]     Robot keyword to Verify Price And Discount In Cart
    [Arguments]    ${cart_id}    ${plan_name}
    ${cart_price}    Validate Price In Cart    ${cart_id}    ${plan_name}
    Validate Discount In Cart    ${cart_id}    ${plan_name}
    Validate Currency In Cart    ${cart_id}
    [return]   ${cart_price}

Verify Price In Cart For NO
    [Documentation]     Robot keyword to Verify Price And Discount In Cart
    [Arguments]    ${cart_id}    ${plan_name}
    ${cart_price}    Validate Price In Cart    ${cart_id}    ${plan_name}
    Validate Currency In Cart    ${cart_id}
    [return]   ${cart_price}

Verify Price And Product Candidate Graph In Cart For MX
    [Documentation]     Robot keyword to Verify Price And Discount In Cart
    [Arguments]    ${cart_id}    ${plan_name}
    ${cart_price}    Run Keyword And Continue On Failure    Validate Price In Cart    ${cart_id}    ${plan_name}
    Run Keyword And Continue On Failure    Validate Currency In Cart    ${cart_id}
    ${product_candidate_ids_dict}    Run Keyword And Continue On Failure    Validate Product Candidate Graph In Cart    ${cart_id}
    [return]    ${cart_price}

Validate Product Candidate Graph In Cart
    [Documentation]     Robot keyword to Validate Currency In Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cartItems}=   Set Variable    ${cart_data}[cartItems]
    : FOR    ${cartItem}    IN    @{cartItems}
    \   ${kind}=   Set Variable    ${cartItem}[product][kind]
    \   ${productCandidateGraph}=   Set Variable    ${cartItem}[productCandidateGraph]
    \   Run Keyword If    '${kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]'    Exit For Loop
    #Set Test Variable   ${productCandidates}   ${productCandidateGraph}[productCandidates]
    ${productCandidates}    Get From Dictionary    ${productCandidateGraph}    productCandidates
    ${relationships}    Get From Dictionary    ${productCandidateGraph}    relationships
    ${product_candidate_ids_dict}   Create Dictionary
    ${destination_product_candidate_id}    Get Product Candidate Id    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]    ${productCandidates}
    Set To Dictionary  ${product_candidate_ids_dict}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]=${destination_product_candidate_id}
    ${service_product_candidate_id}    Get Product Candidate Id    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_SERVICE_KIND]    ${productCandidates}
    Set To Dictionary  ${product_candidate_ids_dict}   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_SERVICE_KIND]=${service_product_candidate_id}
    : FOR    ${sub_product}    IN    @{EXPECTED_CHILD_PRODUCTS_KIND}
    \    ${product_candidate_id}    Get Product Candidate Id    ${sub_product}    ${productCandidates}
    \    Set To Dictionary  ${product_candidate_ids_dict}   ${sub_product}=${product_candidate_id}
    Log    ${product_candidate_ids_dict}
    :FOR  ${sub_product_kind}  IN  @{product_candidate_ids_dict.keys()}
    \  ${src_pc_id}  get from dictionary  ${product_candidate_ids_dict}  ${sub_product_kind}
    \   Validate Product Candidate Relationships In Cart    ${destination_product_candidate_id}   ${src_pc_id}   ${relationships}    ${sub_product_kind}
    : FOR    ${cartItem}    IN    @{cartItems}
    \   ${kind}=   Set Variable    ${cartItem}[product][kind]
    \   ${ff_productCandidates}=   Set Variable    ${cartItem}[productCandidateGraph][productCandidates]
    \   Run Keyword If    '${kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]'    Exit For Loop
    : FOR    ${ff_productCandidate}    IN    @{ff_productCandidates}
    \   ${kind}=   Set Variable    ${ff_productCandidate}[kind]
    \   ${id}=   Set Variable    ${ff_productCandidate}[id]
    \   Set To Dictionary  ${product_candidate_ids_dict}   ${kind}=${id}
    Set Suite Variable    ${product_candidate_ids_dict}
    [return]    ${product_candidate_ids_dict}

Get Product Candidate Id
    [Documentation]    Get Product Cadidate Id from cartItems->productCandidateGraph->productCandidates
    [Arguments]    ${input_kind}    ${productCandidates}
    : FOR    ${productCandidate}    IN    @{productCandidates}
    \   ${product_candidate_id}=   Set Variable    ${productCandidate}[id]
    \   ${kind}=   Set Variable    ${productCandidate}[kind]
    \   Run Keyword If    '${kind}' == '${input_kind}'    Exit For Loop
    Run Keyword And Continue On Failure    Should Not Be Equal    ${product_candidate_id}   None
    [return]    ${product_candidate_id}

Validate Product Candidate Relationships In Cart
    [Documentation]    Validates product candidate relationships in cart
    [Arguments]    ${destination_product_candidate_id}   ${src_pc_id}   ${relationships}    ${sub_product_kind}
    : FOR    ${relationship}    IN    @{relationships}
    \   ${relationshipType}=   Set Variable    ${relationship}[relationshipType]
    \   ${destinationId}=   Set Variable    ${relationship}[destinationId]
    \   ${sourceId}=   Set Variable    ${relationship}[sourceId]
    \   ${expected_relationtype}=    Run Keyword If    '${sub_product_kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_SERVICE_KIND]'       Set Variable    CONFIGURES    ELSE    Set Variable    DEPENDS_ON
    \   Run Keyword If    '${sourceId}' == '${src_pc_id}'    Run Keyword And Continue On Failure    Should Be Equal As Strings      ${destinationId}    ${destination_product_candidate_id}
    \   Run Keyword If    '${sourceId}' == '${src_pc_id}'    Run Keyword And Continue On Failure    Should Be Equal As Strings      ${expected_relationtype}    ${relationshipType}
    \   Run Keyword If    '${sourceId}' == '${src_pc_id}'       Exit For Loop

Validate Currency In Cart
    [Documentation]     Robot keyword to Validate Currency In Cart
    [Arguments]    ${cart_id}
    ${currency}    Get Currency From Cart    ${cart_id}
    Should Be Equal As Strings      ${EXPECTED_CURRENCY}    ${currency}

Validate Price In Cart
    [Documentation]     Robot keyword to Validate Price In Cart
    [Arguments]    ${cart_id}    ${plan_name}
    ${expected_price}     getPlanRateFromRequirement   ${plan_name}   ${COUNTRY_CODE}
    ${cart_item_price}    Get Item Price From Cart    ${cart_id}
    Should Be Equal As Strings      ${expected_price}    ${cart_item_price}
    [return]    ${cart_item_price}

Validate Buy More Price In Cart
    [Documentation]     Robot keyword to Validate Buy More Price In Cart
    [Arguments]    ${cart_id}    ${plan_name}
    ${expected_price}     getPlanRateFromRequirement   ${plan_name}    ${COUNTRY_CODE}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${item}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item}=   Set Variable    ${item}[0]
    ${high_level_prices}=   Set Variable    ${cart_item}[product][prices]
    : FOR    ${high_level_price}    IN    @{high_level_prices}
    \   ${name}    Get From Dictionary    ${high_level_price}    name
    \   ${amount}    Run Keyword If    '${name}' == 'Buy More Charge'    Get From Dictionary    ${high_level_price}    amount
    \   ${cart_item_price}    Run Keyword If    '${name}' == 'Buy More Charge'    Get From Dictionary    ${amount}    value
    \   Run Keyword If    '${name}' == 'Buy More Charge'    Exit For Loop
    Should Be Equal As Strings      ${expected_price}    ${cart_item_price}
    [return]    ${cart_item_price}

Validate Discount In Cart
    [Documentation]     Robot keyword to Validate Discount In Cart
    [Arguments]    ${cart_id}    ${plan_name}
    ${expected_discount}     getDiscountRateFromRequirement  ${plan_name}   ${COUNTRY_CODE}
    ${discount_price}    Get Discount Price From Cart    ${cart_id}
    Should Be Equal As Strings      ${expected_discount}    ${discount_price}

Get Currency From Cart
    [Documentation]     Robot keyword toGet Currency From Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cartTotalPrices}    Get From Dictionary    ${cart_data}    cartTotalPrices
    : FOR    ${cartTotalPrice}    IN    @{cartTotalPrices}
    \   ${kind}    Get From Dictionary    ${cartTotalPrice}    kind
    \   ${amount}    Run Keyword If    '${kind}' == 'SUBTOTAL'    Get From Dictionary    ${cartTotalPrice}    amount
    \   ${currency}    Run Keyword If    '${kind}' == 'SUBTOTAL'    Get From Dictionary    ${amount}    currency
    \   ${currency_name}    Run Keyword If    '${kind}' == 'SUBTOTAL'    Get From Dictionary    ${currency}    name
    \   Run Keyword If    '${kind}' == 'SUBTOTAL'    Exit For Loop
    [return]   ${currency_name}

Get Discount Price From Cart
    [Documentation]     Robot keyword to Get Discount Price From Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${item}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_items}=   Set Variable    ${item}[0]
    ${products}=   Set Variable    ${cart_items}[product][products]
    : FOR    ${product}    IN    @{products}
    \   ${name}    Get From Dictionary    ${product}    name
    \   ${prices}    Run Keyword If    '${name}' == 'Recurring Discount'    Get From Dictionary    ${product}    prices
    \   Run Keyword If    '${name}' == 'Recurring Discount'    Set Test Variable   ${prices_field}    ${prices}[0]
    \   ${amount}    Run Keyword If    '${name}' == 'Recurring Discount'    Get From Dictionary    ${prices_field}    amount
    \   ${value}    Run Keyword If    '${name}' == 'Recurring Discount'    Get From Dictionary    ${amount}    value
    \   Run Keyword If    '${name}' == 'Recurring Discount'    Exit For Loop
    ${value}   Set Variable If   ${value} is ${None}   0   ${value}
    ${value}   Convert To Integer  ${value}
    [return]   ${value}

Get Fulfillment Product From MX Cart
    [Documentation]     Robot keyword to Get Fulfillment Price From Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cartItems}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_items_count}    Get Length    ${cartItems}
    ${amount}    Run Keyword If    ${cart_items_count}>1    Get Fulfillment Price    ${cartItems}    ELSE    Set Variable    0
    [return]   ${amount}

Get Fulfillment Price
    [Documentation]     Robot keyword to Get Fulfillment Price
    [Arguments]    ${cartItems}
    : FOR    ${cart_item}    IN    @{cart_items}
    \   ${kind}=   Set Variable    ${cart_item}[product][kind]
    \   ${amount}=     Run Keyword If    '${kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]'    Set Variable    ${cart_item}[product][prices][0][amount][value]
    \   Run Keyword If    '${kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]'    Exit For Loop
    Log    ${amount}
    [return]   ${amount}

Get Equipment Lease Price From MX Cart
    [Documentation]     Robot keyword to Get Equipment Lease Price From Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    : FOR    ${cart_item}    IN    @{cart_items}
    \   ${kind}=   Set Variable    ${cart_item}[product][kind]
    \   ${products}=   Set Variable    ${cart_item}[product][products]
    \   Run Keyword If    '${kind}' == '${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]'    Exit For Loop
    : FOR    ${product}    IN    @{products}
    \   ${kind}=   Set Variable    ${product}[kind]
    \   ${name}=   Set Variable    ${product}[name]
    \   ${option_group_products}    Run Keyword If    '${kind}' == 'OPTION_GROUP'    Set Variable    ${product}[products]
    \   Run Keyword If    '${kind}' == 'OPTION_GROUP'    Exit For Loop
    : FOR    ${option_group_product}    IN    @{option_group_products}
    \    ${characteristics}=   Set Variable    ${option_group_product}[prices][0][characteristics]
    \    ${characteristics_length}    Get Length    ${characteristics}
    \    ${amount}=   Run Keyword If    ${characteristics_length} > 1     Set Variable    ${option_group_product}[prices][0][amount][value]   ELSE   Continue For Loop
    \    Run Keyword If    ${characteristics_length} > 1    Exit For Loop
    #${value}   Convert To Integer  ${value}
    [return]   ${amount}

Get SPB Price Category For Option Group
    [Documentation]     Robot keyword Get SPB Price Category For Option Group
    [Arguments]    ${characteristics}
     : FOR    ${characteristic}    IN    @{characteristics}
     \    Get SPB Price Category For Option Group    ${characteristics}

Get Equipment Lease Price From Cart
    [Documentation]     Robot keyword to Get Equipment Lease Price From Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${item}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_items}=   Set Variable    ${item}[0]
    ${products}=   Set Variable    ${cart_items}[product][products]
    : FOR    ${product}    IN    @{products}
    \   ${name}    Get From Dictionary    ${product}    name
    \   ${prices}    Run Keyword If    '${name}' == 'Fixed Satellite Monthly Lease Fee'    Get From Dictionary    ${product}    prices
    \   Run Keyword If    '${name}' == 'Fixed Satellite Monthly Lease Fee'    Set Test Variable   ${prices_field}    ${prices}[0]
    \   ${amount}    Run Keyword If    '${name}' == 'Fixed Satellite Monthly Lease Fee'    Get From Dictionary    ${prices_field}    amount
    \   ${value}    Run Keyword If    '${name}' == 'Fixed Satellite Monthly Lease Fee'    Get From Dictionary    ${amount}    value
    \   Run Keyword If    '${name}' == 'Fixed Satellite Monthly Lease Fee'    Exit For Loop
    ${value}   Set Variable If   ${value} is ${None}   0   ${value}
    ${value}    Run Keyword If    '${value}' == '0'   Convert To Integer  ${value}    ELSE    Set Variable    ${value}
    #${value}   Convert To Integer  ${value}
    [return]   ${value}

Get Equipment Lease Options From Cart
    [Documentation]   Get all lease options
    ${cart_data}    Get The Cart Data    ${cart_id}
    [Arguments]   ${cart_id}
    ${cartItems}    Get From Dictionary    ${cart_data}    cartItems
    : FOR    ${cartItem}    IN    @{cartItems}
    \    Run Keyword If  '${cartItem}[product][kind]'=='${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]'  Run Keywords
    \   ...    Set Test Variable    ${products}    ${cartItem}[product][products]   AND
    \   ...    Exit For Loop
    ${lease_products}   Create List
    : FOR    ${product}    IN    @{products}
    \    Run Keyword If  '${product}[name]'=='Fixed Satellite Lease' and '${product}[kind]'=='OPTION_GROUP'  Run Keywords
    \   ...    Set Test Variable   ${lease_products}   ${product}[products]   AND
    \   ...    Exit For Loop
    ${lease_len}   Get Length  ${lease_products}
    ${status}   ${message}   Run Keyword And Ignore Error  Should Be True   ${lease_len}>0
    [return]   ${status}   ${lease_products}
    
Select Lease Option
    [Documentation]  Randomly select a lease option and update bep_parameters lease info
    [Arguments]   ${options}
    ${selected_option}    Evaluate  random.choice($options)  random
    ${ofm_name}   Set Variable   ${selected_option}[name]
    ${ofm_id}   Set Variable   ${selected_option}[id]
    Dictionary Should Contain Key  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OPTIONS][EQUIPMENT_LEASE_FEE]  ${ofm_name}
    Set To Dictionary   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SUBPRODUCTS]    EQUIPMENT_LEASE_FEE=${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OPTIONS][EQUIPMENT_LEASE_FEE][${ofm_name}]
    Run Keyword Unless    '${ofm_name}'=='${COUNTRY_VARIABLES}[${COUNTRY_CODE}][MONTHLY_LEASE_NAME]'    Set Suite Variable    ${MONTHLY_LEASE_OPTION}   False
    Run Keyword If    '${MONTHLY_LEASE_OPTION}' == 'False'    Set To Dictionary   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]    EQUIPMENT_LEASE_LIFETIME_FEE=${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS_EQUIPMENT_LIFETIME_LEASE]
    [return]     ${ofm_id}

Verify OTC From Cart
    [Documentation]  Verify OTC From Cart
    [Arguments]   ${otc_from_cart}
    Run Keyword If    ${MONTHLY_LEASE_OPTION} == True    Should Be Equal    ${otc_from_cart}    ${INSTALLATION_FEE}   ELSE    Calculate And Verify Once Total    ${otc_from_cart}

Calculate And Verify Once Total
    [Documentation]     Calculate And Verify Once Total
    [Arguments]    ${otc_from_cart}
    ${expected_total_once}   Evaluate  ${EQUIPMENT_LEASE_PRICE}+${INSTALLATION_FEE}
    Should Be Equal    ${expected_total_once}    ${otc_from_cart}

Get Item Price From Cart
    [Documentation]     Robot keyword to Get Item Price From Cart
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${item}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item}=   Set Variable    ${item}[0]
    ${high_level_prices}=   Set Variable    ${cart_item}[product][prices]
    : FOR    ${high_level_price}    IN    @{high_level_prices}
    \   ${name}    Get From Dictionary    ${high_level_price}    name
    \   ${amount}    Run Keyword If    '${name}' == 'Package Charge'    Get From Dictionary    ${high_level_price}    amount
    \   ${value}    Run Keyword If    '${name}' == 'Package Charge'    Get From Dictionary    ${amount}    value
    \   Run Keyword If    '${name}' == 'Package Charge'    Exit For Loop

    [return]   ${value}

Get OTC Price From Cart
    [Documentation]     Robot keyword to Get once time charge From cartTotalPrices
    [Arguments]    ${cart_id}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cartTotalPrices}    Get From Dictionary    ${cart_data}    cartTotalPrices
    Set Test Variable   ${value}   0
    : FOR    ${cartTotalPrice}    IN    @{cartTotalPrices}
    \   ${name}    Get From Dictionary    ${cartTotalPrice}    name
    \   Run Keyword If    '${name}' == 'Once Total'    Exit For Loop
    Run Keyword If    '${name}' == 'Once Total'    Set Test Variable   ${value}    ${cartTotalPrice}[amount][value]
    [return]   ${value}

Add Empty Cart
    [Documentation]     Robot keyword to add an empty cart
    [Arguments]    ${cart_name}    ${buyer_id}    ${seller_id}
    ${status}  ${result}    usePomApi    addEmptyCart    ${cart_name}    ${buyer_id}    ${seller_id}
    Should Be True    ${status}
    Log Response    ${result}
    ${response}=   Set Variable    ${result}[data][addOrUpdateCart]
    ${empty_cart_id}    Get From Dictionary    ${response}    id
    [return]   ${empty_cart_id}

Get The Cart Data
    [Documentation]     Robot keyword to Get The Cart Data
    [Arguments]    ${cart_id}
    ${status}  ${result}    usePomApi    getCart  ${cart_id}
    Should Be True    ${status}   getCart response from POM is ${result}
    Log Response    ${result}
    ${cart_data}=   Set Variable    ${result}[data][getCart]
    [return]   ${cart_data}

Add Up Item Prices From Cart
    [Documentation]     Robot keyword to add prices of all ietms in the cart
    [Arguments]    ${cart_id}
    ${product_price}    Get Item Price From Cart    ${cart_id}
    ${discount_price}    Get Discount Price From Cart    ${cart_id}
    ${lease_price}   Run Keyword If    '${COUNTRY_CODE}' == 'MX'    Get Equipment Lease Price From MX Cart    ${cart_id}    ELSE    Get Equipment Lease Price From Cart    ${cart_id}
    ############# Add fulfillment in OTC Charge ###############
    #${fulfillment_price}   Run Keyword If    '${COUNTRY_CODE}' == 'MX'    Get Fulfillment Product From MX Cart    ${cart_id}    ELSE    Set Variable    0
    #${fulfillment_price}   Convert To Integer  ${fulfillment_price}
    ${calculated_total_price}    bep_common.AddVariables   ${product_price}    ${discount_price}   ${lease_price}
    [return]   ${calculated_total_price}

Get Total Price And Currency From Cart
    [Documentation]     Robot keyword to Get total cart price
    [Arguments]    ${cart_total_prices}
    # get monthly total
    ${status}  ${total}   ${currency}    usePomApi    getTotalPriceAndCurrency  ${cart_total_prices}
    Should Be True    ${status}
    Log    ${total} ${currency}

    # get one-time total
    Set Test Variable   ${once_total}   0
    :FOR  ${item}   IN   @{cart_total_prices}
    \   Run Keyword If  '${item}[name]'=='Once Total'   Set Test Variable   ${once_total}   ${item}[amount][value]

    [return]   ${total}    ${currency}

Update Cart Status To Accepted
    [Documentation]     Robot keyword to change the cart status to accepted
    [Arguments]    ${cart_id}    ${status}
    ${status}  ${result}    usePomApi    updateCartStatus   ${cart_id}    ${status}
    ${status2}    ${message}   Should Be True    ${status}   updateCartStatus response from POM is ${result}
    [return]   ${result}

Add Empty Cart For Negative Test
    ${updated_cart_name}    Generate Random Cart Name
    Log   CART NAME IS ${updated_cart_name}
    ${empty_cart_id}    Add Empty Cart    ${updated_cart_name}    ${buyer_id}    ${seller_id}
    Log    empty_cart_id is ${empty_cart_id}
    #Set Suite Variable    ${empty_cart_id}
    [return]   ${empty_cart_id}

Verify Invalid Cart
    [Documentation]     Robot keyword to verify invalid cart
    [Arguments]    ${fake_cart_id}
    ${status}  ${result}    usePomApi    getCart  ${fake_cart_id}
    #Log To Console    ${result}
    ${status2}   ${message}   Should Be True    ${status}   getCart response from POM is ${result}
    Log Response    ${result}
    ${cart_data}=   Set Variable    ${result}[errors][0][0][message]
    ${status2}   ${message}   Should Contain    ${cart_data}    Invalid cart ID   getCart from POM should indicate invalid cart id instead of ${cart_data}
    #${cart_data_dict}    convertJsonToDictionary    ${cart_data}
    [return]   ${cart_data}

Add New Item To Existing Cart
    [Documentation]     Robot keyword to update Items In The Cart
    [Arguments]    ${cart_id}     ${high_level_cart_item_id}    ${new_product_type_id}
    ${status}  ${result}    usePomApi    addOrUpdateCartItem  ${cart_id}     ${high_level_cart_item_id}    ${new_product_type_id}
    Should Be True    ${status}   addOrUpdateCartItem response from POM is ${result}
    Log Response    ${result}
    ${response}=   Set Variable    ${result}[data][addOrUpdateCartItem]
    [return]   ${response}

### This is a temp Function for demo to replace seller ID ###########]

Replace Party Info In Cart Data
    [Arguments]    ${buyer_id}    ${buyer_name}   ${cart_data}
    Set Suite Variable    ${cart_data}
    ${parties}    Run Keyword And Continue On Failure    Get From dictionary    ${cart_data}  relatedParties
    Set Suite Variable    ${parties}
    :FOR    ${party}    IN    @{parties}
    \    ${value}    Get From Dictionary    ${party}    role
    \    ${party}    Run Keyword If    '${value}'=='buyer'    Set To Dictionary	${party}	name	${buyer_name}	id	${buyer_id}

    Log   Modified cart_data is ${cart_data}
    [return]   ${cart_data}




Delete The Cart
    [Documentation]     Robot keyword to delete Items From Cart
    [Arguments]    ${cart_id}
    ${status}  ${result}    usePomApi    deleteCart  ${cart_id}
    Log To Console    ${result}
    Log    ${result}
    Should Be True    ${status}
    ${response}=   Set Variable    ${result}[data][deleteCart][status]
    Should Contain    ${response}    deleted
    [return]   ${response}

Get Item From Cart
    [Documentation]     Robot keyword to get Item From Cart
    [Arguments]    ${cart_id}  ${cart_item_id}
    ${status}  ${result}    usePomApi    getCartItem  ${cart_id}  ${cart_item_id}
    Log To Console    ${result}
    Log    ${result}
    Should Be True    ${status}
    ${cart_item}=   Set Variable    ${result}[data][getCartItem]
    [return]   ${cart_item}


########### May not need #############

Get Product From POM
    [Documentation]     Robot keyword to get Product From POM
    [Arguments]    ${id}  ${cart_id}
    Log To Console    get product From POM
    ${status}  ${result}    usePomApi    getProduct  ${relatedParties}  ${location}
    Log To Console    ${result}
    Log    ${result}
    Should Be True    ${status}
    ${product}=   Set Variable    ${result}[data][getProduct]
    [return]   ${product}
