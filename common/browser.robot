#******************************************************************
#
#  File name: browser.robot
#
#  Description: Keywords for browser
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
#******************************************************************
*** Settings ***
Documentation     Perform commands and retrieve status on user terminals

Resource         resource.robot

*** Keywords ***
Set Up Browser Parameters
    [Documentation]     Sets up browser parameters to start browser with google-chrome --headless --disable-gpu
    ${chrome_options} =     Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${chrome_options}   add_argument    headless
    Call Method    ${chrome_options}   add_argument    disable-gpu
    Call Method    ${chrome_options}   add_argument    no-sandbox
    #Call Method    ${chrome_options}   add_argument    remote-debugging-port=9222
    ${desired_capabilities}=     Call Method     ${chrome_options}    to_capabilities
    Set Suite Variable    ${desired_capabilities}
    
Get Screenshot Name
    [Documentation]   Get Unique Screenshot Name
    ${date}    Get Current Date    UTC    
    ${epoch_timestamp}    Convert Date	${date}    epoch
    ${random_name}=    Convert To String    ${epoch_timestamp}
    ${screenshot_name} =   Catenate    SEPARATOR=  screenshot_   ${random_name}.png
    Log To Console    ${screenshot_name}
    [Return]    ${screenshot_name}

