################################################################
#
#  File name: modem.robot
#
#  Description: Demonstrates use of modem-related keywords
#
#  Author:  swile
#
#  Copyright (c) ViaSat, 2018
#
##############################################################
*** Settings ***
Resource    ../../common/modem/modem_resources.robot
Resource    ../../common/ssh_library.robot

*** Variables ***
${IP}            	10.240.109.14


*** Test Cases ***
Use Utstat
    # Use ip address as alias in case you want to reconnect
    Open SSH Connection And Login     ${ip}   ${ip}  ${MODEM_USERNAME}   ${MODEM_PASSWORD}
    ${status}   Verify Port Configuration   Router
    Log To Console   ${status}

    

