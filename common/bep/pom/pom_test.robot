*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Resource    ../common/bep/pom/pomresource.robot

*** Comments ***
Usage : robot --console VERBOSE --exitonfailure pom_test.robot

*** Variables ***
${cartId}           54bfb54f-8be7-4c1c-affc-53b04cb5f769
${cartItemId}       0c643357-8c0d-4697-934a-c2efe1da8278
${relatedParties}   [{id: "001r000000CEhrm", role: "buyer"}, {id: "fe34ee49-6198-44b0-a96a-baa39bf59175", role: "seller"}]
#${location}         {coordinates: {latitude: 30.758638, longitude: -106.464699}}
${location}         {coordinates: {latitude: 31.300305, longitude: -110.938365}}
#${id}    42ed3fa4-6ac0-4783-859a-e8374588ce51
${cartId_getProduct}    0c643357-8c0d-4697-934a-c2efe1da8278

${shopping_cart_to_add_items}     {name: "Cart 2", description: "Create a cart with the MX50 Product", relatedParties: [{id: "09e5529c-cf71-4bf2-bcf5-b4e5f0f7b731", role: "buyer"}, {id: "ec456fb0-f193-4f5f-8e1b-f37d6331fdbb", role: "seller"}], cartItems: {action: "add", quantity: {value: 1, unit: "each"}, product: {id: "4d0b6b7b-9eb2-44ad-8ac6-2adf1ba00a9b", name: "Viasat 50 Mbps"}}}
${shopping_cart_item}    {id: "0c643357-8c0d-4697-934a-c2efe1da8278", action: "add", quantity: {value: 2, unit: "each"}}
${cart_id_to_delete}    8082ea19-40ac-4f3c-923e-c50a572590b7

${cart_name}    Prachi's Cart
${buyer_id}    001r000000CEhrm
${seller_id}    fe34ee49-6198-44b0-a96a-baa39bf59175
${buyer_name}    BEP Nexus Sprint#2 Customer

*** Test Cases ***
Get Offer And Put It In The Cart
    [Documentation]    Gets the offers first and  randomly selects any offer
    ${selected_offer_id}    Select Random Offer From GetOffers    ${relatedParties}    ${location}
    #Log   RANDOM selected order is ${selected_offer_id}   WARN
    #Set Suite Variable    ${cart_item_id}    ${selected_offer_id}
    Set Suite Variable    ${cart_item_id}    daf30293-b101-4580-9412-74d6dd55d2a1
    Log   selected product is Viasat Business Metered 50 GB with id ${cart_item_id}   WARN

Add Cart With Item From Get Offers
    [Documentation]    Create an emoty cart and add randomly selected/given offer in the cart
    ${value} =  Generate Random String  5  [NUMBERS]
    ${updated_cart_name} =	Catenate	SEPARATOR=	${cart_name}	${value}
    log   CART NAME IS ${updated_cart_name}    WARN
    ${cart_id}    Add Cart With Item    ${updated_cart_name}    ${buyer_id}    ${seller_id}    ${cart_item_id}
    Set Suite Variable    ${cart_id}
    Log    NEW CART ID is ${cart_id}    WARN

Fetch Cart Data From POM
    [Documentation]    get the cart data from pom
    [Tags]    pom    test
    ${cart_data}    Get The Cart Data    ${cart_id}
    #Log   get cart Response is: ${cart_data}    WARN


Fetch Offers From POM
    [Documentation]    Get Offers from POM
    [Tags]    pom     myTag
    ${offers}    Get Offers From POM    ${relatedParties}    ${location}
    Log To Console    ${offers}



Modify Cart
    ${cart_data}    Get The Cart Data    ${cartId}
    Replace Party Info In Cart Data    ${buyer_id}    ${buyer_name}    ${cart_data}



Update Items In The Given Cart
    [Documentation]    Update Items In The Cart
    [Tags]    pom
    ${cart_data}    Update Items In The Cart    ${cartId}    ${shopping_cart_item}
    Log To Console    ${cart_data}

Add Items In The Given Cart
    [Documentation]    Add Items In The Cart
    [Tags]    pom
    ${cart_data}    Add Items In The Cart    ${shopping_cart_to_add_items}
    Log To Console    ${cart_data}



Get Item from The Cart In POM
    [Documentation]    Delete Item from The Cart In Pom
    [Tags]    pom
    ${cart_item}    Get Item From Cart    ${cartId}    ${cartItemId}
    Log To Console    ${cart_item}

Delete Item from The Cart In POM
    [Documentation]    Delete Item from The Cart In Pom
    [Tags]    pom
    Delete Items From Cart    ${cartId}    ${cartItemId}
    Log To Console    success

Delete The Cart In POM
    [Documentation]    Delete The Cart In Pom
    [Tags]    pom
    ${response}    Delete The Cart    ${cart_id_to_delete}
    Log To Console    ${response}


Fetch Product from The Cart In POM
    [Documentation]    Delete Item from The Cart In Pom
    [Tags]    pom
    ${product}    Get Product From POM    ${id}    ${cartId_getProduct}
    Log To Console    ${product}
