import os,sys
import logging
import tng_api as tng_api
#import wifi_params as wifi_params

wifiSet1= '{"model": "Ruckus ZoneFlex T300e", "mac": "1C:B9:C4:37:62:D0", "serial": "241603504046"}'
wifiSet2= '[{"model": "Ruckus ZoneFlex T300e","mac": "1C:B9:C4:37:62:D0","serial": "241603504046"}, {"model": "MikroTik RB750Gr3","mac": "64:D1:54:54:B6:3B","serial": "6F3907541AFE"}]'

def run():

    tngApi = tng_api.TNG_API_Lib()
    status, token = tngApi.getTngToken("VWS_Distributor_2","Password6")
    status = tngApi.bulkAddDevices(token, wifiSet2)
run()
