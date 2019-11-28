################################################################
#
#  File name: cpe_speed_web_test.robot
#
#  Description: Linux CPE speed test & web browser test
#
#  Author:  pgadekar
#
#  Runtime: ?:?? mins
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
*** Settings ***
Resource    ../common/resource.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown
Test Setup          Connect To CPE    ${cpe_ip}    ${modem_type}
Test Teardown       Disconnect Cpe SSH

*** Comments ***
Usage : robot -v modem_ip:10.240.109.14 -v cpe_ip:10.247.41.90 cpe_speed_web_test.robot

#  DESCRIPTION
#  Test suite to run speed test on cpe. It also verifies internet connectivity by opening browser.

*** Variables ***


*** Test Cases ***
Verify Speed Test On Cpe
    [Tags]    speed
    Run And Log Speed Test

Verify Browser Test On Cpe
    [Setup]    Cpe Browser Setup
    [Tags]    browser
    Log To Console    parameters are set
    Open Browser And Verify on CPE    http://cnn.com    cnn
    [Teardown]    Browser Teardown
    
*** Keywords ***
Suite Setup
    Verify Modem State
    Verify Cpe State    ${cpe_ip}

Verify Modem State   
    Connect To Modem    ${modem_ip}
    Wait For Modem Online
    Wait For Verify CSP Status Is True On Modem
    Disconnect Modem SSH
    
Suite Teardown
    Close All SSH Connections
