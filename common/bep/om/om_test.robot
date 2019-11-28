
*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     om_api.py
Variables   om_parameters.py
Variables   bep_parameters.py
Resource    om_resource.robot
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
# characteristics

# product items

# configured product type
${PRODUCT_NAME}   Viasat Business Metered 50 GB
${PRODUCT_KIND}   Package
${PRODUCT_DESCRIPTION}   blank
#${PRODUCT_ID}   daf30293-b101-4580-9412-74d6dd55d2a1
# required product type id for PSM
${PRODUCT_ID}   4d0b6b7b-9eb2-44ad-8ac6-2adf1ba00a9b

# order line

# location
${COUNTRY_NAME}   Mexico
${COUNTRY_CODE}   MEX
${ADDRESS_LINE}   Av. de las Americas 108
${CITY}           San Felipe V Etapa
${STATE}          CHI
${POSTAL_CODE}    31123
 
*** Test Cases ***
Get OM Version Invoke
    ${result}   Get OM Version
    Log To Console   ${result}

Upsert Order To OM
    [Documentation]   arguments to Upsert OM Order are ${orderId}  ${orderLines}  ${customerRelationshipId}  ${location}  ${paymentTransactionId}  ${expectedCompletionDate}   ${state}
    ...   with the last 4 being optional. The orderLines input array must have at least one entry.
    
    ${characteristics}    Get From Dictionary   ${CHARACTERISTICS}   ${PRODUCT_NAME}

    # leaving out lat/long for now
    ${latitude}   Set Variable   39.5
    ${longitude}   Set Variable   -104.6
    &{isoCountryCode}   Create Dictionary   name=${COUNTRY_NAME}   alphabeticThreeCharacterCode=${COUNTRY_CODE}  
    @{ADDRESS_LINES}   Create List   ${ADDRESS_LINE}
    &{location}   createDictionary  addressLines=${ADDRESS_LINES}  isoCountryCode=${isoCountryCode}  city=${CITY}  regionOrState=${STATE}  latitude=${latitude}  longitude=${longitude}  zipOrPostCode=${POSTAL_CODE}
    #&{location}   createDictionary   addressLines=${ADDRESS_LINES}   isoCountryCode=${isoCountryCode}  city=${CITY}  regionOrState=${STATE}   


    # the following removes empty values and also prices
    ${result}   removeEmptyLists   ${PRODUCTS_50_PRICES}[0]
    Set List Value   ${PRODUCTS_50_PRICES}  0   ${result}
    ${products}   Set Variable  ${PRODUCTS_50_PRICES}
    
    &{configuredProductType}   Create Dictionary   id=${PRODUCT_ID}   name=${PRODUCT_NAME}   kind=${PRODUCT_KIND}   characteristics=${characteristics}   products=${products}  description=${PRODUCT_DESCRIPTION} 
    &{orderLineItem}    Create Dictionary   orderLineId=${ORDER_LINE_ID}   configuredProductType=${configuredProductType}   serviceLocation=${location}
    @{orderLines}   Create List   ${orderLineItem}
    Set Suite Variable  ${orderLines}
    
    ${customerRelationshipId}  Set Variable   ${CUSTOMER_RELATIONSHIP_ID}

    #${result}   Upsert OM Order   ${ORDER_ID}   ${orderLines}   ${customerRelationshipId}   ${location}   ${None}   ${None}    
    ${result}   Upsert OM Order   ${ORDER_ID}   ${orderLines}   ${customerRelationshipId}   ${location}   ${PAYMENT_TRANSACTION_ID}   2019-06-21    
    
    Log To Console   ${result}

Get Order From OM
    [Documentation]   Gets order just placed and compares to order placed. Assumes there is one subproduct.
    [Tags]     enable
    @{returns}   Create List   orderId

    Append To List  ${returns}  orderLines{orderLineId,serviceLocation{latitude,longitude,addressLines,city,regionOrState,zipOrPostCode,isoCountryCode{name,alphabeticThreeCharacterCode}},productInstanceId,configuredProductType{name,description,kind,characteristics{name,value,valueType},products{name,description,kind,characteristics{name,value,valueType}}}}

    ${status}   ${result}    Get OM Order   ${ORDER_ID}    ${returns}
    Should Be True   ${status}

    ${getOrder}  Set Variable  ${result}[data][getOrder]
    Should Be Equal  ${getOrder}[orderId]    ${ORDER_ID}
    Should Be Equal  ${getOrder}[orderLines][0][orderLineId]  ${orderLines}[0][orderLineId]
    ${latitude}  Convert To Number  ${orderLines}[0][serviceLocation][latitude]
    ${longitude}   Convert To Number  ${orderLines}[0][serviceLocation][longitude]
    Set To Dictionary   ${orderLines}[0][serviceLocation]  latitude=${latitude}
    Set To Dictionary   ${orderLines}[0][serviceLocation]  longitude=${longitude}
    Should Be Equal  ${getOrder}[orderLines][0][serviceLocation]  ${orderLines}[0][serviceLocation]
    Should Be Equal  ${getOrder}[orderLines][0][configuredProductType][characteristics]  ${orderLines}[0][configuredProductType][characteristics]
    Should Be Equal  ${getOrder}[orderLines][0][configuredProductType][name]  ${orderLines}[0][configuredProductType][name]
    Should Be Equal  ${getOrder}[orderLines][0][configuredProductType][description]  ${orderLines}[0][configuredProductType][description]
    Should Be Equal  ${getOrder}[orderLines][0][configuredProductType][kind]  ${orderLines}[0][configuredProductType][kind]
    #&{productsWithoutId}   Set Variable  ${orderLines}[0][configuredProductType][products][0]
    #Remove From Dictionary  ${productsWithoutId}  id
    Should Be Equal  ${getOrder}[orderLines][0][configuredProductType][products][0][name]  ${orderLines}[0][configuredProductType][products][0][name]

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    # if global variables not present for IDs, generate them
    Set ID If It Does Not Exist   \${ORDER_ID}
    Set ID If It Does Not Exist   \${CUSTOMER_RELATIONSHIP_ID}    
    Set ID If It Does Not Exist   \${PRODUCT_ITEM_ID}  
    Set ID If It Does Not Exist   \${PRODUCT_ID}
    Set ID If It Does Not Exist   \${ORDER_LINE_ID}
    Set ID If It Does Not Exist   \${PAYMENT_TRANSACTION_ID} 
    #ResVNO Smoke 

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
 
Set ID If It Does Not Exist
    [Arguments]   ${name}  
    ${status}  ${message} =  Run Keyword And Ignore Error  Variable Should Exist  ${name}
    ${guid}    common_library.generateGuid
    Run Keyword If  "${status}" == "FAIL"  Set Suite Variable  ${name}  ${guid} 
    
