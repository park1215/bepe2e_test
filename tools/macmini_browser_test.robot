
################################################################
#
#  File name: macmini_browser_test.robot
#
#  Description: Mac Mini wifi and browser test
#
#  Author:  pgadekar
#
#  Runtime: ?:?? mins
#
#  Copyright (c) ViaSat, 2019
#
##############################################################

*** Settings ***
Resource  ../common/wifi/wifi_resources.robot

Test Setup  Browser Test Setup
Test Teardown  Browser Test Teardown

*** Comments ***
Usage : pybot -v MAC_MINI_IP:10.86.155.55 macmini_browser_test.robot 

*** Variables ***
${temp_ssid}    AA-Inflight


*** Test Cases ***

Simple Test
        ${stdout}    Get Connection
        Log To Console    ${stdout}
        Open Browser And Verify     ${TEST_URL}   ${WIKIPEDIA_TEXT}

*** Keywords ***

Browser Test Setup
        Set Suite Variable   ${MAC_MINI_IP}
        SSH To Mac Mini    ${MAC_MINI_IP}      
        Turn On Wifi On Mac    
        Connect To SSID    ${temp_ssid}
        #Verify And Start Selenium Jar

Browser Test Teardown
        Disconnect Mac Mini
        Close All SSH Connections
        Close all browsers
