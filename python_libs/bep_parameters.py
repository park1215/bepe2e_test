import sys
import getpass
from demo_sprint3_parameters import *

PAYMENT_REFERENCE_TYPE = {'NA':'VPSNA','EU':'VPSEU'}

VPS_INFO = {"MexicoResidential":{"BASE_URL":"https://viasatamer--uat.my.salesforce.com/"}, \
            "PAYE-00005":{"BASE_URL":"https://viasateu--uat.cs87.my.salesforce.com/"}, \
            "PAYE-00006":{"BASE_URL":"https://viasateu--uat.cs87.my.salesforce.com/"}, \
            "PAYE-00007":{"BASE_URL":"https://viasateu--uat.cs87.my.salesforce.com/"}}

DEFAULT_VPS_SYSTEM_NAME='MexicoResidential'
VPS_PAYMENT_SERVICE_ENDPOINT = "services/apexrest/paymentservice"
VPS_PAYMENT_ON_FILE_ENDPOINT = "services/apexrest/paymentonfile"
VPS_BATCH_ENDPOINT = "services/apexrest/batchtransaction"
VPS_AUTH_ENDPOINT = "services/oauth2/token"

TEST_NAME_PREFIX = "Bepe2e_"
# UTN = use test name - abbreviated so easier to type out in command line
UTN = True
USERNAME_TEST_NAME_PREFIX = getpass.getuser()+"_"
SELECTED_PLAN = None

# can override country code
ES = "ES"
MX = "MX"
COUNTRY_CODE = ES
VPS_INSTANCES = {"MX":"NA","ES":"EU","NO":"EU","PL":"EU"}

# override txnAmount, customerRef in scripts
VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS = {'txnType':'Sale','txnAmount':'10.00','customerRef':'ce169685-8265-4849-b80a-3ba0cf0fa2d6','userAgent':'API'}
# various inputs to "request payment on file"

VPS_AUTH_DEFAULTS ={"systemName":DEFAULT_VPS_SYSTEM_NAME,"nameOnCard":"Jane Doe","ccNumber":"4400000000000008","ccExpYear":2020,"ccExpMonth":10,"ccCVV":"737","saveCard":True,"useAsDefault":True,"useForRecurringPayment":True}

VPS_RPOF_DEFAULTS = {"systemName":DEFAULT_VPS_SYSTEM_NAME,"nameOnCard":"Jane Doe","ccNumber":"4484600000000004","ccExpYear":2020,"ccExpMonth":10,"ccCVV":"737","useAsDefault":False,\
                     "useForRecurringPayment":True}
VPS_POF_DEFAULTS = {"systemName":DEFAULT_VPS_SYSTEM_NAME,"nameOnCard":"Jane Doe","ccNumber":"4400000000000008","ccExpYear":2020,"ccExpMonth":10,"ccCVV":"737","useAsDefault":False,\
                     "useForRecurringPayment":False}
VPS_POF_AMEX_DEFAULTS = {"systemName":DEFAULT_VPS_SYSTEM_NAME,"nameOnCard":"Amex User","ccNumber":"370000000100018","ccExpYear":2020,"ccExpMonth":10,"ccCVV":"7373","useAsDefault":False,\
                     "useForRecurringPayment":False}
VPS_POF_DC_DEFAULTS = {"systemName":DEFAULT_VPS_SYSTEM_NAME,"nameOnCard":"DC User","ccNumber":"36006666333344","ccExpYear":2020,"ccExpMonth":10,"ccCVV":"737","useAsDefault":False,\
                     "useForRecurringPayment":False}
VPS_POF_MC_DEFAULTS = {"systemName":DEFAULT_VPS_SYSTEM_NAME,"nameOnCard":"Mastercard User","ccNumber":"5585558555855583","ccExpYear":2020,"ccExpMonth":10,"ccCVV":"737","useAsDefault":False,\
                     "useForRecurringPayment":False}
VPS_POF_CBT_DEFAULTS = {"systemName":'PAYE-00006',"noOperationType":"CustBankTransfer","useAsDefault":False,"useForRecurringPayment":False}
VPS_SEPA_DEFAULTS = {"systemName":'PAYE-00007',"sepa":{"accountName":"A. Klaassen","ibanAccountNumber":"NL13TEST0123456789"},"useForRecurringPayment":True}
VPS_ACH_DEFAULTS = {"ach":{"accountName":"Ach User","accountNumber":"123456789","abaRoutingNumber":"011000138"}}

VPS_FAIL_CARD = {'nameOnCard':'BLOCKED_CARD : 06 : ERROR','ccNumber':'4001590000000001','ccExpYear':2020,'ccExpMonth':10,'ccCVV':'737'}

VPS_BILLING_ADDRESS =  {"postalCode":"92009"}
VPS_CC_SELECTIONS = ['Visa','MasterCard','American Express','Diners Club']
VPS_PAYMENT_METHODS = {"Visa":VPS_POF_DEFAULTS,"MasterCard":VPS_POF_MC_DEFAULTS,"SEPA":VPS_SEPA_DEFAULTS,"American Express":VPS_POF_AMEX_DEFAULTS, \
                       "Diners Club":VPS_POF_DC_DEFAULTS,"CustBankTransfer":VPS_POF_CBT_DEFAULTS}

VPS_PAYMENT_TYPE_MAPPING = {'Visa':'CC','MasterCard':'CC','American Express':'CC','Diners Club':'CC','CustBankTransfer':'CustBankTransfer','SEPA':'SEPA'}
VPS_PAYMENT_TYPES = {"ES":{'CC':15,'SEPA':16,'ACH':17},"MX":{'CC':13},"PL":{'CC':21,'SEPA':22},"NO":{'CC':18,'CustBankTransfer':20}}
VPS_PAYMENT_TYPE_OTP = {"ES":'ANY',"MX":'CC',"PL":'CC',"NO":'CC'}

# defaults, can override with input variable or randomizer
RANDOMIZE_OTP = True
RANDOMIZE_RECURRING_PAYMENT = True
VPS_PAYMENT_METHOD = "American Express"
VPS_RECURRING_PAYMENT_METHOD = "Diners Club"

REAL_MODEM = False

# defaults, can be overriden by passing -v RANDOMIZE_IRA_EXTERNAL_ID:False -v IRA_EXTERNAL_ID:<TIN/VAT>
#RANDOMIZE_IRA_EXTERNAL_ID = True
IRA_EXTERNAL_ID = "TIN"
IRA_EXTERNAL_ID_SELECTIONS = ['TIN','VAT']

# recurring payments - eventually use lookups that follow this
BATCH_PAYMENT_REQUEST = {"ES":{'prefix':'VGBP_ESP','index_17':15,'index_2':'EUR'},"MX":{'prefix':'VGBP_MEX','index_17':13,'index_2':'MXN'}, \
                         "NO":{'prefix':'VGBP_NOR','index_17':18,'index_2':'NOK'}}

####################### Country VARIABLES #####################

COUNTRY_VARIABLES = { 
    "MX":{ \
            "LAT_LONG_REQ":True, \
            "CONTRACT_TEMPLATE_ID": "2000", \
            "INVITE_SIGNER":"true", \
            "SERTIFI_API_CODE":"299A0DFD-ABF0-4D12-B28E-ADDBC76EB1BA", \
            "CMS_EMAIL_TEXT_BEFORE_SIGN":"has sent you the file", \
            "CMS_EMAIL_TEXT_AFTER_SIGN":"have been received", \
            "ORG_ID":"fe34ee49-6198-44b0-a96a-baa39bf59175", \
            "TOTAL_PLANS":{"FIXED_SATELLITE_INTERNET":6,"FULFILLMENT":2}, \
            "TOTAL_SUB_PRODUCTS":3, \
            "SUBPRODUCTS":{"SERVICE_CONTRACT":{"name":"Contract","tariffName":"12 Month Contract - MX"}, \
                           "EQUIPMENT_LEASE_FEE":{"name":"Lease Fee - Monthly","tariffName":"Lease Fee - Monthly - MX"}}, \
            "OTCS":{"FULFILLMENT":{"name":"Activation Fee"}}, \
            "OPTIONS":{"EQUIPMENT_LEASE_FEE":{"Fixed Satellite Monthly Lease Fee":{"name":"Lease Fee - Monthly","tariffName":"Lease Fee - Monthly - MX"}, \
                                               "Fixed Satellite Lifetime Lease CFS":{"name":"Lease Fee - Lifetime Lease Fee Charge","tariffName":"Lease Fee - Lifetime Charge - MX"}}}, \
            "OTCS_EQUIPMENT_LIFETIME_LEASE":{"name":"Lease Fee - Lifetime Lease- Charge"}, \
            "INTERNET_NAME":{"name":"Internet"}, \
            "SERVICE_CONTRACT_KIND":"SERVICE_CONTRACT", \
            "DISCOUNT_KIND":"XXX", \
            "MONTHLY_LEASE_NAME":"Fixed Satellite Monthly Lease Fee", \
            "LIFETIME_LEASE_NAME":"Fixed Satellite Lifetime Lease CFS", \
            "EQUIPMENT_LEASE_FEE_KIND":"EQUIPMENT_LEASE_FEE", \
            "CHILD_PRODUCTS":["FIXED_SATELLITE_SERVICE", "SERVICE_CONTRACT", "OPTION_GROUP"], \
            "SATELLITE_INTERNET_KIND":"FIXED_SATELLITE_INTERNET", \
            "SATELLITE_SERVICE_KIND":"FIXED_SATELLITE_SERVICE", \
            "FULFILLMENT_KIND":"FULFILLMENT", \
            "FULFILLMENT_OFFERS":{"Cargo por Activación":{},"Visita de Servicio - Estandar":{}}, \
            "CURRENCY":"Mexican Peso", \
            "CURRENCY_DICT":{"name":"Mexican Peso","alphabeticCode":"MXN","numericCode":484,"majorUnitSymbol":"$","minorUnits":2}, \
            "INVOICING_ORG":2, \
            "VPS_SYSTEM_NAME": "MexicoResidential", \
            "VPS_INSTANCE":  "VPSNA", \
            "FULFILLMENT_PARTNER_ID": "83d0d084-0dab-4f4e-bb54-cb43decdd53a", \
            # dealer id according to bepr-148
            "DEALER_ID": "200005374", \
            "INSTALLATION_PRODUCT_NAME": "Cargo por Activación", \
            "EQUIPMENT_KIND" : "EQUIPMENT" ,\
            "OPTION_GROUP_KIND" : "OPTION_GROUP", \
            "RESIDENTIAL_INTERNET_INSTALLATION_KIND": "RESIDENTIAL_INTERNET_INSTALLATION", \
            "PROVIDER_GROUP":"MexicoResidential", \
            "TIN":"mexico_rfc_id", \
            "RANDOMIZE_IRA_EXTERNAL_ID":False, \
            "THREE_CHAR_COUNTRY_CODE":"MX", \
            "TWO_CHAR_COUNTRY_CODE":"MX", \
            "PAYMENT_METHODS":["Diners Club","Visa"], \
            "INVOICING_ORGANIZATION": 'MEXICO', \
            "BILL_DATES":[3,11,19,27], \
            "PHONE_NUMBER_LENGTH":10, \
            "PHONE_COUNTRY_CODE":52, \
            "PRODUCT_PLAN":"Internet", \
            "MODEM":{"SDP_JWT_NAME":"mxres", "REALM":"mx5.mxres.viasat.com"}, \
            "REAL_MODEM_ADDRESSES":[{"addressLine":["Morelos No. 43"],"municipality":"Jacona De Plancarte Centro","region":"MIC","postalCode":"59800", \
                          "beam":795, "coordinates":{"latitude": 20.598638, "longitude": -100.464699} }, \
                         {"addressLine":["Aramen 500"],"municipality":"Morelia","region":"MIC","postalCode":"58000", \
                           "beam":796, "coordinates":{"latitude": 19.432608, "longitude": -99.133209} },  \
                         {"addressLine":["Sinaloa 1100 S/N"],"municipality":"Culiacán","region":"SIN","postalCode":"80060", \
                          "beam":702, "coordinates":{"latitude": 32.667496, "longitude": -115.428990}}],  \
            "ADDRESSES":[#{"addressLine":["Morelos No. 43"],"municipality":"Jacona De Plancarte Centro","region":"MIC","postalCode":"59800", \
                         # "beam":794, "coordinates":{"latitude": 30.758638, "longitude": -106.464699} }, \
                         #{"addressLine":["Gonzalitos e Insurgentes SN"],"municipality":"Vista Hermosa","region":"NLE","postalCode":"66420", \
                         # "beam":550, "coordinates":{"latitude": 25.684126, "longitude": -100.352219} },  \
                         #{"addressLine":["Aramen 500"],"municipality":"Morelia","region":"MIC","postalCode":"58000", \
                         #  "beam":562, "coordinates":{"latitude": 19.683294, "longitude": -101.185577} },  \
                         #{"addressLine":["Adolfo Ruiz Cortines 3495"],"municipality":"Boca Del Rio","region":"VER","postalCode":"94298", \
                         # "beam":797, "coordinates":{"latitude": 19.139552, "longitude": -96.106214} },  \
                         #{"addressLine":["Calle Primera No. 1000"],"municipality":"Ensenada","region":"BCN","postalCode":"22800", \
                         # "beam":522, "coordinates":{"latitude": 31.862269, "longitude": -116.625980} },  \
                         #{"addressLine":["Calzada Conasupo 55"],"municipality":"Tuxtla Gutiérrez","region":"CHP","postalCode":"29000", \
                         # "beam":576, "coordinates":{"latitude": 16.750323, "longitude": -93.178944} },  \
                         #{"addressLine":["Sinaloa 1100 S/N"],"municipality":"Culiacán","region":"SIN","postalCode":"80060", \
                         # "beam":548, "coordinates":{"latitude": 24.815937, "longitude": -107.373895}}],  \
                         {"addressLine":["Colinas del Poniente"],"municipality":"Santiago de Querétaro","region":"QUE","postalCode":"76117", \
                          "beam":795, "coordinates":{"latitude": 20.598638, "longitude": -100.464699} }, \
                         {"addressLine":["Calle de Venustiano Carranza 135"],"municipality":"Ciudad de México","region":"CMX","postalCode":"06000", \
                           "beam":796, "coordinates":{"latitude": 19.432608, "longitude": -99.133209} },  \
                         {"addressLine":["Mariano Azuela 10","Hipico"],"municipality":"Mexicali","region":"BCN","postalCode":"21210", \
                          "beam":702, "coordinates":{"latitude": 32.667496, "longitude": -115.428990}}],  \
                         #{"addressLine":["Calle Regato 219","Zona Centro"],"municipality":"Durango","region":"DUR","postalCode":"34000", \
                         # "beam":702, "coordinates":{"latitude": 24.030626, "longitude": -104.662202}}],  \
            "BILLING_ADDRESSES":[{"addressLine":["Prolongacion Jose Maria Morelos y Pavon 1017","Col. Centro"],"municipality":"Monterrey ","region":"NLE","postalCode":"64800","countryCode":"MX"}, \
                         {"addressLine":["Paseo La Marina Norte 435","Marina Vallarta"],"municipality":"Puerto Vallarta","region":"JAL","postalCode":"48354","countryCode":"MX"},  \
                         {"addressLine":["Carretera Chetumal-Puerto Juarez Km 266.3 Xpu Ha"],"municipality":"Puerto Aventuras","region":"ROO","postalCode":"77750","countryCode":"MX"}]  \
            }, \
        "ES":{ \
            "LAT_LONG_REQ":False, \
            "CONTRACT_TEMPLATE_ID": "XXX", \
            "INVITE_SIGNER":"XXX", \
            "SERTIFI_API_CODE":"XXX", \
            "ORG_ID":"0e080444-a1c9-11e9-90b9-02e0bfa4ac13", \
            "TOTAL_PLANS":3, \
            "TOTAL_SUB_PRODUCTS":3, \
            "SUBPRODUCTS":{"SERVICE_CONTRACT":{"name":"Contract","tariffName":"12 Month Contract - 30/mo ETF"}, \
                           "DISCOUNT":{"name":"Discount","tariffName":"€10 off for 3 months"}}, \
            "SUBPRODUCTS_NAMES":['EU Internet','Contract','Discount'], \
            "SUBPRODUCTS_TARIFF_NAMES":['12 Month Contract - 30/mo ETF','€10 off for 3 months'], \
            "INTERNET_NAME":{"name":"EU Internet"}, \
            "OTCS":{}, \
            "SERVICE_CONTRACT_KIND":"SERVICE_CONTRACT", \
            "DISCOUNT_KIND":"DISCOUNT", \
            "EQUIPMENT_LEASE_FEE_KIND":"XXX", \
            "SATELLITE_SERVICE_KIND":"FIXED_SATELLITE_SERVICE", \
            "SATELLITE_INTERNET_KIND":"FIXED_SATELLITE_INTERNET", \
            "CHILD_PRODUCTS":["FIXED_SATELLITE_SERVICE", "SERVICE_CONTRACT", "DISCOUNT"], \
            "CURRENCY":"Euro", \
            "CURRENCY_DICT":{"name":"Euro","alphabeticCode":"EUR","numericCode":978,"majorUnitSymbol":"€","minorUnits":2}, \
            "INVOICING_ORG":4, \
            "VPS_SYSTEM_NAME": "PAYE-00005", \
            "VPS_INSTANCE":  "VPSEU", \
            "FULFILLMENT_PARTNER_ID":"SPAIN", \
            "DEALER_ID":"UNKNOWN", \
            "PROVIDER_GROUP":"EUResidential", \
            "TIN":"spain_tin", \
            "TIN_RULES":{"digits":8,"letters":1}, \
            "TIN_GENERATOR":"Generate External Id For TIN", \
            "RANDOMIZE_IRA_EXTERNAL_ID":True, \
            "VAT":"vat_identification_number", \
            "VAT_GENERATOR":"Generate External Id For VAT", \
            "THREE_CHAR_COUNTRY_CODE":"ES", \
            "TWO_CHAR_COUNTRY_CODE":"ES", \
            "PHONE_NUMBER_LENGTH":9, \
            "PHONE_COUNTRY_CODE":34, \
            "PRODUCT_PLAN":"EU Internet", \
            "INVOICING_ORGANIZATION": 'SPAIN', \
            "BILL_DATES":[2,18], \
            "PAYMENT_METHODS":["MasterCard","Visa","Diners Club","American Express","SEPA"], \
            "BUY_MORE_DICT":{"Bono de datos 5GB":{"OTC_NAME":"Buy More - 5 GB"}, \
                            "Bono de datos 1GB":{"OTC_NAME":"Buy More - 1GB"}}, \
            "ADDRESSES":[{"addressLine":["Calle de Jacometrezo","Numero 6b"],"municipality":"Madrid","region":"MD","postalCode":"28013"}, \
                         {"addressLine":["Ctra. Villena"],"municipality":"Herrera de Pisuerga","region":"CL","postalCode":"34400"},  \
                         {"addressLine":["La Velilla Vedraza","Villa Rosa"],"municipality":"Segovia","region":"CL","postalCode":"40173"},  \
                         {"addressLine":["Valadouro"],"municipality":"Mañaria","region":"PV","postalCode":"48212"},  \
                         {"addressLine":["Plazuela do Porto"],"municipality":"Icod de los Vinos","region":"CN","postalCode":"38430"},  \
                         {"addressLine":["Avda. Andalucía"],"municipality":"Villamediana de Iregua","region":"RI","postalCode":"26142"},  \
                         {"addressLine":["Paraguay"],"municipality":"Dénia","region":"VC","postalCode":"03700"}],  \

            "BILLING_ADDRESSES":[{"addressLine":["Plaza Colón 19","Suite 11"],"municipality":"La Bañeza","region":"CL","postalCode":"28013","countryCode":"ES"}, \
                         {"addressLine":["Herrería 22"],"municipality":"Albolote","region":"AN","postalCode":"18220","countryCode":"ES"},  \
                         {"addressLine":["Bouciña 3"],"municipality":"Creixell","region":"CT","postalCode":"43838","countryCode":"ES"}]  \
            }, \
        "NO":{ \
            "LAT_LONG_REQ":False, \
            "CONTRACT_TEMPLATE_ID": "XXX", \
            "INVITE_SIGNER":"XXX", \
            "SERTIFI_API_CODE":"XXX", \
            "ORG_ID":"0e080444-a1c9-11e9-90b9-02e0bfa4ac13", \
            "TOTAL_PLANS":4, \
            "TOTAL_SUB_PRODUCTS":4, \
            "SUBPRODUCTS":{"SERVICE_CONTRACT":{"name":"Contract","tariffName":"12 Month Contract"}, \
                           "EQUIPMENT_LEASE_FEE":{"name":"Lease Fee - Monthly","tariffName":"Equipment Lease Fee"}}, \
            "INTERNET_NAME":{"name":"EU Internet"}, \
            "OTCS":{"ACTIVATION_FEE":{"name":"Establishment"}}, \
            "SERVICE_CONTRACT_KIND":"SERVICE_CONTRACT", \
            "DISCOUNT_KIND":"DISCOUNT", \
            "EQUIPMENT_LEASE_FEE_KIND":"EQUIPMENT_LEASE_FEE", \
            "SATELLITE_SERVICE_KIND":"FIXED_SATELLITE_SERVICE", \
            "SATELLITE_INTERNET_KIND":"FIXED_SATELLITE_INTERNET", \
            "CHILD_PRODUCTS":["FIXED_SATELLITE_SERVICE", "SERVICE_CONTRACT", "EQUIPMENT_LEASE_FEE", "ACTIVATION_FEE"], \
            "CURRENCY":"Norwegian Krone", \
            "CURRENCY_DICT":{"name":"Norwegian krone","alphabeticCode":"NOK","numericCode":578,"majorUnitSymbol":"kr","minorUnits":2}, \
            "INVOICING_ORG":5, \
            "VPS_SYSTEM_NAME": "PAYE-00006", \
            "VPS_INSTANCE":  "VPSEU", \
            "FULFILLMENT_PARTNER_ID":"NORWAY", \
            "DEALER_ID":"UNKNOWN", \
            "PROVIDER_GROUP":"EUResidential", \
            "TIN":"norway_tin", \
            "TIN_GENERATOR":"Use Norway TIN Generator", \
            "RANDOMIZE_IRA_EXTERNAL_ID":True, \
            "VAT":"vat_identification_number", \
            "VAT_GENERATOR":"Use Norway VAT Generator", \
            "PHONE_NUMBER_LENGTH":8, \
            "PHONE_COUNTRY_CODE":47, \
            "PRODUCT_PLAN":"EU Internet", \
            "INVOICING_ORGANIZATION": 'NORWAY', \
            # from https://wiki.viasat.com/display/FPsvcs/EU+-+Norway+-+MVP+Requirements NO - FCA - 006
            "BILL_DATES":[10,22], \
            "PAYMENT_METHODS":["MasterCard","Visa","CustBankTransfer","American Express","Diners Club"], \
            "ADDRESSES":[{"addressLine":["Nygaardsgaten 31"],"municipality":"Bergen","region":"","postalCode":"5015"}, \
                         {"addressLine":["Sjoegata 7"],"municipality":"Tromso","region":"","postalCode":"9008"}], \
            "BILLING_ADDRESSES":[{"addressLine":["Dronningens gate 5"],"municipality":"Trondheim","region":"","postalCode":"7011","countryCode":"NO"}, \
                         {"addressLine":["Sonja Henies Plass 3"],"municipality":"Oslo","region":"","postalCode":"0185","countryCode":"NO"}]  \
            }, \
        "PL":{ \
            "LAT_LONG_REQ": False, \
            "CONTRACT_TEMPLATE_ID": "XXX", \
            "INVITE_SIGNER": "XXX", \
            "SERTIFI_API_CODE": "XXX", \
            "ORG_ID": "0e080444-a1c9-11e9-90b9-02e0bfa4ac13", \
            "TOTAL_PLANS": 3, \
            "TOTAL_SUB_PRODUCTS": 4, \
            "SUBPRODUCTS": {"SERVICE_CONTRACT": {"name": "Contract", "tariffName": "24 Months Contract - Poland"}, \
                            "DISCOUNT": {"name": "Discount", "tariffName": "20 zł off for 3 months"}, "EQUIPMENT_LEASE_FEE": {"name": "Lease Fee - Monthly", "tariffName": "Equipment Lease Fee - Poland"}}, \
            "SUBPRODUCTS_TARIFF_NAMES":['24 Months Contract - Poland','20 zł off for 3 months', 'Equipment Lease Fee - Poland'], \
            "SUBPRODUCTS_NAMES":['EU Internet','Contract','Discount', 'Lease Fee - Monthly'], \
            "INTERNET_NAME":{"name":"EU Internet"}, \
            "OTCS":{}, \
            "SERVICE_CONTRACT_KIND": "SERVICE_CONTRACT", \
            "DISCOUNT_KIND": "DISCOUNT", \
            "EQUIPMENT_LEASE_FEE_KIND": "EQUIPMENT_LEASE_FEE", \
            "SATELLITE_SERVICE_KIND": "FIXED_SATELLITE_SERVICE", \
            "SATELLITE_INTERNET_KIND": "FIXED_SATELLITE_INTERNET", \
            "CHILD_PRODUCTS": ["FIXED_SATELLITE_SERVICE", "SERVICE_CONTRACT", "EQUIPMENT_LEASE_FEE", "DISCOUNT"], \
            "CURRENCY": "Zloty", \
            "CURRENCY_DICT": {"name": "Polish zloty", "alphabeticCode": "PLN", "numericCode": 985,
                              "majorUnitSymbol": "zł", "minorUnits": 2}, \
            "INVOICING_ORG": 6, \
            "VPS_SYSTEM_NAME": "PAYE-00007", \
            "VPS_INSTANCE":  "VPSEU", \
            "FULFILLMENT_PARTNER_ID": "POLAND", \
            "DEALER_ID": "UNKNOWN", \
            "PROVIDER_GROUP": "EUResidential", \
            "TIN": "poland_tin", \
            "TIN_GENERATOR": "Use Poland TIN Generator", \
            "RANDOMIZE_IRA_EXTERNAL_ID": True, \
            "VAT": "poland_tin", \
            "VAT_GENERATOR": "Use Poland PESEL VAT Generator", \
            "PHONE_NUMBER_LENGTH": 9, \
            "PHONE_COUNTRY_CODE": 48, \
            "PRODUCT_PLAN": "EU Internet", \
            "INVOICING_ORGANIZATION": 'POLAND', \
            # from https://wiki.viasat.com/display/FPsvcs/EU+-+Norway+-+MVP+Requirements NO - FCA - 006
            "BILL_DATES": [15, 26], \
            "PAYMENT_METHODS": ["MasterCard", "Visa", "CustBankTransfer", "American Express", "Diners Club"], \
            "ADDRESSES": [
                {"addressLine": ["Nygaardsgaten 31"], "municipality": "Wroclaw", "region": "WRO", "postalCode": "50-017"}, \
                {"addressLine": ["Ul. Orzechowa 11"], "municipality": "Swinoujscie", "region": "WRO", "postalCode": "30-422"}, \
                ], \
            "BILLING_ADDRESSES": [
                {"addressLine": ["Dronningens gate 5"], "municipality": "Wroclaw", "region": "WRO", "postalCode": "50-017",
                 "countryCode": "PL"}, \
                ] \
            } \
    }

DIFFERENT_BILLING_ADDRESS = True

S3_PAYMENT_REQUEST_BUCKET="spb-nonprod-netcracker9p-us-west-2-in"
S3_PAYMENT_RESPONSE_BUCKET="spb-nonprod-netcracker9p-us-west-2-out"
S3_ARCHIVE_BUCKET="spb-nonprod-netcracker9p-us-west-2-archive"
S3_ARCHIVE_READ_ROLE="arn:aws:iam::206977378963:role/bep_e2e_read_archive_role"
S3_PAYMENT_PREFIX="payments/"

BEPTEST_EMAIL_BUCKET = "beptest-email"
