import os,sys
import logging
import om_api
import uuid

#location = {"addressLine": "Av. de las Américas 100","addressLine2": "Suite 10","isoCountryCode": {"name": "Mexico","alphabeticThreeCharacterCode":"MEX"},"city": "San Felipe V Etapa"}
#location = '{addressLine:"Av. de las Americas 105",addressLine2:"Suite 25",isoCountryCode:{name:"Mexico",alphabeticThreeCharacterCode:"MEX"},city:"San Felipe V Etapa"}'
location = '{addressLine:"Av. de las Americas 108",addressLine2:"Suite 25",isCountryCode:{name:"Mexico",alphabeticThreeCharacterCode:"MEX"},city:"San Felipe V Etapa"}'

orderId = str(uuid.uuid1())
shoppingCartId = str(uuid.uuid1())
customerRelationshipId = str(uuid.uuid1())
omlib = om_api.OM_API_LIB()
#result = omlib.upsertOrder(orderId, shoppingCartId, customerRelationshipId, location)
#result = omlib.getOrder("order-113")
result = omlib.getVersion()
print(result)
	

