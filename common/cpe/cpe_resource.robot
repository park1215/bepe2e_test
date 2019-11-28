#******************************************************************
#
#  File name: cpe_resource.robot
#
#  Description: Keywords for CPEs
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
#******************************************************************
*** Settings ***
Documentation     Perform commands and retrieve status on user terminals

Resource         ../../common/resource.robot

*** Keywords ***
Connect To CPE
    [Documentation]     Opens SSH connection to CPE.
    [Arguments]         ${cpe_ip}    ${modem_type}
    Log    modem type input is ${modem_type}    WARN
    Run Keyword If    '${modem_type}' == 'AB'    Run Keywords
    ...    Set Suite Variable    ${cpe_usrname}    ${CPE_USERNAME}   AND
    ...    Set Suite Variable    ${cpe_pswrd}      ${CPE_PASSWORD}
    ...  ELSE IF    '${modem_type}' == 'SB2'    Run Keywords
    ...    Set Suite Variable    ${cpe_usrname}    ${SB_CPE_USERNAME}   AND
    ...    Set Suite Variable    ${cpe_pswrd}      ${SB_CPE_PASSWORD}
    ...  ELSE
    ...     Log     modem type is not valid     WARN
    Open SSH Connection And Login    ${cpe_ip}  "cpe"  ${cpe_usrname}   ${cpe_pswrd}
    Set Client Configuration	prompt=$
    
Disconnect Cpe SSH
    [Documentation]     Closes CPE's ssh connection.
    Close SSH Connection

Verify Cpe State
    [Documentation]     Checks dhclient and default route on cpe.
    [Arguments]         ${cpe_ip_add}=${cpe_ip}
    Connect To CPE    ${cpe_ip_add}    ${modem_type}
    Verify Dhclient Running On Cpe
    Verify Default Route Interface On Cpe
    Disconnect Cpe SSH
 
Verify Internet Is Not Accessible From CPE
    [Documentation]     Checks dhclient and default route on cpe.
    Cpe Browser Setup
    #${stdout}    Execute SSH Command    ping -c3 8.8.8.8
    #Run Keyword And Continue On Failure    Should Not Be Empty    ${stdout}
    #Run Keyword And Continue On Failure    Should Contain    ${stdout}    100% packet loss
    Open Browser    ${TEST_URL}    browser=chrome    remote_url=http://${cpe_ip}:4444/wd/hub     desired_capabilities=${desired_capabilities}
    Page Should Not Contain    ${WIKIPEDIA_TEXT}
    ${screenshot_name}=    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    Browser Teardown
    
Verify Dhclient Running On Cpe
    [Documentation]     Verifies that dhclient is running on the modem.
    ${stdout}    Execute SSH Command    ps -ef | grep dhclient | grep -v grep
    Should Not Be Empty    ${stdout}
    Should Contain    ${stdout}    eth1

Verify Default Route Interface On Cpe
    [Documentation]     Verifies the default route on modem
    #Run Keyword If    '${modem_type}' == 'AB'    Set Suite Variable    ${grep_string}    f42   
    #...  ELSE IF    '${modem_type}' == 'SB2'   Set Suite Variable    ${grep_string}    f41  
    #...  ELSE
    #...     Log     modem type is not valid     WARN
    #${default_route_int}    Execute SSH Command    netstat -nr | grep -m1 0.0.0.0| cut -d ' ' -${grep_string}
    ${default_route_int}    Execute SSH Command    netstat -nr | grep -m1 0.0.0.0
    Should Contain    ${default_route_int}    eth1
 
Start Selenium Jar
    [Documentation]     start up the selenium server
    Start Command    java -jar selenium-server-standalone-3.141.59.jar &
    Verify Selenium Jar Is Running On Cpe
    #Following sleep is needed because browser can not be opened immediately after starting the selenium server
    sleep     20s
    
Verify Selenium Jar Is Running On Cpe
    [Documentation]     Verifies that selemium java jar is running
    #${stdout}    Execute SSH Command    netstat -plnt | grep 4444
    #Should Contain    ${stdout}    LISTEN
    ${stdout}    Execute SSH Command    ps aux | grep java
    Should Contain    ${stdout}    selenium-server-standalone
     
Verify Internet Is Accessible From CPE
    [Documentation]     Checks dhclient and default route on cpe.
    Cpe Browser Setup
    #${stdout}    Execute SSH Command    ping -c3 8.8.8.8
    #Should Not Be Empty    ${stdout}
    #Should Not Contain    ${stdout}    100% packet loss
    Log To Console    parameters are set
    Open Browser And Verify On CPE    ${TEST_URL}    ${WIKIPEDIA_TEXT} 
    Browser Teardown
    
Open Browser And Verify On CPE
    [Documentation]     Open browser to given url and verifies browser is opened. Captures the screenshot too.
    [Arguments]         ${url}   ${text}
    Open Browser    ${url}    browser=chrome    remote_url=http://${cpe_ip}:4444/wd/hub     desired_capabilities=${desired_capabilities}
    Wait Until Page Contains    ${text}
    ${screenshot_name}=    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}

Verify And Start Selenium Jar Is Running On Cpe
    [Documentation]     Verifies that selemium java jar is running, if not, starts the server
    ${server_running}    Run Keyword And Return Status    Verify Selenium Jar Is Running On Cpe
    Run Keyword Unless    ${server_running}    Wait Until Keyword Succeeds    60s    5s    Start Selenium Jar

Browser Teardown
    [Documentation]     Teardown for browser tests
    Execute SSH command    pkill chrome
    Disconnect Cpe SSH

Cpe Browser Setup
    [Documentation]     Setup for browser tests
    Connect To CPE    ${cpe_ip}    ${modem_type}
    Verify And Start Selenium Jar Is Running On Cpe
    Set Up Browser Parameters
