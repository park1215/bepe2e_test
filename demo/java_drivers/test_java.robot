*** Settings ***
Library    Remote     http://localhost:8270/

*** Test Cases ***
Call Remote Keyword
    ${RESPONSE1}   Open Portal
    Log To Console   response=${RESPONSE1}
    ${RESPONSE2}   Stop Remote Server   
    Log To Console   response=${RESPONSE2}
    
