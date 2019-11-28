from robot.api import logger
import json
'''
def buildCurrencyInput(name, alphabeticCode, majorUnitSymbol):
def buildMoneyInput(amount, currency):
def buildPriceInput(money, kind, recurrence):
    
def buildPartyInput(partyId, name, roles)
'''

def buildAddressInput(addressLines, city, regionOrState, isoCountryCode, zipOrPostCode=None):
    if zipOrPostCode==None:
        addressInput = {'addressLine':addressLines,'city':city,regionOrState:regionOrState,isoCountryCode:isoCountryCode}
    else:
        addressInput = '{addressLine:'+str(addressLines)+',city:"'+city+'",regionOrState:"'+regionOrState+'",isoCountryCode:"'+str(isoCountryCode)+'",zipOrPostCode:"'+zipOrPostCode+'"}'
    return addressInput

def buildStringFromDict(dictInput):
    if isinstance(dictInput,dict):
        strOutput = '{'
        for key in dictInput.keys():
            if isinstance(dictInput[key],dict):
                dictToStr = buildStringFromDict(dictInput[key])
                strOutput = strOutput + key + ':' + dictToStr + ','
            elif isinstance(dictInput[key],list):
                strOutput = strOutput +  key + ':['
                for item in dictInput[key]:
                    dictToStr = buildStringFromDict(item)                   
                    strOutput = strOutput + dictToStr + ','
                strOutput = strOutput[:-1] + '],'
            else:
                if isinstance(dictInput[key],str):
                    strOutput = strOutput + key + ':"' +  dictInput[key] + '",'
                else:
                    strOutput = strOutput + key + ':' +  str(dictInput[key]) + ','
        strOutput = strOutput[:-1] + '}'
        return strOutput
    else:
        return '"' + dictInput + '"'
        

def buildDateFilter(date1,date2):
    dateFilter = '{from:"'+date1+'",to:"'+date2+'"}'
    return dateFilter

def buildGetAvailableAppointments(serviceLocation, productTypeIds, sellerPartyId, dateFilter):
    return '{"query":"{getAvailableAppointments(input:{'+serviceLocation+','+productTypeIds+','+sellerPartyId+'},\
filters:'+dateFilter+'){productAvailableAppointments{productTypeIds,availableAppointments{ availableAppointmentId,from,to}}}}\
"}'
                     


