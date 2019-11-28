##############################################################
#
#  File name: portalLib.py
#
#  Description: UI related library methods
#
#  Author:  rbathina
#
#  History:
#
#  Date         Version   ModifiedBy  Description
#  -------------------------------------------------- -------
#  04/04/2017      0.1     rbathina     Created file
#
#  Copyright (c) ViaSat, 2017
#
##############################################################
# runs on mac mini...
import os
import sys
import time
import subprocess
from wireless import Wireless

"""
   Method Name :  connect_to_ssid
   Parameters  :  ssid, password
   Description :  Connect To Ssid keyword is run as the first keyword in suite just to
                  connect to wifi before starting the UI automation scripts.
   Parameters  :  ssid, password
   Return      :  None
"""
def connect_to_ssid(ssid, password=''):

    try:
        if sys.platform.startswith('darwin'):
            wireless_conn = Wireless()
            if (wireless_conn.connect(ssid, password)):
                print ("Successfully connected Mac Mini to ssid: %s" % ssid)
            else:
                print ("Mac Mini connection did not succeed to ssid: %s" % ssid)
                raise Exception("Connecting mac mini to SSID failed")
        elif sys.platform.startswith('win'):
            cmd = "netsh wlan connect ssid=%s name=%s" % (ssid, ssid)
            os.system(cmd)
            time.sleep(5)
            output = subprocess.check_output('netsh wlan show interfaces state', shell=True)
            if " connected" in output:
                print ("Successfully connected to windows machine ssid: %s" % ssid)
            else:
                print("Connecting Windows machine to ssid failed")
                raise Exception("Connecting windows machine to SSID failed")
    except Exception as err:
        print err
        raise


"""
   Method Name :  connect_to_ssid
   Parameters  :  ssid, password
   Description :  Connect To Ssid keyword is run as the first keyword in suite just to
                  connect to wifi before starting the UI automation scripts.
   Parameters  :  ssid, password
   Return      :  None
"""
def get_current_ssid():
    wireless_conn = Wireless()
    return wireless_conn.current()
