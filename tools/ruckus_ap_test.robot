################################################################
#
#  File name: ruckus_ap_test.robot
#
#  Description: Test script to validate ruckus AP keywords#
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
*** Settings ***
Resource    ../common/resource.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown

*** Comments ***
Usage: 
robot -v MIKROTIK_IP:10.86.155.57 -v ap_mac:1C:B9:C4:37:6C:10 -v MAC_Mini_IP:10.86.155.55 ruckus_ap_test.robot

*** Variables ***


*** Test Cases ***
Run And Verify Factory Reset Of AP
    [Tags]    ap
    Factory Reset AP

List All SSIDs Broadcast On AP
    [Tags]    ssid
    #[Arguments]    ${AP_IP_Address}
    Check SSIDs being Broadcast on AP    ${AP_IP_Address}    ${MAC_Mini_IP}
    
*** Keywords ***
Suite Setup
    Close All SSH Connections
     
Suite Teardown
    Close All SSH Connections
    
    
