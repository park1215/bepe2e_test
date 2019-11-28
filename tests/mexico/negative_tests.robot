*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     copy
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
Add Item To Existing Empty Cart
    [Documentation]  First creates empty cart and then adds item to this cart
    [Tags]   OFM    captureResponseTime
    ${updated_cart_name}    Generate Random Cart Name
    ${new_cart_id}    Add Empty Cart    ${updated_cart_name}    ${buyer_id}    ${SELLER_ID}
    Set Suite Variable    ${COORDINATES}    ${service_address}[coordinates]
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}   ${COORDINATES}
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    
    ${result}    Add Items In Existing Cart    ${new_cart_id}     ${buyer_id}    ${SELLER_ID}    ${selected_offer_id}
    ${cart_data}    Get The Cart Data    ${new_cart_id}
    Log    Cart Data is ${cart_data}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    ${cart_item_list_count}=    Get length    ${cart_items}
    Should Be Equal As Strings      ${cart_item_list_count}  1
    
Place Order Without Postal Code
    [Documentation]  Proceed through upsert order but do not place postal code in upsert order. Verify order rejected. Run first time WITH postal code to verify test case correctness
    [Tags]   postal
    
    ${response}   ${vps}   useVpsApi   initialize   ${VPS_INIT_INPUT}
    Should Be True  ${response}
    Set Suite Variable   ${vps}
    
    # Initialize payment methods and get offers
    ${expected_vps_payment_method}    ${expected_vps_recurring_payment_method}    Set And Get Payment Methods
    ${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}   ${service_address}[coordinates]
    #${offers}    Get And Validate Offers From POM    ${buyer_id}    ${SELLER_ID}    ${country_code}  
    ${selected_offer_id}   ${selected_name}     Select Random Offer From GetOffers    ${offers}
    Log   RANDOM selected plan is ${selected_name} product type id is: ${selected_offer_id}
    ${advance_payment}    ${advance_payment_description}    Get Advance Payment Info From Offers    ${selected_name}

    # Complete Cart
    ${cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${selected_offer_id}    ${selected_name}
    ${cart_data}    Get The Cart Data    ${cart_id}
    ${cart_items}    Get From Dictionary    ${cart_data}    cartItems
    Log    Cart Data is ${cart_data}
    ${cart_item_id}    Get Cart Item Id from Cart Item List    ${cart_items}    ${selected_offer_id}   
    Run Keyword And Continue On Failure    Verify Price Roll Ups In Cart    ${cart_id}

    # IRA
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${FULL_NAME}    ${GROUPS}
    ${returned_email}  ${returned_address}  ${returned_phone_number}  ${tin_external_id}  ${reln_id}  Add And Get Customer Info To IRA    ${party_id}   ${EMAIL_ADDRESS}    ${ADDRESS_LINE}    ${CITY}   ${STATE}   ${POSTAL_CODE}   ${PHONE_NUMBER}
    Log    ${returned_email}, ${returned_address}, ${returned_phone_number}, ${tin_external_id}, ${reln_id}
    ${roles}  ${reln_version2}  ${reln_id}  ${reln_groups}    Get Relationship From IRA    ${reln_id}
    ${customer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   CustomerRole
    ${payer_role_id}   Get PartyRoleId From Relationship for Typename   ${reln_id}   PayerRole
    ${returned_party_id}  ${returned_groups}    Get Party From External Id    ${tin_external_id}    ${EXTERNAL_ID_TYPE_NAME}
    Should Not Be Empty    ${returned_party_id}
    Set Suite Variable  ${customer_ref}   ${reln_id}

    Update And Verify Cart Status To Accepted    ${cart_id}    ACCEPTED

    # VPS Init
    ${vps_request_payment_transaction_id}   ${payment_transaction_id}   Initialize Transaction With VPS    ${reln_id}    ${advance_payment}
    Set Suite Variable   ${vps_request_payment_transaction_id}
    ${one_time_payment_id}    Add One Time Payment Method To VPS   ${reln_id}   ${expected_vps_payment_method}
    ${recurring_payment_id}    Add Recurring Payment Method To VPS    ${reln_id}   ${expected_vps_recurring_payment_method}
    Set Suite Variable   ${recurring_payment_id}

    #Add Billing Account To SPB and modify payment txn in vps
    ${billing_account_id}    Add Billing Account    ${customer_ref}    ${payer_role_id}    ${customer_role_id}    ${expected_vps_recurring_payment_method}
    Set Suite Variable  ${billing_account_id}
    Modify Payment Transaction Id In VPS    ${billing_account_id}    ${vps_request_payment_transaction_id}

    # Attempt to place order without postal code
    ${location}   copy.deepcopy  ${service_address}
    Set To Dictionary   ${location}   addressLines=${service_address}[addressLine]
    Remove From Dictionary  ${location}   addressLine
    ${payment_transaction_id}    Generate A GUID
    ${order_id}    Generate A GUID

    ${status}   ${message}   Run Keyword and Ignore Error  Upsert OM Order   ${order_id}    ${cart_id}    ${customer_ref}   ${location}   ${payment_transaction_id}   ${cart_item_id}    ${billing_account_id}
    # first verify that this passes, then remove postal code and verify it fails - then push that version of the file to git
    Should Be Equal As Strings  ${status}   PASS

Add & Delete Multiple Items In OFM
    [Documentation]  First creates empty cart and then adds item to this cart
    [Tags]   OFM
    ${offer_id}    ${offer_name}    Select Random Offer From GetOffers    ${offers}
    Set Suite Variable    ${offer_name}
    Set Suite Variable    ${offer_id}
    Run Keyword And Continue On Failure    Add Cart With Single Item & Delete Item
    Run Keyword And Continue On Failure    Test Add And Remove Item Functionality In OFM

OFM Negative Tests
    [Documentation]  This is the negative test for cart
    [Tags]  OFM    negative
    Run Keyword And Continue On Failure    Get Cart For Invalid Cart Id
    ${empty_cart_id}    Run Keyword And Continue On Failure    Transition Empty Cart To Accepted State
    Run Keyword And Continue On Failure    Add Items To Empty Cart When In Accepted State     ${empty_cart_id}     ${buyer_id}    ${SELLER_ID}    ${offer_id}
    Run Keyword And Continue On Failure    Verify Get Offer Fails For Not Supported Country     ${buyer_id}    ${SELLER_ID}    CN

OM Negative Tests
    [Documentation]   SW use main product instance id returned from upsert order to get all product instance ids for order Step 8
    [Tags]   OM    negative
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
    ${guid}    Generate A GUID
    Set Test Variable    ${reln_id}     ${guid}
    ${empty_cart_id}    Add Empty Cart For Negative Test
    &{location}   createDictionary  addressLines=${ADDRESS_LINE}  isoCountryCode=${isoCountryCode}  city=${CITY}  regionOrState=${STATE}  latitude=${LATITUDE}  longitude=${LONGITUDE}  zipOrPostCode=${POSTAL_CODE}
    Set Suite Variable    ${om_location}    ${location}
    Run Keyword And Continue On Failure    Update And Verify Cart Status To Accepted    ${empty_cart_id}    ACCEPTED
    Run Keyword And Continue On Failure    Verify Upsert With Fake Cart Id    ${fake_cart_test_order_id}    ${fake_cart_id}    ${reln_id}   ${om_location}   ${fake_cart_test_transaction_id}   2019-06-21
    Run Keyword And Continue On Failure    Verify Upsert With Empty Cart    ${empty_cart_test_order_id}    ${empty_cart_id}    ${reln_id}   ${om_location}   ${empty_cart_test_transaction_id}   2019-06-21
    ${in_progress_cart_id}    Add Cart With Item And Verify Cart    ${buyer_id}    ${SELLER_ID}    ${offer_id}    ${offer_name}
    Verify Upsert With In-Progress Cart    ${non_accepted_cart_test_order_id}    ${in_progress_cart_id}    ${reln_id}   ${om_location}   ${non_accpeted_cart_test_transaction_id}   2019-06-21

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    Set Country Specific Variables

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@

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
