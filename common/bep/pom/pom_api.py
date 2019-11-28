import requests
import sys, os
import pprint
import json, re
import bep_common
import pom_parameters
from pom_parameters import *
from robot.api import logger

class POM_API_LIB:
    def getOffers(self, buyerId, sellerId, countryCode, coordinates, type="FIXED_SATELLITE_INTERNET"):
        """
        Method Name :  getOffers
        Parameters  :  id, name, party role
        Description :  Posts get offers and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        #url = pom_parameters.POM_OFFER_DEV_URL
        url =  pom_parameters.POM_CART_DEV_URL
        if coordinates == 'None':
            payload = {"query":"{\n  getOffers(offerFilters: {catalogSegments: [\"Residential Internet\"], relatedParties: [{id: \"" + buyerId + "\", role: \"buyer\"}, {id: \"" + sellerId + "\", role: \"seller\"}], characteristics: [{name: \"PSM_PRODUCT_KIND\", value: \"" + type + "\"}], location: {address: {countryCode:\"" +countryCode + "\"}}}) {\n id\n name\n description\n kind\n uiBehaviors {\n behavior\n value\n }\n characteristics {\n valueType\n name\n value\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n percentage\n unitOfMeasure\n }\n products {\n ...productDetails\n products {\n ...productDetails\n }\n }\n }\n}\n\nfragment productDetails on ProductType {\n id\n name\n description\n kind\n uiBehaviors {\n behavior\n value\n }\n characteristics {\n valueType\n name\n value\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n percentage\n unitOfMeasure\n }\n}\n\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n majorUnitSymbol\n}\n"}
        else:
            str_coordinates = str(coordinates)
            str_coordinates = str_coordinates.replace("'", "")
            payload = {"query":"{\n  getOffers(offerFilters: {catalogSegments: [\"Residential Internet\"], relatedParties: [{id: \"" + buyerId + "\", role: \"buyer\"}, {id: \"" + sellerId + "\", role: \"seller\"}], characteristics: [{name: \"PSM_PRODUCT_KIND\", value: \"" + type + "\"}], location: {coordinates: " + str_coordinates + " address:{countryCode:\"" +countryCode + "\"}}}) {\n id\n name\n description\n kind\n uiBehaviors {\n behavior\n value\n }\n characteristics {\n valueType\n name\n value\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n percentage\n unitOfMeasure\n }\n products {\n ...productDetails\n products {\n ...productDetails\n }\n }\n }\n}\n\nfragment productDetails on ProductType {\n id\n name\n description\n kind\n uiBehaviors {\n behavior\n value\n }\n characteristics {\n valueType\n name\n value\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n percentage\n unitOfMeasure\n }\n}\n\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n majorUnitSymbol\n}\n"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            try:
                logger.info ("url is:")
                logger.info(url)
                logger.info ("header is:")
                logger.info (header)
                logger.info ("payload is:")
                logger.info(payload)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))

                print(r.status_code)
                if r.status_code == 200:
                    return True, r.json()
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling getOffers offM Endpoint, Error --> " + str(e)

    def getOffersBuyMore(self, planName, productTypeId, countryCode):
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url =  pom_parameters.POM_CART_DEV_URL
        #payload = {"query":"{\n  getOffers(offerFilters: {catalogSegments: [\"Residential Internet\"], relatedParties: [{id: \"" + buyerId + "\", role: \"buyer\"}, {id: \"" + sellerId + "\", role: \"seller\"}], characteristics: [{name: \"PSM_PRODUCT_KIND\", value: \"FIXED_SATELLITE_INTERNET\"}], location: {address: {countryCode:\"" +countryCode + "\"}}}) {\n id\n name\n description\n kind\n uiBehaviors {\n behavior\n value\n }\n characteristics {\n valueType\n name\n value\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n percentage\n unitOfMeasure\n }\n products {\n ...productDetails\n products {\n ...productDetails\n }\n }\n }\n}\n\nfragment productDetails on ProductType {\n id\n name\n description\n kind\n uiBehaviors {\n behavior\n value\n }\n characteristics {\n valueType\n name\n value\n }\n prices {\n name\n description\n kind\n recurrence\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n percentage\n unitOfMeasure\n }\n}\n\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n majorUnitSymbol\n}\n"}

        payload = {"query":"query MultipleOfferQueries {\n buymore: getOffers(\n offerFilters: {\n catalogSegments: [\"Residential Internet\"]\n location: { address: { countryCode: \"" + countryCode + "\"} }\n characteristics: [{ name: \"PSM_PRODUCT_KIND\", value: \"BUY_MORE\" }]\n customerInventory: [\n {\n id: \"Inventory GUID\"\n productTypeId: \"" + productTypeId + "\" \n name: \"" + planName + "\" \n }\n ]\n }\n ) {\n id\n kind\n name\n description\n characteristics {\n name\n value\n }}}\n \n ","operationName":"MultipleOfferQueries"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            try:
                logger.info ("url is:")
                logger.info(url)
                logger.info ("header is:")
                logger.info (header)
                logger.info ("payload is:")
                logger.info(payload)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))

                print(r.status_code)
                if r.status_code == 200:
                    response = r.json()
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling getOffersBuyMore offM Endpoint, Error --> " + str(e)

    def getCart(self, cartId):
        """
        Method Name :  getCart
        Parameters  :  id
        Description :  Posts get cart and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL

        #payload = {"query":"\nquery  {\n getCart(id: \"" + cartId + "\")\n{\n...CartData\n}\n\n}\n\n\nfragment PriceInfo on Price {\namount {\n value currency {\n...fullCurrency\n}\nvalue\n}\ndescription\n name\n percentage\n kind\n recurrence\n unitOfMeasure\n}\n\n fragment CartEvent on Event {\n id\nsummary\n eventDetail\n kind\n timestamp\nrequestedBy {\n ...PartySummaryData\n}\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n name\n value\n valueType\n}\nfragment ProductDetail on ProductType {\n id\n name\ndescription\n kind\n characteristics {\n...CharacteristicDetail\n}\n prices {\n...PriceInfo\n}\n\n}\nfragment CartItemData on CartItem {\n id\n action\n quantity {\n unit\n value\n}\n status\n itemPrices {\n...PriceInfo\n}\n product {\n...ProductDetail\n products {\n...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n }\n }\n }\n }\n\n}\n\nfragment PartySummaryData on PartySummary {\n id\n name\n role\n}\n\nfragment CartData on ShoppingCart {\n id\n name\n status\n cartEvents {\n ...CartEvent\n }\n cartItems {\n ...CartItemData\n }\n cartTotalPrices {\n ...PriceInfo\n }\n validFor {\n startDateTime\n endDateTime\n }\n relatedParties {\n ...PartySummaryData\n }\n}\n\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n majorUnitSymbol\n}\n"}
        payload = {"query":"query getMyCart {\n getCart(id: \"" + cartId + "\")\n {\n ...CartData\n }\n}\nfragment PriceInfo on Price {\n amount {\n value currency {\n ...fullCurrency\n }\n value\n }\n description \n characteristics{name value valueType}\n amount{value currency{name alphabeticCode numericCode minorUnits majorUnitSymbol}}\n kind\n name\n percentage\n unitOfMeasure\n recurrence\n}\nfragment CartEvent on Event {\n id\n summary\n eventDetail\n kind\n timestamp\n requestedBy {\n ...PartySummaryData\n }\n}\nfragment CharacteristicDetail on Characteristic {\n name\n value\n valueType\n}\nfragment ProductDetail on ProductType {\n id\n name\n description\n kind\n characteristics {\n ...CharacteristicDetail\n }\n prices {\n ...PriceInfo\n }\n}\nfragment CartItemData on CartItem { productCandidateGraph {relationships {destinationId id relationshipType sourceId  } productCandidates {id name kind description productTypeId characteristics {name value valueType} prices {amount {value } kind characteristics {name value valueType} name description recurrence unitOfMeasure}}} \n id\n action\n quantity {\n unit\n value\n }\n status\n itemPrices {\n ...PriceInfo\n }\n product {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n }\n }\n }\n }\n}\nfragment PartySummaryData on PartySummary {\n id\n name\n role\n}\nfragment CartData on ShoppingCart {\n id\n name\n status\n cartEvents {\n ...CartEvent\n }\n cartItems {\n ...CartItemData\n }\n cartTotalPrices {\n ...PriceInfo\n }\n validFor {\n startDateTime\n endDateTime\n }\n relatedParties {\n ...PartySummaryData\n }\n}\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n majorUnitSymbol\n}"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            try:
                logger.info("header is:")
                logger.info(header)
                logger.info(json.dumps(payload))
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                logger.info("response is:")
                logger.info(r)
                print(r.status_code)
                if r.status_code == 200:
                    response = r.json()
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                #logger.console("############# line 64 ###################")
                return False, funcName + ":Error calling getCart offM Endpoint, Error --> " + str(e)


    def getTotalPriceAndCurrency(self, cartTotalPrices):
        """
        Method Name :  cartTotalPrices
        Parameters  :  id
        Description :  gets the total price of the cart
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        try:
            for cartTotalPrice in cartTotalPrices:
                if cartTotalPrice.get('name') == 'Monthly Total':
                    amount = cartTotalPrice.get('amount')
                    total = amount.get('value')
                    currencyField = amount.get('currency')
                    currency = currencyField.get('name')
                    logger.info("currency is:")
                    logger.info(currency)
                    logger.info("total is:")
                    logger.info(total)

        except Exception as e:
            return False, funcName + ":Error calculating total price of items in the cart, Error --> ", str(e)

        return True, total, currency


    def updateCartStatus(self, cartId, status):
        """
        Method Name :  updateCartStatus
        Parameters  :  id
        Description :  changes the cart status to given status accepted
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL
        payload = {"query":"mutation{addOrUpdateCart(shoppingCart:{id:\"" + cartId + "\", status:\"ACCEPTED\"}){id name status}}\n"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            #ofmupdateCartStatus = header['X-BEP-Execution-Id']
            logger.info("header = " + str(header))

            try:
                logger.info("payload is:")
                logger.info(payload)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = r.json()
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling getCart offM Endpoint, Error --> " + str(e)

    def deleteCart(self, cartId):
        """
        Method Name :  deleteCart
        Parameters  :  cartId
        Description :  Posts deleteCart with cartId and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL

        payload = {"query": "mutation {\n    deleteCart (cartId: \"" + cartId + "\")\n    {\n        status\n    }\n}"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            try:

                logger.info ("header is:")
                logger.info (header)
                print ("payload is:")
                print(json.dumps(payload))
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = json.loads(r.text)
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling deleteCart offM Endpoint, Error --> " + str(e)

    def addOrUpdateCart(self, cartName, buyerId, sellerId, cartItemId, fulfillmentItemId):
        """
        Method Name :  addOrUpdateCart
        Parameters  :  name, description, relatedParties, cartItems
        Description :  Posts addOrUpdateCart and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL
        #payload = {
        #    "query": "mutation  {\n    addOrUpdateCart(\n        shoppingCart:" + shoppingCart + " ) {\n        ...CartData\n    }\n}\n\nfragment PriceInfo on CartPrice {\n    amount {\n        currency {\n            ...fullCurrency\n        }\n        value\n    }\ndescription\n    id\n    name\n    percentage\n    priceType\n    recurrence\n    unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n  name\n  alphabeticCode\n  numericCode\n  minorUnits\n  majorUnitSymbol\n}\n\nfragment CartEvent on Event {\n    id\n    summary\n    eventDetail\n    kind\n    timestamp\n    requestedBy {\n        ...PartySummaryData\n    }\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n    name\n    value\n    valueType\n}\nfragment ProductDetail on ProductType {\n    id\n    name\n    description\n    kind\n    characteristics {\n        ...CharacteristicDetail\n    }\n    prices {\n        ...PriceInfo\n    }\n\n}\nfragment CartItemData on CartItem {\n    id\n    action\n    quantity {\n        unit\n        value\n    }\n    status\n    itemPrices {\n        ...PriceInfo\n    }\n    product {\n        ...ProductDetail\n        products {\n            ...ProductDetail\n            products {\n                ...ProductDetail\n                products {\n                    ...ProductDetail\n                }\n            }\n        }\n    }\n\n}\n\nfragment PartySummaryData on PartySummary {\n    id\n    name\n    role\n}\n\nfragment CartData on ShoppingCart {\n    id\n    name\n    description\n    status\n    cartEvents {\n        ...CartEvent\n    }\n    cartItems {\n        ...CartItemData\n    }\n    cartTotalPrices {\n        ...PriceInfo\n    }\n    validFor {\n        startDateTime\n        endDateTime\n    }\n    relatedParties {\n        ...PartySummaryData\n    }\n}"}

        if fulfillmentItemId == 'None':
            payload = {
                "query": "mutation {addOrUpdateCart(\n\tshoppingCart: {\nname:\"" + cartName + "\",\nrelatedParties:[ \n{ id: \"" + buyerId + "\", role: \"buyer\" },\n{ id: \"" + sellerId + "\", role: \"seller\" }\n]\ncartItems:[{action:\"add\", product:{id:\"" + cartItemId + "\"}}] \n}\n\n)\n{\n    ...CartData\n}\n}\nfragment PriceInfo on Price {\n  amount {\nvalue\n}\nname\nrecurrence\n  unitOfMeasure\n}\nfragment ProductDetail on ProductType {\nid\nname\nkind\n}\nfragment CartItemData on CartItem {\nid\naction\nquantity {\nunit\nvalue\n}\nstatus\nproduct {\n...ProductDetail\n}\n}\nfragment PartySummaryData on PartySummary {\nid\nname\nrole\n}\nfragment CartData on ShoppingCart {\nid\nname\nstatus\ncartItems {\n...CartItemData\n}\n  cartTotalPrices {\n...PriceInfo\n}\nrelatedParties {\n...PartySummaryData\n}\n}"}
        else:
            payload = {"query": "mutation {addOrUpdateCart(\n\tshoppingCart: {\nname:\"" + cartName + "\",\nrelatedParties:[ \n{ id: \"" + buyerId + "\", role: \"buyer\" },\n{ id: \"" + sellerId + "\", role: \"seller\" }\n]\ncartItems:[{action:\"add\", product:{id:\"" + cartItemId + "\"}} {action:\"add\", product:{id:\"" + fulfillmentItemId + "\"}} ] \n}\n\n)\n{\n    ...CartData\n}\n}\nfragment PriceInfo on Price {\n  amount {\nvalue\n}\nname\nrecurrence\n  unitOfMeasure\n}\nfragment ProductDetail on ProductType {\nid\nname\nkind\n}\nfragment CartItemData on CartItem {\nid\naction\nquantity {\nunit\nvalue\n}\nstatus\nproduct {\n...ProductDetail\n}\n}\nfragment PartySummaryData on PartySummary {\nid\nname\nrole\n}\nfragment CartData on ShoppingCart {\nid\nname\nstatus\ncartItems {\n...CartItemData\n}\n  cartTotalPrices {\n...PriceInfo\n}\nrelatedParties {\n...PartySummaryData\n}\n}"}

        if status == 200:
            header = bep_common.createBEPHeader(token, {}, True)
            logger.info ("header is:")
            logger.info(header)
            try:
                print ("payload is:")
                print(json.dumps(payload))
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = json.loads(r.text)
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling addOrUpdateCart offM Endpoint, Error --> " + str(e)

    def addOrUpdateExistingCart(self, cartId, buyerId, sellerId, cartItemId):
        """
        Method Name :  addOrUpdateCart
        Parameters  :  name, description, relatedParties, cartItems
        Description :  Posts addOrUpdateCart and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL
        payload = {"query":"mutation {addOrUpdateCart(\n\tshoppingCart: {\n id:\"" + cartId + "\",\n relatedParties:[ \n { id: \"" + buyerId + "\", role: \"buyer\" },\n { id: \"" + sellerId + "\", role: \"seller\" }\n ]\n cartItems:[{action:\"add\", product:{id:\"" + cartItemId + "\"}}] \n } \n \n)\n{\n ...CartData\n }\n}\nfragment PriceInfo on Price {\n amount {\n value\n }\n name\n recurrence\n  unitOfMeasure\n}\nfragment ProductDetail on ProductType {\n id\n name\n  kind\n}\nfragment CartItemData on CartItem {\n id\n action\n quantity {\n unit\n value\n }\n status\n product {\n ...ProductDetail\n }\n}\nfragment PartySummaryData on PartySummary {\n id\n  name\n  role\n}\nfragment CartData on ShoppingCart {\n id\n name\n status\n cartItems {\n ...CartItemData\n }\n cartTotalPrices {\n ...PriceInfo\n }\n relatedParties {\n ...PartySummaryData\n }\n}"}


        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            logger.info ("header is:")
            logger.info(header)
            try:

                print ("payload is:")
                print(json.dumps(payload))
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = json.loads(r.text)
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling addOrUpdateExistingCart offM Endpoint, Error --> " + str(e)

    def getCartItem(self, cartId, cartItemId):
        """
        Method Name :  getCartItem
        Parameters  :  cartId, cartItemId
        Description :  Posts getCartItem and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL

        payload = {
            "query": "\nquery {\n  getCartItem(cartId:\"" + cartId + "\", cartItemId: \"" + cartItemId + "\") {\n    ... CartItemData\n    }\n}\n\nfragment CartItemData on CartItem {\n    id\n    action\n    quantity {\n        unit\n        value\n    }\n    status\n    itemPrices {\n        ...PriceInfo\n    }\n    product {\n        ...ProductDetail\n        products {\n            ...ProductDetail\n            products {\n                ...ProductDetail\n                products {\n                    ...ProductDetail\n                }\n            }\n        }\n    }\n\n}\n\nfragment PriceInfo on CartPrice {\n    amount {\n        currency {\n            ...fullCurrency\n        }\n        value\n    }\ndescription\n    id\n    name\n    percentage\n    priceType\n    recurrence\n    unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n  name\n  alphabeticCode\n  numericCode\n  minorUnits\n  majorUnitSymbol\n}\n\nfragment ProductDetail on ProductType {\n    id\n    name\n    description\n    kind\n    characteristics {\n        ...CharacteristicDetail\n    }\n    prices {\n        ...PriceInfo\n    }\n\n}\n\nfragment CharacteristicDetail on Characteristic {\n\n    name\n    value\n    valueType\n}"}
        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            logger.info ("header is:")
            logger.info(header)
            try:
                logger.info ("header is:")
                logger.info (header)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = json.loads(r.text)
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling getCartItem offM Endpoint, Error --> " + str(e)

    def getProduct(self, id, cartId):
        """
        Method Name :  getProduct
        Parameters  :  id, cartId
        Description :  Posts getProduct and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL
        payload = {
            "query": "\nquery {\n  getProduct(id:\"" + id + "\", cartId: \"" + cartId + "\") {\n  \n   ... ProductDetail\n  }\n}\n\n\nfragment ProductDetail on ProductType {\n    id\n    name\n    description\n    kind\n    characteristics {\n        ...CharacteristicDetail\n    }\n    prices {\n        ...PriceInfo\n    }\n\n}\n\nfragment CharacteristicDetail on Characteristic {\n\n    name\n    value\n    valueType\n}\n\nfragment PriceInfo on CartPrice {\n    amount {\n        currency {\n            ...fullCurrency\n        }\n        value\n    }\ndescription\n    id\n    name\n    percentage\n    priceType\n    recurrence\n    unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n  name\n  alphabeticCode\n  numericCode\n  minorUnits\n  majorUnitSymbol\n}"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            logger.info ("header is:")
            logger.info(header)
            try:
                logger.info ("header is:")
                logger.info (header)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = json.loads(r.text)
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling getProduct offM Endpoint, Error --> " + str(e)

    def findCart(self, filter, limit, nextToken):
        """
        Method Name :  findCart
        Parameters  :  filter, limit, nextToken
        Description :  Posts findCart and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        ############# This is not tested since implementation is not done ##########################

        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL

        payload = {
            "query": "{findCart(filter:\"" + filter + "\" , limit: \"" + limit + "\", nextToken: \"" + nextToken + "\"}){\n        ...CartData\n    }\n\n}\n\n\nfragment PriceInfo on CartPrice {\n    amount {\n        currency {\n            ...fullCurrency\n        }\n        value\n    }\n    description\n    id\n    name\n    percentage\n    priceType\n    recurrence\n    unitOfMeasure\n}\n\nfragment CartEvent on Event {\n    id\n    summary\n    eventDetail\n    kind\n    timestamp\n    requestedBy {\n        ...PartySummaryData\n    }\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n    name\n    value\n    valueType\n}\nfragment ProductDetail on ProductType {\n    id\n    name\n    description\n    kind\n    characteristics {\n        ...CharacteristicDetail\n    }\n    prices {\n        ...PriceInfo\n    }\n\n}\nfragment CartItemData on CartItem {\n    id\n    action\n    quantity {\n        unit\n        value\n    }\n    status\n    itemPrices {\n        ...PriceInfo\n    }\n    product {\n        ...ProductDetail\n        products {\n            ...ProductDetail\n            products {\n                ...ProductDetail\n                products {\n                    ...ProductDetail\n                }\n            }\n        }\n    }\n\n}\n\nfragment PartySummaryData on PartySummary {\n    id\n    name\n    role\n}\n\nfragment CartData on ShoppingCart {\n    id\n    name\n    description\n    status\n    cartEvents {\n        ...CartEvent\n    }\n    cartItems {\n        ...CartItemData\n    }\n    cartTotalPrices {\n        ...PriceInfo\n    }\n    validFor {\n        startDateTime\n        endDateTime\n    }\n    relatedParties {\n        ...PartySummaryData\n    }\n}\n\nfragment fullCurrency on Currency {\n    name\n    alphabeticCode\n    numericCode\n    majorUnitSymbol\n}"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            try:
                logger.info ("header is:")
                logger.info (header)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = json.loads(r.text)
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling findCart offM Endpoint, Error --> " + str(e)

    def deleteCartItem(self, cartId, cartItemId):
        """
        Method Name :  deleteCartItem
        Parameters  :  cartId, cartItemId
        Description :  Posts deleteCartItem and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL

        #logger.console("############# INPUTS ###################")
        #logger.console(cartItemId)

        #logger.console(cartId)


        payload = {"query":"mutation  {\n deleteCartItem(\n cartId: \"" + cartId +"\" \n cartItemId: \"" + cartItemId + "\"\n ) {\n ...CartData\n }\n}\n\n\nfragment PriceInfo on Price {\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n description\n name\n percentage\n kind\n recurrence\n unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n minorUnits\n majorUnitSymbol\n}\n\nfragment CartEvent on Event {\n id\n summary\n eventDetail\n kind\n timestamp\n requestedBy {\n ...PartySummaryData\n }\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n name\n value\n valueType\n}\nfragment ProductDetail on ProductType {\n id\n name\n description\n kind\n characteristics {\n ...CharacteristicDetail\n }\n prices {\n ...PriceInfo\n }\n\n}\nfragment CartItemData on CartItem {\n id\n action\n quantity {\n unit\n value\n }\n status\n itemPrices {\n ...PriceInfo\n }\n product {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n }\n }\n }\n }\n\n}\n\nfragment PartySummaryData on PartySummary {\n id\n name\n role\n}\n\nfragment CartData on ShoppingCart {\n id\n name\n status\n cartEvents {\n ...CartEvent\n }\n cartItems {\n ...CartItemData\n }\n cartTotalPrices {\n ...PriceInfo\n }\n validFor {\n startDateTime\n endDateTime\n }\n relatedParties {\n ...PartySummaryData\n }\n}"}


        #payload = {
        #    "query": "mutation {\n    deleteCartItem(\n        cartId: \"" + cartId + "\" \n        cartItemId: \"" + cartItemId + "\" \n    ) {\n        ...CartData\n    }\n}\n\nfragment PriceInfo on CartPrice {\n    amount {\n        currency {\n            ...fullCurrency\n        }\n        value\n    }\ndescription\n    id\n    name\n    percentage\n    priceType\n    recurrence\n    unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n  name\n  alphabeticCode\n  numericCode\n  minorUnits\n  majorUnitSymbol\n}\n\nfragment CartEvent on Event {\n    id\n    summary\n    eventDetail\n    kind\n    timestamp\n    requestedBy {\n        ...PartySummaryData\n    }\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n    name\n    value\n    valueType\n}\nfragment ProductDetail on ProductType {\n    id\n    name\n    description\n    kind\n    characteristics {\n        ...CharacteristicDetail\n    }\n    prices {\n        ...PriceInfo\n    }\n\n}\nfragment CartItemData on CartItem {\n    id\n    action\n    quantity {\n        unit\n        value\n    }\n    status\n    itemPrices {\n        ...PriceInfo\n    }\n    product {\n        ...ProductDetail\n        products {\n            ...ProductDetail\n            products {\n                ...ProductDetail\n                products {\n                    ...ProductDetail\n                }\n            }\n        }\n    }\n\n}\n\nfragment PartySummaryData on PartySummary {\n    id\n    name\n    role\n}\n\nfragment CartData on ShoppingCart {\n    id\n    name\n    description\n    status\n    cartEvents {\n        ...CartEvent\n    }\n    cartItems {\n        ...CartItemData\n    }\n    cartTotalPrices {\n        ...PriceInfo\n    }\n    validFor {\n        startDateTime\n        endDateTime\n    }\n    relatedParties {\n        ...PartySummaryData\n    }\n}"}
        #logger.console("############# line 213 ###################")
        if status == 200:
            #logger.console("############# line 215 ###################")
            header = bep_common.createBEPHeader(token,{},True)
            logger.info ("header is:")
            logger.info(header)
            try:
                #logger.console("############# line 218 ###################")
                print ("payload is:")
                print(json.dumps(payload))
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                #logger.console("############# line 222 ###################")
                print(r.status_code)
                logger.console(r)
                #logger.console("############# line 224 ###################")
                if r.status_code == 200:
                    #logger.console("############# line 226 ###################")
                    response = json.loads(r.text)
                    #logger.console("############# line 228 ###################")
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                #logger.console("############# line 229 ###################")
                return False, funcName + ":Error calling deleteCartItem offM Endpoint, Error --> " + str(e)

    def addOrUpdateCartItem(self, cartId, highLevelCartItemId, newProductTypeId):
        """
        Method Name :  addOrUpdateCartItem
        Parameters  :  cartId, shoppingCartItem
        Description :  Posts addOrUpdateCartItem and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL
        payload = {"query":"mutation  {\n addOrUpdateCartItem(\n cartId: \""+ cartId + "\"\n shoppingCartItem: {\n id: \"" + highLevelCartItemId + "\"\n action: \"add\"\n cartItems: [\n {\n action: \"add\"\n product: {\n id: \"" + newProductTypeId + "\"\n }\n }\n ]\n }\n ) {\n ...CartData\n }\n}\n\nfragment PriceInfo on Price {\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n description\n name\n percentage\n kind\n recurrence\n unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n  name\n  alphabeticCode\n  numericCode\n  minorUnits\n  majorUnitSymbol\n}\n\nfragment CartEvent on Event {\n id\n summary\n eventDetail\n kind\n timestamp\n requestedBy {\n ...PartySummaryData\n }\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n name\n value\n valueType\n}\nfragment ProductDetail on ProductType {\n id\n name\n description\n kind\n characteristics {\n ...CharacteristicDetail\n }\n prices {\n ...PriceInfo\n }\n\n}\nfragment CartItemData on CartItem {\n id\n action\n quantity {\n unit\n value\n }\n status\n itemPrices {\n ...PriceInfo\n }\n product {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n }\n }\n }\n }\n\n}\n\nfragment PartySummaryData on PartySummary {\n id\n name\n role\n}\n\nfragment CartData on ShoppingCart {\n id\n name\n status\n cartEvents {\n ...CartEvent\n }\n cartItems {\n ...CartItemData\n }\n cartTotalPrices {\n ...PriceInfo\n }\n validFor {\n startDateTime\n endDateTime\n }\n relatedParties {\n ...PartySummaryData\n }\n}"}

        if status == 200:
            header = bep_common.createBEPHeader(token,{},True)
            #ofmupdateCartStatus = header['X-BEP-Execution-Id']
            logger.info("header = " + str(header))

            try:
                logger.info("payload is:")
                logger.info(payload)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                if r.status_code == 200:
                    response = r.json()
                    return True, response
                else:
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                return False, funcName + ":Error calling getCart offM Endpoint, Error --> " + str(e)

    def addEmptyCart(self, cartName, buyerId, sellerId):
        """
        Method Name :  addEmptyCart
        Description :  Posts addEmptyCart with addOrUpdateCart and return response
        return      :  boolen and response (False when test fails with error message as response)
        """
        logger.info("############# line 301 ###################")
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        url = pom_parameters.POM_CART_DEV_URL
        payload = {"query":"mutation  {\n addOrUpdateCart(\n shoppingCart: {\n name: \"" + cartName + "\",\n relatedParties: [{id: \"" + buyerId + "\", role: \"buyer\"}, {id: \"" + sellerId + "\", role: \"seller\"}]\n }\n ) {\n ...CartData\n }\n}\n\n\nfragment PriceInfo on Price {\n amount {\n currency {\n ...fullCurrency\n }\n value\n }\n description\n name\n percentage\n kind\n recurrence\n unitOfMeasure\n}\n\nfragment fullCurrency on Currency {\n name\n alphabeticCode\n numericCode\n  minorUnits\n  majorUnitSymbol\n}\n\nfragment CartEvent on Event {\n id\n summary\n eventDetail\n kind\n timestamp\n requestedBy {\n ...PartySummaryData\n }\n\n}\nfragment CharacteristicDetail on Characteristic {\n\n name\n value\n valueType\n}\nfragment ProductDetail on ProductType {\n id\n name\n description\n kind\n characteristics {\n ...CharacteristicDetail\n }\n prices {\n ...PriceInfo\n }\n\n}\nfragment CartItemData on CartItem {\n id\n action\n quantity {\n unit\n value\n }\n status\n itemPrices {\n ...PriceInfo\n }\n product {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n products {\n ...ProductDetail\n }\n }\n }\n }\n\n}\n\nfragment PartySummaryData on PartySummary {\n id\n name\n role\n}\n\nfragment CartData on ShoppingCart {\n id\n name\n status\n cartEvents {\n ...CartEvent\n }\n cartItems {\n ...CartItemData\n }\n cartTotalPrices {\n ...PriceInfo\n }\n validFor {\n startDateTime\n endDateTime\n }\n relatedParties {\n ...PartySummaryData\n }\n}"}

        logger.info("############# line 309 ###################")

        logger.info ("payload is:")
        logger.info(url)
        logger.info(token)
        logger.info(json.dumps(payload))

        if status == 200:
            logger.info("############# line 315 ###################")

            header = bep_common.createBEPHeader(token,{},True)
            try:

                logger.info ("header is:")
                logger.info (header)
                r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
                print(r.status_code)
                logger.info("############# line 322 ###################")
                if r.status_code == 200:
                    logger.info("############# line 324 ###################")
                    response = json.loads(r.text)
                    return True, response
                else:
                    logger.info("############# line 328 ###################")
                    logger.info(str(r))
                    return False, "status code = " + str(r.status_code)
            except Exception as e:
                logger.info("############# line 331 ###################")
                return False, funcName + ":Error calling addEmptyCart offM Endpoint, Error --> " + str(e)
        else:
            logger.info("############# line 334 ###################")
            return False, funcName + ":Error generating token for OFFM in addEmptyCart Endpoint, Error --> " + str(status)

    def getVersion(self):
        funcName = sys._getframe().f_code.co_name
        comBep = bep_common.BEP_API()
        status, token = comBep.getBepJwtToken(pom_parameters.POM_JWT_URL)
        if status != 200:
            return False, funcName + ":" + token
        header = bep_common.createBEPHeader(token)
        payload = {"query":"query ofmAboutVersion {about\n\n{version buildTimeStamp}\n}"}
        try:
            url = pom_parameters.POM_CART_DEV_URL
            r = requests.post(url, headers=header, verify=False, data=json.dumps(payload))
            result = r.json()

            if r.status_code == 200:
                return True, result['data']
            else:
                return False, r.status_code
        except Exception as e:
            return False, funcName + ":Error calling " + funcName + " Endpoint, Error --> " + str(e)

def getProductTypeIdByKind(products,kind):
    for product in products:
        if product['kind']==kind:
            return product['id']
    return None

def getDataCapFromRequirement(planName, countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    elif countryCode == "NO":
        requirementfile = '../../VNO/EU/norway_plans.json'
    elif countryCode == "PL":
        requirementfile = '../../VNO/EU/poland_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        dataCap = plans[planName]["dataCap"]
        return dataCap

def getContractTermFromRequirement(planName, countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    elif countryCode == "NO":
        requirementfile = '../../VNO/EU/norway_plans.json'
    elif countryCode == "PL":
        requirementfile = '../../VNO/EU/poland_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        contractTerm = plans[planName]["contract"]
        return contractTerm

def getDownloadSpeedFromRequirement(planName, countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    elif countryCode == "NO":
        requirementfile = '../../VNO/EU/norway_plans.json'
    elif countryCode == "PL":
        requirementfile = '../../VNO/EU/poland_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        downloadSpeed = plans[planName]["downloadSpeed"]
        return downloadSpeed

def getUploadSpeedFromRequirement(planName, countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    elif countryCode == "NO":
        requirementfile = '../../VNO/EU/norway_plans.json'
    elif countryCode == "PL":
        requirementfile = '../../VNO/EU/poland_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        uploadSpeed = plans[planName]["uploadSpeed"]
        return uploadSpeed

def getPlanRateFromRequirement(planName, countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    elif countryCode == "NO":
        requirementfile = '../../VNO/EU/norway_plans.json'
    elif countryCode == "PL":
        requirementfile = '../../VNO/EU/poland_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        planRate = plans[planName]["rate"]
        return planRate

def getDiscountRateFromRequirement(planName,countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    elif countryCode == "PL":
        requirementfile = '../../VNO/EU/poland_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        discount = plans[planName]["discount"]
        return discount

def getSISMProductIdFromRequirement(planName):
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../../VNO/MX/mexico_plans.json'),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        sismProductId = plans[planName]["SISMProductId"]
        return sismProductId

def getFOProductIdFromRequirement(planName):
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../../VNO/MX/mexico_plans.json'),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        logger.info(planName)
       # if 'Cargo por' in planName:
       #     planName = 'Cargo por Activación'
       # elif 'Estandar' in planName:
       #     planName = 'Visita de Servicio - Estandar'
        FOProductId = plans[planName]["FOProductId"]
        return FOProductId

def getServiceDeliveryPartnerFromRequirement(planName):
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../../VNO/MX/mexico_plans.json'),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        serviceDeliveryPartner = plans[planName]["serviceDeliveryPartner"]
        return serviceDeliveryPartner

def getBuyMorePlanFromRequirement(planName, countryCode):
    if countryCode == "MX":
        requirementfile = '../../VNO/MX/mexico_plans.json'
    elif countryCode == "ES":
        requirementfile = '../../VNO/EU/spanish_plans.json'
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), requirementfile),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        buyMoreCount = plans[planName]["buyMoreCount"]
        return buyMoreCount

def getProductRateFromRequirement(planName):
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../../VNO/MX/mexico_plans.json'),
              "r") as plans_json_file:
        plans = json.load(plans_json_file)
        logger.info(planName)
        rate = plans[planName]["rate"]
        return rate

def usePomApi(apiMethod, *argv):
    funcName = sys._getframe().f_code.co_name
    pomApi = POM_API_LIB()
    if apiMethod == 'getOffers':
        if len(argv)==5:
            result = pomApi.getOffers(argv[0], argv[1], argv[2], argv[3], argv[4])
        else:
            result = pomApi.getOffers(argv[0], argv[1], argv[2], argv[3])
    elif apiMethod == 'getOffersBuyMore':
        result = pomApi.getOffersBuyMore(argv[0], argv[1], argv[2])
    elif apiMethod == 'getCart':
        result = pomApi.getCart(argv[0])
    elif apiMethod == 'deleteCart':
        result = pomApi.deleteCart(argv[0])
    elif apiMethod == 'addOrUpdateCart':
        result = pomApi.addOrUpdateCart(argv[0], argv[1], argv[2], argv[3], argv[4])
    elif apiMethod == 'getCartItem':
        result = pomApi.getCartItem(argv[0], argv[1])
    elif apiMethod == 'getProduct':
        result = pomApi.getProduct(argv[0], argv[1])
    elif apiMethod == 'findCart':
        result = pomApi.findCart(argv[0], argv[1], argv[2])
    elif apiMethod == 'deleteCartItem':
        result = pomApi.deleteCartItem(argv[0], argv[1])
    elif apiMethod == 'addOrUpdateCartItem':
        result = pomApi.addOrUpdateCartItem(argv[0], argv[1], argv[2])
    elif apiMethod == 'addEmptyCart':
        result = pomApi.addEmptyCart(argv[0], argv[1], argv[2])
    elif apiMethod == 'updateCartStatus':
        result = pomApi.updateCartStatus(argv[0], argv[1])
    elif apiMethod == 'addOrUpdateExistingCart':
        result = pomApi.addOrUpdateExistingCart(argv[0], argv[1], argv[2], argv[3])
    elif apiMethod == 'addItemPrices':
        result = pomApi.addItemPrices(argv[0])
    elif apiMethod == 'getTotalPriceAndCurrency':
        result = pomApi.getTotalPriceAndCurrency(argv[0])
    elif apiMethod == 'getVersion':
        result = pomApi.getVersion()

    else:
        result = (False, funcName + " incorrect number of arguments for " + funcName)

    return result

if __name__ == "__main__":
    pom = POM_API_LIB()
    result = pom.getVersion()
    print(str(result))