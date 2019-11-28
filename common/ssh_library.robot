#******************************************************************
#
#  File name: sshlibrary.robot
#
#  Description: SSH library keyword
#
#  Author:  CMOB SIT
#
#  Copyright (c) ViaSat, 2015
#
#******************************************************************
*** Settings ***
Documentation     Create SSH connections and execute commands through them

Library           SSHLibrary
Library           OperatingSystem
Library           Process

*** Keywords ***
Open SSH Connection And Login
    [Documentation]    SSHLibrary Connection with username and password with alise
    [Arguments]   ${host}  ${alias}  ${username}   ${password}
    SSHLibrary.Open Connection   ${host}    alias=${alias}  timeout=1 hour
    SSHLibrary.Login  ${username}   ${password}

Wait Until SSH Logs In
    [Arguments]   ${host}  ${alias}  ${username}   ${password}
    Wait Until Keyword Succeeds    240s    10s    Open SSH Connection And Login    ${host}  ${alias}  ${username}   ${password}

Execute SSH Command
    [Documentation]    executed command and return result
    [Arguments]   ${cmd}    ${timeout}=30 secs
    ${stdout}=  SSHLibrary.Execute Command  ${cmd}   timeout=${timeout}    return_stdout=True
    [return]   ${stdout}
    
Execute SSH Command And Return Rc
    [Documentation]    Verify executed command and success
    [Arguments]  ${cmd}
    ${rc}=  SSHLibrary.Execute Command   ${cmd}  timeout=30 secs    return_stdout=False  return_rc=True 
    Should be equal  ${rc}  ${0}  values=False  msg="${cmd}" messages not found /or command execution not Success
    [return]   ${rc}

Execute SSH Command And Return Stdout
    [Documentation]    executed command and return result
    [Arguments]   ${cmd}
    ${stdout}=  SSHLibrary.Execute Command  ${cmd}   timeout=30 secs    return_stdout=True
    [return]   ${stdout}

Switch Connection 
    [Documentation]    switches to a previously opened connection
    [Arguments]   ${alias}
    ${stdout}=  SSHLibrary.Switch Connection     ${alias}   
    [return]   ${stdout}

Close SSH Connection
    [Documentation]   Close SSH session
    SSHLibrary.Close Connection

Close All SSH Connections
    [Documentation]   Close all SSH session
    SSHLibrary.Close All Connections

