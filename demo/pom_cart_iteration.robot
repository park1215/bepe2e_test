*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Resource    ../common/wifi/wifi_resources.robot
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
${mex_org_id}          fe34ee49-6198-44b0-a96a-baa39bf59175
${buyer_id}
#${upsert_method}  ''
#${relatedParties}   [{id: "", role: "buyer"}, {id: "fe34ee49-6198-44b0-a96a-baa39bf59175", role: "seller"}]
#${location}         {coordinates: {latitude: 28.6, longitude: -106.1}}
${country_code}       ES
#${spain_product_id}       a99aaf0b-4589-419f-83b1-70038d02188b
#${cart_name}    BEPE2E's Cart
#${seller_id}    fe34ee49-6198-44b0-a96a-baa39bf59175
#${shopping_cart_item}    {id: "0c643357-8c0d-4697-934a-c2efe1da8278", action: "add", cartItems: [{id: "ded0a22d-675d-4e3e-96cc-cdea1ddbf8ff", action: "add", product: {id: "297413e0-d2de-4912-9786-90f561bdd7cb", name: "Equipment Lease Fee - Lifetime"}}]}
#${cart_item_id}                d7ccf99f-4f27-44e0-84c9-cc33cc5cb89d



*** Test Cases ***
Iterate Through Get Offers
    [Documentation]  Gets the offers first and  randomly selects any offer
    [Tags]  BEPR-527    pom
    Get Offers & Add In Cart One By One    ${buyer_id}    ${mex_org_id}    ${country_code}



*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log   Configure suite variables here@
    # if global variables not present for IDs, generate them
    #Set Suite Variable    ${selected_service_plan}    Viasat 12 Mbps
    #Set ID If It Does Not Exist   \${ORDER_ID}
    #Set ID If It Does Not Exist   \${CUSTOMER_RELATIONSHIP_ID}
    #Set ID If It Does Not Exist   \${PRODUCT_ITEM_ID}
    #Set ID If It Does Not Exist   \${PRODUCT_ID}
    #Set ID If It Does Not Exist   \${ORDER_LINE_ID}
    #Set ID If It Does Not Exist   \${PAYMENT_TRANSACTION_ID}
    #ResVNO Smoke
    #${response}   ${vps}   useVpsApi   initialize
    #Should Be True  ${response}
    #Set Suite Variable  ${vps}
    #Log To Console  service plan=${service_plan}
    #Create PSM SQS Queue
    #Create SISM SQS Queue
    #Create OM SQS Queue
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}    WARN
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}    WARN

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    #Delele PSM Queue
    #Delele SISM Queue
    #Delele OM Queue




