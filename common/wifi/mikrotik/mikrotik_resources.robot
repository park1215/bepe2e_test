#################################################################
#
#  File name:  mikrotik_resources.robot
#
#  Description: Mikrotik Library to perform various operations related to reset/rollback/verification of mikrotik controllers
#
#  Author: adingankar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
# In most keywords, assume caller has already made SSH connection
*** Settings ***
Resource                  ../../resource.robot
Resource                  mikrotik_parameters.robot

*** Keywords ***
SSH To Reset Mikrotik
    [Documentation]   Keyword to ssh into a factory reset Mikrotik
    [Arguments]    ${MIKROTIK_IP}
    Wait Until SSH Logs In    ${MIKROTIK_IP}  ${MIKROTIK_IP}  ${MIKROTIK_RESET_LOGIN}  ""

SSH To Mikrotik
    [Documentation]   Keyword to ssh into a provisioned Mikrotik
    [Arguments]    ${MIKROTIK_IP}
    Wait Until SSH Logs In    ${MIKROTIK_IP}  ${MIKROTIK_IP}  ${MIKROTIK_PHONEHOME_LOGIN}  ${MIKROTIK_PHONEHOME_PASSWORD}

SSH to AP via Mikrotik & Issue Command
    [Documentation]    Keyword to run Linux Commands to Login to AP via Mikrotik & Issue Command
    #${SSH_output}    Run   ssh -J VWSAdmin@10.86.155.57 VWSAdmin@10.62.190.134 
    ${output}    Run  ssh VWSAdmin@10.86.155.55
    Should Contain    ${output}    Password:  
    #Log To Console    ${output.stdout}
    #${test}    Set Variable    VWSAdmin@10.86.155.57's password:
    #Should Contain    ${test}    password: 
#    ${rc}  ${output}=  Run And Return Rc And Output    ${MIKROTIK_CURE_PASSWORD}
#    Log To Console    ${output}
#    Should Contain    ${output}    Please login:
#    ${rc}  ${output}=  Run And Return Rc And Output    ${MIKROTIK_CURE_LOGIN}
#    Log To Console    ${output}
#    Should Contain    ${output}    password :
#    ${rc}  ${output}=  Run And Return Rc And Output    aorwH0BtH8Sp
#    Should Contain    ${output}    rkscli:
#    Log To Console    ${output}
#    ${rc}  ${output}=  Run And Return Rc And Output    quit
#    Should Contain    ${output}    Killed by signal 1.         
#    Log To Console    ${output}
    
CURE SSH To Mikrotik
    [Documentation]   Keyword to ssh into a Mikrotik after configured via cure
    [Arguments]    ${MIKROTIK_IP}
    Wait Until SSH Logs In    ${MIKROTIK_IP}  ${MIKROTIK_IP}  ${MIKROTIK_CURE_LOGIN}  ${MIKROTIK_CURE_PASSWORD}
    
Disconnect Mikrotik SSH
    [Documentation]   Keyword to ssh into a factory reset Mikrotik
    Close SSH Connection

Clear Entry In Known Hosts
    [Documentation]   Keyword to clear the prior SHA-signature entry from Known Hosts file
    [Arguments]    ${MIKROTIK_IP}
    Run    awk '!/${MIKROTIK_IP}/' ~/.ssh/known_hosts > ~/.ssh/temp && mv ~/.ssh/temp ~/.ssh/known_hosts

Prepare Mikrotik For Reset
    [Documentation]   Keyword to delete files and prep MikroTik For Reset
#    Execute SSH Command   file remove log.html
#    Execute SSH Command   file remove log_noAB_plans.html
    Execute SSH Command   file remove flash/hotspot
    Execute SSH Command   file remove flash/CURRENT_CONFIG_VERSION.rsc

Reset Mikrotik Controller
    [Documentation]   Keyword to reset Mikrotik to factory config + custom script that adds back lab networking
    [Arguments]    ${MIKROTIK_NAME}
    ${output}    Execute SSH Command   system reset-configuration skip-backup=yes no-defaults=yes run-after-reset=flash/set_mgmt_interface_${MIKROTIK_NAME}.rsc
    Log To Console    ${output}
    Log To Console    Controller Full Reset & Rebooting

Run Import Script on Mikrotik
    [Documentation]   Keyword to import phone home script on Mikrotik IP
    [Arguments]    ${MIKROTIK_NAME}
    ${stdout}    Execute SSH Command   import MikroTik_Licensee-Agnostic_Phone-Home-Beta-Config_v2-1-3_bepe2e_mod.rsc
    Log To Console    ${stdout}
    Set Client Configuration    prompt=>
    SSHLibrary.Read Until Prompt
    Log To Console    ${stdout}
#    Should Contain    ${stdout}    could not get answer from dns server
    Should Contain    ${stdout}    SETTING NEIGHBOR DISCOVERY HAS BEEN COMPLETED.

SCP Files Onto MikroTik
    [Documentation]   Keyword to import phone home script on Mikrotik IP
    [Arguments]    ${MIKROTIK_NAME}    ${MIKROTIK_IP}
    Run    scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null common/wifi/mikrotik/MikroTik_Licensee-Agnostic_Phone-Home-Beta-Config_v2-1-3_bepe2e_mod.rsc common/wifi/mikrotik/certs/prod/* ${MIKROTIK_RESET_LOGIN}@${MIKROTIK_IP}:/

Validate Base Provisioning
    [Documentation]   Keyword to ensure VWSAdmin user got added to Mikrotik
    ${stdout}    Execute SSH Command   user print
    Should Contain    ${stdout}    VWSAdmin

Validate Tunnel On Mikrotik
    [Documentation]   Keyword to ensure the tunnel is active on VPN interface
    ${stdout}    Execute SSH Command    ip addr print
    Log To Console    ${stdout}
    Should Contain    ${stdout}    ${TUNNEL_GATEWAY}
    ${stdout}    Execute SSH Command    ping ${TUNNEL_GATEWAY} count=5
    Log To Console    ${stdout}
    Should Not Contain    ${stdout}    timeout

SCP HotSpot Files Onto Mikrotik
    [Documentation]   Keyword to copy over hotspot login pages
    [Arguments]    ${MIKROTIK_NAME}    ${MIKROTIK_IP}
    ${rc}   ${output}    Run And Return Rc And Output    ls -tal common/wifi/mikrotik/wapLogin/*
    Log To Console    ${rc}    ${output}
    ${rc}    ${output}    Run And Return Rc And Output    sshpass -p ${MIKROTIK_PHONEHOME_PASSWORD} scp common/wifi/mikrotik/wapLogin/*.html ${MIKROTIK_PHONEHOME_LOGIN}@${MIKROTIK_IP}:flash/hotspot/
    Log To Console    ${rc}    ${output}

Revert Mikrotik Controller To GBS Settings
    [Documentation]   Consolidated Keyword To Reset any Mikrotik Controller
    [Arguments]    ${MIKROTIK_NAME}    ${MIKROTIK_IP}
    SSH To Mikrotik    ${MIKROTIK_IP}
    Log To Console    Delete files under flash
    Prepare Mikrotik For Reset
    Reset Mikrotik Controller    ${MIKROTIK_NAME}
    Log To Console    Finished Resetting
    Disconnect Mikrotik SSH
    Clear Entry In Known Hosts  ${MIKROTIK_IP}
    Log To Console    Finished Clearing KNOWN_HOSTS
    SSH To Reset Mikrotik    ${MIKROTIK_IP}
    Log To Console    Copy Phone Home Script Onto Miktrotik
    SCP Files Onto MikroTik    ${MIKROTIK_NAME}    ${MIKROTIK_IP}
    Run Import Script on Mikrotik    ${MIKROTIK_NAME}
    Log To Console    Finished Importing Phone Home Script
    Validate Base Provisioning
    Log To Console    Validated VWSAdmin User
    Disconnect Mikrotik SSH
   
Get AP Detail From Mikrotik
    [Documentation]   Returns the IP address of a given AP's MAC Address
    [Arguments]    ${ap_mac}
    CURE SSH To Mikrotik    ${MIKROTIK_IP}
    ${stdout}    Execute SSH Command    ip dhcp-server lease print detail where mac-address=${ap_mac}
    Disconnect Mikrotik SSH
    [return]   ${stdout} 
