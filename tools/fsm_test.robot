################################################################
#
#  File name: fsm_test.robot
#
#  Description: FSM GUI Login to perform the following functions -->
#              Lookup WorkOrder and move it to Complete Status
#              This triggers FSM to call CustomerSearch & AccountInfo & ModemQuery to retrieve modem MAC & SN information
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

*** Comments ***
need to provide modem mac when this script runs in demo_provision suite else it uses default modem from test.ymal
Usage : robot -v modem_ip:10.240.109.14 -v modem_mac_colon:00:A0:BC:6C:7D:6A fsm_test.robot

#  DESCRIPTION
#  Test suite to change order status to complete to trigger FSM to call CustomerSearch & AccountInfo & ModemQuery to retrieve modem MAC & SN information

*** Variables ***


*** Test Cases ***
Change The Order Status To Complete
    [Tags]    fsm
    Verify And Start Selenium Jar On Bep
    Log To Console    jar started
    Login To FSM Gui
    #Verify Status Is Systemic    
    Change Status To Completed
    Log To Console    entry received
    
*** Keywords ***
Suite Setup
    Verify Modem State
    Log To Console   modem verification done
    #Set Suite Variable    ${ntd_id}    403023526
    #Set Suite Variable    ${ntd_id}    302769626
    Set Suite Variable    ${ntd_id}    403028368

Verify Modem State   
    Connect To Modem    ${modem_ip}
    Wait For Modem Online
    Wait For Verify CSP Status Is True On Modem
    Disconnect Modem SSH
    
Suite Teardown
    [Documentation]     Teardown for browser tests
    Run    pkill chrome
    Close All SSH Connections
    
    
