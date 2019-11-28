#******************************************************************
#
#  File name: fsm_resource.robot
#
#  Description: Keywords for FSM
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
Login To FSM Gui
    [Documentation]     Login to FSM, opens FSM browser Gui and leaves page open.
    Set Up Browser Parameters
    Open Browser    ${FSM_URL}    browser=chrome    desired_capabilities=${desired_capabilities}
    Page Should Contain Element   ${FSM_HOME_ELEMENT}
    Enter FSM Credentials    
    
Search Entry By Ntd Id
    [Documentation]     Retrives data for given NTD id
    [Arguments]    ${ntd_id}
    Input Text    ${SEARCH_INPUT_ELEMENT}    ${ntd_id}
    Click Element    ${SERACH_ELEMENT}
    
Verify Order Status Is Systemic
    [Documentation]     Verifies the work order status shows Pending Complete Systemic, assumes ntd_id is set as suite variable
    Search Entry By Ntd Id    ${ntd_id}
    Wait Until Page Contains Element    ${DATA_FORM_ELEMENT} 
    ${status}    Get Text    ${STATUS_ELEMENT}
    Should Contain    ${status}    ${PENDING_COMPLETE_SYSTEMIC}

Drop Down To Complete Status
    [Documentation]     Selects drop down menu to set order status to complete 
    Mouse over    ${STATUS_ELEMENT}
    Page Should Contain Element    ${DROPDOWN_ELEMENT}      5s
    Click Element    ${DROPDOWN_ELEMENT}
    Mouse Down    ${SELECT_COMPLETED_ELEMENT}
    ${screenshot_name}    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    Click Element    ${SELECT_COMPLETED_ELEMENT}
    Click Element    ${CHANGE_STATUS_ELEMENT}

Add Note
    [Documentation]     Need to add a note before changing a work order to complete
    ${elem}  	Get WebElement	//*[starts-with(@name, 'noteForm:j_idt')]
    ${note_id}=	Get Element Attribute	${elem}  	id
    Input Text     id=${note_id}    "Change to complete (automation)"    
    Click Element    ${ADD_NOTE_ELEMENT}
    ${screenshot_name}    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
   
Change Status To Completed
    [Documentation]     Verifies that status is not completed and changes status to completed
    Search Entry By Ntd Id    ${ntd_id}
    Wait Until Page Contains Element    ${DATA_FORM_ELEMENT} 
    ${current_status}    Get Text    ${STATUS_ELEMENT}
    Should Not Contain    ${current_status}    ${COMPLETED} 
    ${screenshot_name}    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    Add Note
    Drop Down To Complete Status
    Wait Until Page Contains    ${SUCCESSFUL_MESSAGE}    35s
    Set Focus To Element    ${MESSAGE_ELEMENT}
    ${screenshot_name}    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    Wait For Status Change
    
Wait For Status Change
    [Documentation]     Verifies that state changes to complete (it takes a while to display the changed state)
    ${changed_status}    Get Text    ${STATUS_ELEMENT}
    Should Contain    ${changed_status}    ${COMPLETED} 
    
Enter FSM Credentials
    [Documentation]     Enters the login credentials
    Input Text          ${FSM_USERNAME_ELEMENT}    ${FSM_USERNAME}	
    Input Text          ${FSM_PASSWORD_ELEMENT}    ${FSM_PASSWORD}
    ${screenshot_name}    Get Screenshot Name  
    Capture Page Screenshot         ${screenshot_name}
    Click Element       ${LOGIN_ELEMENT}
    Page Should Contain Element    ${SEARCH_INPUT_ELEMENT}
    
Verify Selenium Jar Is Running On Bep
    [Documentation]     Verifies that selemium java jar is running
    ${stdout}    Run    ps aux | grep java
    Should Contain    ${stdout}    selenium-server-standalone
    
Start Selenium Jar On Bep
    [Documentation]     start up the selenium server
    Start Process    java    -jar    ${CURDIR}/selenium-server-standalone-3.141.59.jar    alias=selenium
    Verify Selenium Jar Is Running On Bep
    #Following sleep is needed because browser can not be opened immediately after starting the selenium server
    sleep     20s
    
Verify And Start Selenium Jar On Bep
    [Documentation]     Verifies that selemium java jar is running, if not, starts the server
    ${server_running}    Run Keyword And Return Status    Verify Selenium Jar Is Running On Bep
    Run Keyword Unless    ${server_running}    Wait Until Keyword Succeeds    60s    5s    Start Selenium Jar On Bep

Fetch Order Information From FSM
    [Documentation]   For a given ntdId, retrieve information from FSM such as orderStatus, externalOrderId, list of services & list of equipment
    ${result_list}    Fetch FSM Information    ${ntd_id}
    Log To Console  ${result_list}[0]   ${result_list}[1]
    Should Be True    ${result_list}[0]
    [return]   ${result_list}
