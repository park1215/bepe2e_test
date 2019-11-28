#******************************************************************
#
#  File name: ruckus_resource.robot
#
#  Description: Keywords for Ruckus APs
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
#******************************************************************
*** Settings ***
Documentation     Perform commands related to APs and retrieve status on user terminals

Resource         ../../../common/resource.robot

*** Keywords ***
Login To AP
    [Documentation]     Opens SSH connection to AP from mac mini.
    SSH To Mac Mini    ${MAC_Mini_IP}
    SSHLibrary.Write     ssh ${RUCKUS_LOGIN}@${AP_IP_Address}
    ${stdout}     SSHLibrary.Read	  delay=3s
    Should Contain    ${stdout}    Please login:
    SSHLibrary.Write     ${RUCKUS_LOGIN}
    ${stdout2}     SSHLibrary.Read	  delay=3s
    Should Contain    ${stdout2}    password :
    SSHLibrary.Write     ${RUCKUS_PASSWORD} 
    SSHLibrary.Read Until	rkscli:
 
Run Set Factory On AP
    [Documentation]     Runs command "Set factory"
    SSHLibrary.Write     ${SET_FACTORY}
    ${stdout}     SSHLibrary.Read	  delay=3s
    Should Contain    ${stdout}    Factory defaults will take effect after reboot
    
Run Reboot On AP
    [Documentation]     Runs command "Reboot" on AP.
    SSHLibrary.Write     reboot
    Set Client Configuration    prompt=$
    ${stdout}     SSHLibrary.Read	  delay=5s
    Should Contain    ${stdout}    OK
    Should Contain    ${stdout}    closed by remote host
    
Disconnect AP SSH
    [Documentation]     Closes AP's ssh connection.
    Close SSH Connection

Get and Set IP Address of Ruckus AP
    [Documentation]     Logins to Mikrotik and get and parse the IP address of given MAC
    ${output}    Get AP Detail From Mikrotik    ${ap_mac}
    Parse AP IP Address    ${output} 
    
Factory Reset AP
    [Documentation]      Resets ruckus AP to factory default settings
    Get and Set IP Address of Ruckus AP
    Login To AP
    Run Set Factory On AP
    Run Reboot On AP
    Verify AP Not Accessible
    Wait Until AP Is Back Online
    
Check SSIDs being Broadcast on AP
    [Documentation]      Login to AP, parse and return list of all SSIDs being broadcast by the AP
#    Get and Set IP Address of Ruckus AP
    [Arguments]    ${AP_IP_Address}    ${MAC_Mini_IP}
    Set Suite Variable    ${AP_IP_Address}
    Login To AP
    SSHLibrary.Write     ${GET_SSID}
    ${stdout}     SSHLibrary.Read         delay=3s
    Log To Console    ${stdout} 

Verify AP Not Accessible
    [Documentation]      Verifies AP goes down and ping is not successful
    ${stdout}    Execute SSH Command    ping -c5 ${AP_IP_Address}
    Should Contain    ${stdout}    100.0% packet loss
    
Wait Until AP Is Back Online
    [Documentation]      Wait Until AP Is Back Online
    Wait Until Keyword Succeeds    300s    3s    Verify Ping To AP Is Successful

Verify Ping To AP Is Successful
    [Documentation]      Verifies AP is reachable from Mac Mini
    ${stdout}    Execute SSH Command   ping -c5 ${AP_IP_Address}
    Should Not Contain   ${stdout}   bad address
    Should Not Contain  ${stdout}     100.0% packet loss

Parse AP IP Address
    [Documentation]      Parse the AP's IP address from stdout recevived from mikrotik
    [Arguments]    ${output} 
    Run    echo "${output}" > ap_detail.txt
    ${AP_IP_Address}    Run   cat ap_detail.txt | grep "active-address=" |awk '{print $1}'| cut -d= -f2
    Set Suite Variable    ${AP_IP_Address}
    Run    rm -rf ap_detail.txt
    
