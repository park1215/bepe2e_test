*** Settings ***
Library           Selenium2Library

*** Keywords ***
SSH To Mac Mini
    [Documentation]    Keyword to test ssh connection - can probably delete
    Open SSH Connection And Login     ${MAC_55_IP}   ${MAC_55_IP}  ${MAC_55_USERNAME}   ${MAC_55_PASSWORD}

Turn On Wifi On Mac
    [Arguments]  ${HOST}=${MAC_55_IP}}   ${UNAME}=${MAC_55_USERNAME}   ${PWD}=${MAC_55__PASSWORD}
    Open SSH Connection And Login     ${HOST}   ${HOST}   ${UNAME}   ${PWD}
    SSHLibrary.Write  echo ${PWD} | sudo -S networksetup -setairportpower en1 on
    ${stdout}=   SSHLibrary.Read Until  $
    Log To Console      ----${stdout}----
    SSHLibrary.Close Connection
