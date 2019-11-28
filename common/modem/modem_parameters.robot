##############################################################
#
#  File name: modem_parameters.robot
#
#  Description: Parameters for modem-related Keywords
#  Copyright (c) ViaSat, 2018
#
##############################################################
*** Settings ***


*** Variables ***

${PORT_CONFIGURATION}                           -p
${SERVICE_FLOW_LISTS}                           -W
${MODEM_RETRY}                                  3 min
${MODEM_INTERVAL}                               5 sec
${CSP_RETRY}                                    2 min
${FRESH_REBOOT_STR}                             min,
${FRESH_REBOOT_CMD}                             uptime | awk '{print$4}'
${FRESH_REBOOT_LOGIN_RETRY}                     6 min
${FRESH_REBOOT_LOGIN_INTERVAL}                  15 sec
${CSP_INTERVAL}                                 5 sec
${CSP_STATE_TRUE}                               -C | grep connected | awk '{print $2}'
${UT_CSP_STATE_TRUE}                            TRUE
${MODEM_LED_ONLINE}                             -M | grep ledState | awk '{print $2}'
${MODEM_UMAC_ONLINE}                            -M | grep umacState | awk '{print $4}'
${MODEM_SW_VERSION}                             -M | grep swVersion | awk '{print $2}'
${MODEM_ONLINE_STATE}                           Online
                         
