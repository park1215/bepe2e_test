import pom_api


def run():
    pomApi = pom_api.POM_API_LIB()


    # Test getOffers
    relatedParties = '[{id: "001r000000CEhrm", role: "buyer"}, {id: "fe34ee49-6198-44b0-a96a-baa39bf59175", role: "seller"}]'
    location = '{coordinates: {latitude: 30.758638, longitude: -106.464699}}'
    status, response = pomApi.getOffers(relatedParties, location)
    print(status)
    print(response)

    
    '''
    # Test getCart
    id = "42ed3fa4-6ac0-4783-859a-e8374588ce51"
    status, response = pomApi.getCart(id)
    print(status)
    print(response)

    
    # Test addEmptyCart
    id = "8082ea19-40ac-4f3c-923e-c50a572590b7"
    name = "Cart 1 - Modified Name"
    status, response = pomApi.addEmptyCart(id,name)
    print(status)
    print(response)

    


    # Test addOrUpdateCart
    shoppingCart = '{name: "Cart 2", description: "Create a cart with the MX50 Product", relatedParties: [{id: "09e5529c-cf71-4bf2-bcf5-b4e5f0f7b731", role: "buyer"}, {id: "ec456fb0-f193-4f5f-8e1b-f37d6331fdbb", role: "seller"}], cartItems: {action: "add", quantity: {value: 1, unit: "each"}, product: {id: "4d0b6b7b-9eb2-44ad-8ac6-2adf1ba00a9b", name: "Viasat 50 Mbps"}}}'
    status, response = pomApi.addOrUpdateCart(shoppingCart)
    print(status)
    print(response)
    

    
    # Test getCartItem
    cartId = "42ed3fa4-6ac0-4783-859a-e8374588ce51"
    cartItemId = "0c643357-8c0d-4697-934a-c2efe1da8278"
    status, response = pomApi.getCartItem(cartId, cartItemId)
    print(status)
    print(response)
    

    # Test getProduct
    id = "42ed3fa4-6ac0-4783-859a-e8374588ce51"
    cartId = "0c643357-8c0d-4697-934a-c2efe1da8278"
    status, response = pomApi.getProduct(id, cartId)
    print(status)
    print(response)
    


    # Test findCart
    ################ This is not tested since implementation is not done ##########################
    filter = ""
    limit = ""
    nextToken = ""
    status, response = pomApi.findCart(filter, limit, nextToken)
    print(status)
    print(response)
    
    
    # Test deleteCartItem
    cartId = "42ed3fa4-6ac0-4783-859a-e8374588ce51"
    cartItemId = '0c643357-8c0d-4697-934a-c2efe1da8278'
    status, response = pomApi.deleteCartItem(cartId, cartItemId)
    print(status)
    print(response)
    
    
    
    # Test addOrUpdateCartItem
    cartId = "42ed3fa4-6ac0-4783-859a-e8374588ce51"
    # to add item use following
    #shoppingCartItem = '{action: "add", product: {id: "ab4d360a-79fd-4908-a7b6-24eeac7402a4", name: "EasyCare"}}'
    # to update existing item use following
    shoppingCartItem = '{id: "0c643357-8c0d-4697-934a-c2efe1da8278", action: "add", quantity: {value: 2, unit: "each"}}'
    status, response = pomApi.addOrUpdateCartItem(cartId, shoppingCartItem)
    print(status)
    print(response)
    
    
    # Test deleteCart
    cartId = "8082ea19-40ac-4f3c-923e-c50a572590b7"
    status, response = pomApi.deleteCart(cartId)
    print(status)
    print(response)
    '''





run()
