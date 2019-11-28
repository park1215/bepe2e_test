#################################################################
#
#  File name:  wifi_resources.robot
#
#  Description: MAC Connectivity Library to connect and run selenium test cases on Mac
#
#  Author: pgadekar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
# In most keywords, assume caller has already made SSH connection
*** Settings ***
Resource                  ../resource.robot
Resource                  wifi_parameters.robot
Library                   ../../python_libs/wifi.py

*** Keywords ***
SSH To Mac Mini
    [Arguments]  ${MAC_Mini_IP}
    [Documentation]    Keyword to test ssh connection - can probably delete
    Open SSH Connection And Login     ${MAC_Mini_IP}   ${MAC_Mini_IP}  ${MAC_USERNAME}   ${MAC_PASSWORD}

Turn On Wifi On Mac
    #[Arguments]  ${HOST}=${MAC_Mini_IP}   
    #SSH To Mac Mini    ${MAC_Mini_IP} 
    SSHLibrary.Write  echo ${MAC_PASSWORD} | sudo -S networksetup -setairportpower en1 on
    ${stdout}=   SSHLibrary.Read Until  $
    Log To Console      ----${stdout}----
    
Connect To SSID
    [Arguments]    ${SSID}
    Execute SSH Command  networksetup -setairportnetwork en1 ${SSID}
    ${connected_ssid}    Get Connected SSID
    Should Be Equal    ${connected_ssid}    ${SSID}

Check If SSID seen on MAC
    [Arguments]    ${SSID}
    ${stdout}=    Execute SSH Command  /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | grep -i ${SSID}
    Should Not Be Empty    ${stdout}    msg=SSID Lookup Failed or returned no Entries
    [return]    ${stdout}

Get Connected SSID
    ${connected_ssid}    Execute SSH Command  /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print substr($0, index($0, $2))}'
    [return]  ${connected_ssid}

Disconnect Mac Mini
    SSHLibrary.Close Connection
    
Verify Selenium Jar Is Running
    ${stdout}    Execute SSH Command   lsof -nP +c 15 | grep LISTEN
    Should Contain   ${stdout}    ${SELENIUM_JAR_PORT}

Open Browser And Verify
    [Arguments]  ${URL}    ${TEXT}
    Verify Selenium Jar Is Running
    Open Browser   ${URL}   browser=chrome  remote_url=http://${MAC_MINI_IP}:${SELENIUM_JAR_PORT}/wd/hub
   # Open Browser   ${URL}   browser=chrome  remote_url=http://127.0.0.1:4444/wd/hub
    #Open browser  about:  chrome
    #Go to  ${URL}
    Page should contain  ${TEXT}
    ${screenshot_name}=    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    
Verify And Start Selenium Jar
    [Documentation]     start up the selenium server
    Log To Console    first
    ${server_running}    Run Keyword And Return Status    Verify Selenium Jar Is Running
    Run Keyword Unless    ${server_running}    Wait Until Keyword Succeeds    60s    5s    Start Selenium Jar On MacMini

Start Selenium Jar On MacMini
    Execute SSH command    java -jar selenium-server-standalone-3.141.59.jar &
    Verify Selenium Jar Is Running
    #Following sleep is needed because browser can not be opened immediately after starting the selenium server
    sleep     20s

Create Order
    [Arguments]   ${service_instance_id}   ${bep_order_id}   ${cure_configuration_name}   ${bom}   ${customer_id}   ${licensee_details}   ${location_details}
    &{config}=   Create Dictionary   service_instance_id=${service_instance_id}  bep_order_id=${bep_order_id}   cure_configuration_name=${cure_configuration_name}   bom=${bom}   customer_id=${customer_id}
    ...       licensee_details=${licensee_details}   location_details=${location_details}
    &{noconfig}=   Create Dictionary   robot=True
    ${result}    createWifiOrder   ${config}
    [Return]  ${result}
    
######################################## Following Keywords are directly imported from SAT and not tested ####################
Turn On Wifi On Mac Old
    [Arguments]  ${HOST}=${MAC_Mini_IP}   ${UNAME}=${MAC_55_USERNAME}   ${PWD}=${MAC_55__PASSWORD}
    Open SSH Connection And Login     ${HOST}   ${HOST}   ${UNAME}   ${PWD}
    SSHLibrary.Write  echo ${PWD} | sudo -S networksetup -setairportpower en1 on
    ${stdout}=   SSHLibrary.Read Until  $
    Log To Console      ----${stdout}----
    SSHLibrary.Close Connection

Turn Off Wifi On Mac
    [Arguments]  ${HOST}=${MAC_55_IP}   ${UNAME}=${MAC_55_USERNAME}   ${PWD}=${MAC_55__PASSWORD}
    SSHLibrary.Open Connection   ${HOST}  timeout=1 min
    SSHLibrary.Login  ${UNAME}   ${PWD}
    SSHLibrary.Write  echo ${PWD} | sudo -S networksetup -setairportpower en1 off
    ${stdout}=   SSHLibrary.Read Until  $
    Log To Console      ----${stdout}----
    SSHLibrary.Close Connection
    
Connect To SSID Old
    [Arguments]    ${SSID}
    SSHLibrary.Write  networksetup -setairportnetwork en1 ${SSID}    
    
List SSIDs
    SSHLibrary.Write   /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s
    ${stdout}=   SSHLibrary.Read Until  $
    [return]    ${stdout}
    
Start Selenium Server On Macmini old
    [Arguments]     ${ALIAS}=${MAC_55_IP}   ${PATH}=.   ${SELENIUM_JAR}=${SEL_JAR}
    SSHLibrary.Switch Connection  ${ALIAS}
    SSHLibrary.Write   cd ${PATH}
    SSHLibrary.File Should Exist   ${PATH}/${SELENIUM_JAR}
    SSHLibrary.Write   nohup java -jar ${SELENIUM_JAR} &    
 
Stop Selenium Server On Remote Device
    [Arguments]     ${ALIAS}=${MAC_55_IP}
    SSHLibrary.Switch Connection  ${ALIAS}
    SSHLibrary.Write   pkill -f selenium-server-standalone 
    
Open Remote Chrome On Macmini
    [Arguments]  ${url}
    Open Browser   ${url}   Chrome  remote_url=http://${MAC_IP}:4444/wd/hub   
    ${screenshot_name}=    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    Close Browser
