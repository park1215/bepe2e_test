################################################################
#
#  File name: utstat_library.robot
#
#  Description: utstat keyword library
#
#  Author:  knayan/nmekala
#
#  History:
#
#  Date         Version   ModifiedBy  Description
#  -------------------------------------------------- -------
#  04/02/2016      0.1     knayan     Created file
#  22/02/2016      0.2     knayan     Added "Verify HotSpot Details For ICC And IAD" keyword
#  23/02/2016      0.2.1   knayan     Added "Wait For Verify CSP Status Is True On Modem" Keyword
#  25/02/2016      0.2.2   knayan     Added "Verify CPE Table is Enabled" keyword
#  17/03/2016      0.2.3   knayan     Added new keywords to get Sat ID, Sat Version,Beam,SMTS configs
#  01/08/2016      0.2.4   nmakala    Updated "Verify Device Type on Modem" keyword with MT Run command
#  05/09/2017      0.2.5   nmakala    Changed ${serviceId} variable name to ${serviceId_ht} in "Verify Device Type on Modem" keyword
#
#  Copyright (c) ViaSat, 2015
#
##############################################################
*** Settings ***
Documentation     MT library for reusable keywords and variables.
Resource          resource.robot
***Variable***
*** Keywords ***
Get Utstat Led State
    [Documentation]    Get Led State from utstat
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_LED_STATE}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Verify Led Status Is Online On Modem
    [Documentation]    Verify Led STATE is Online from utstat.
    ${stdout}    Get Utstat Led State
    Should Contain    ${stdout}    ${MT_LED_STATE_ONLINE}

Verify Led Status Is Not Online On Modem
    [Documentation]    Verify led state is Not Online from utstat.
    ${stdout}    Get Utstat Led State
    Should Not Contain    ${stdout}    ${MT_LED_STATE_ONLINE}

Verify umac State Is Online On Modem
    [Documentation]    Verify umac state is Online On utstat
    ${stdout}    Get Utstat umac State
    Should Contain    ${stdout}  ${MT_UMAC_STATE_ONLINE}

Get Utstat umac State
    [Documentation]    Get umac State from utstat.
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_UMAC_STATE}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Software Version
    [Documentation]    Get Utstat Software Version from utstat.
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_SW_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Hardware Version
    [Documentation]    Identify if M3 or Mt and then get Hardware Version from utstat.
    ${stdout}    Run Keyword If    ${M3_CONNECTED}
    ...    M3 Get Utstat Hardware Version
    ...  ELSE
    ...   MT Get Utstat Hardware Version
    [return]    ${stdout}

MT Get Utstat Hardware Version
    [Documentation]    Get Hardware Version from utstat for MT
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_HW_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Serial Number
    [Documentation]    Get Serial Number from utstat
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_SERIAL_NUM}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Odutype
    [Documentation]    Get Odutype from utstat.
    ${stdout}    MT Run Command    ${UTSTAT_O}    ${MT_ODU_TYPE}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat BDT Version
    [Documentation]    Get Utstat BDT Version
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_BDT_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Acu Firmware Version
    [Documentation]    Get Acu Firmware Version from utstat.
    ${stdout}    MT Run Command    ${UTSTAT_A}    ${MT_ACU_FIRMWARE_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Hardware Part Number
    [Documentation]    Get Hardware Part Number from utstat.
    ${stdout}    MT Run Command    ${UTSTAT_A}    ${MT_HARDWARE_PART_NUMBER}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat Hardware Serial Number
    [Documentation]    Get Utstat Hardware Serial Number
    ${stdout}    MT Run Command    ${UTSTAT_A}    ${MT_HARDWARE_SERIAL_NUMBER}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Utstat CSP State
    [Documentation]    Get CSP STATE from utstat.
    ${stdout}    MT Run Command    ${UTSTAT_C}    ${MT_CSP_STATE}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Verify CSP Status Is True On Modem
    [Documentation]    Get CSP STATE from utstat and verify csp is True
    ${stdout}    Get Utstat CSP State
    Should Contain    ${stdout}    ${MT_CSP_STATE_TRUE}

Verify CSP Status Is False On Modem
    [Documentation]    Get CSP STATE from utstat and verify csp is False
    ${stdout}    Get Utstat CSP State
    Should Contain    ${stdout}    ${MT_CSP_STATE_FALSE}

Wait For Verify CSP Status Is True On Modem
    [Documentation]    Wait For Verify CSP Status Is True On Modem
    Wait Until Keyword Succeeds    ${CSP_RETRY}    ${CSP_INTERVAL}    Verify CSP Status Is True On Modem

Wait For Verify CSP Status Is False On Modem
    [Documentation]    Wait For Verify CSP Status Is False On Modem
    Wait Until Keyword Succeeds    ${CSP_RETRY}    ${CSP_INTERVAL}    Verify CSP Status Is False On Modem

Get Utstat Device Hotspot Table Entry Using ${device_wan_address}
    [Documentation]    Get Device Hotspot Table Entry using utstat
    ${stdout}    MT Run Command    ${UTSTAT_Q}    | grep ${device_wan_address}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Verify Device Hotspot Table Entry Enabled Using ${device_wan_address}
    [Documentation]    Verify Device Hotspot Table Entry Enabled Using device wan addresss
    ${stdout}    Get Utstat Device Hotspot Table Entry Using ${device_wan_address}
    Should Contain    ${stdout}    ${MT_HOTSPOT_ENABLED}

Verify Device Hotspot Table Entry Disabled Using ${device_wan_address}
    [Documentation]    Verify Device Hotspot Table Entry disabled Using device wan addresss
    ${stdout}    Get Utstat Device Hotspot Table Entry Using ${device_wan_address}
    Should Contain    ${stdout}    ${MT_HOTSPOT_DISABLED}

Verify Device Hotspot Table Entry Enabled For ${DEVICE_TYPE} Using ${device_wan_address}
    [Documentation]    Verify Device Hotspot Table Entry Enabled For DEVICE_TYPE Using using utstat.
    ${stdout}    Get Utstat Device Hotspot Table Entry Using ${device_wan_address}
    Should Contain    ${stdout}    ${MT_HOTSPOT_ENABLED}
    Should Contain    ${stdout}    ${${DEVICE_TYPE}_NPI_CODE}

Verify Device Hotspot Table Entry Disabled For ${DEVICE_TYPE} Using ${device_wan_address}
    [Documentation]    Verify Device Hotspot Table Entry Disabled For DEVICE_TYPE Using using utstat
    ${stdout}    Get Utstat Device Hotspot Table Entry Using ${device_wan_address}
    Should Contain    ${stdout}    ${MT_HOTSPOT_DISABLED}
    Should Contain    ${stdout}    ${${DEVICE_TYPE}_NPI_CODE}

Verify HotSpot Details For ICC
    [Documentation]    verify hotspot details on mt for ICC using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_Q}    | grep -A10 -B0 Hotspot
    ${utstat_output}    MT Run Command    ${UTSTAT_Q}
    Log    ${utstat_output}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${HOTSPOT_ON_UTSTAT}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${NAS_IP_ON_UTSTAT}
    ${utstat_icc}    MT Run Command    ${UTSTAT_Q} | grep Ifcc
    Run Keyword And Continue On Failure    Should Match Regexp    ${utstat_icc}    ${CPE_FOR_ICC_UTSTAT}

Verify HotSpot Details For IAD
    [Documentation]    verify hotspot details on mt for IAD using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_Q}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${HOTSPOT_ON_UTSTAT}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${NAS_IP_ON_UTSTAT}
    ${NPI_CODE_IAD}  Get NPI Code For IAD From Build
    ${IAD_UTSTAT}    Set Variable    ${CPE_FOR_IAD_UTSTAT}${NPI_CODE_IAD},.*
    Run Keyword And Continue On Failure    Should Match Regexp    ${stdout}    ${IAD_UTSTAT}

Verify HotSpot Details For WIFE
    [Documentation]    verify hotspot details on mt for IFE using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_Q}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${HOTSPOT_ON_UTSTAT}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${NAS_IP_ON_UTSTAT}
    ${NPI_CODE_WIFE}  Get NPI Code For WIFE From Build
    ${WIFE_UTSTAT}    Set Variable    ${CPE_FOR_SLA_UTSTAT}${NPI_CODE_WIFE},.*
    Run Keyword And Continue On Failure    Should Match Regexp    ${stdout}    ${WIFE_UTSTAT}

Verify HotSpot Details For SLA
    [Documentation]    verify hotspot details on mt for IAD using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_Q}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${HOTSPOT_ON_UTSTAT}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${NAS_IP_ON_UTSTAT}
    ${NPI_CODE_SLA}  Get NPI Code For SLA From Build
    ${SLA_UTSTAT}    Set Variable    ${CPE_FOR_SLA_UTSTAT}${NPI_CODE_SLA},.*
    Run Keyword And Continue On Failure    Should Match Regexp    ${stdout}    ${SLA_UTSTAT}

Verify HotSpot Details For MPP
    [Documentation]    verify hotspot details on mt for MPP using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_Q}    | grep -A10 -B0 Hotspot
    ${utstat_output}    MT Run Command    ${UTSTAT_Q}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${HOTSPOT_ON_UTSTAT}
    Run Keyword And Continue On Failure    Should Contain    ${stdout}    ${NAS_IP_ON_UTSTAT}
    ${AIRLINE}     Get Airline From Config
    ${utstat_mpp}    Run Keyword If    "${AIRLINE}" == "${UAL}"
    ...    Verify HotSpot For Ual MPP
    ...  ELSE IF   '${AIRLINE}'=='${FIN}'
    ...   Verify HotSpot For Fin MPP
 
Verify HotSpot For Fin MPP
    [Documentation]    verify hotspot details on mt for MPP using utstat for fin
    ${utstat_mpp}    MT Run Command    ${UTSTAT_Q} | grep ${MPP_FIN_NPI_CODE}
    ${MPP_UTSTAT}    Set Variable    ${CPE_FOR_MPP_UTSTAT}${MPP_FIN_NPI_CODE},.*
    Run Keyword And Continue On Failure    Should Match Regexp    ${utstat_mpp}    ${CPE_FOR_MPP_UTSTAT}
    
Verify HotSpot For Ual MPP
    [Documentation]    verify hotspot details on mt for MPP using utstat for ual
    ${utstat_mpp}    MT Run Command    ${UTSTAT_Q} | grep ${MPP_UAL_NPI_CODE}
    ${MPP_UTSTAT}    Set Variable    ${CPE_FOR_MPP_UAL_UTSTAT}${MPP_UAL_NPI_CODE},.*
    Run Keyword And Continue On Failure    Should Match Regexp    ${utstat_mpp}    ${CPE_FOR_MPP_UAL_UTSTAT}
    
Wait For Verify HotSpot Details For MPP
   [Documentation]  Verifies HotSpot Details For MPP IS ENABLED with specified intervals for specified time
   Wait Until Keyword Succeeds  ${WAN_SEVICE_RETREVAL}  ${WAN_SERVICE_INREVAL}  Verify HotSpot Details For MPP

Wait For Verify HotSpot Details For SLA
   [Documentation]  Verifies HotSpot Details For SLA IS ENABLED with specified intervals for specified time
   Wait Until Keyword Succeeds  ${WAN_SEVICE_RETREVAL}  ${WAN_SERVICE_INREVAL}  Verify HotSpot Details For SLA

Wait For Verify HotSpot Details For ICC
   [Documentation]  Verifies HotSpot Details For ICC IS ENABLED with specified intervals for specified time
   Wait Until Keyword Succeeds  ${WAN_SEVICE_RETREVAL}  ${WAN_SERVICE_INREVAL}  Verify HotSpot Details For ICC

Wait For Verify HotSpot Details For IAD
   [Documentation]  Verifies HotSpot Details For IAD IS ENABLED with specified intervals for specified time
   Wait Until Keyword Succeeds  ${WAN_SEVICE_RETREVAL}  ${WAN_SERVICE_INREVAL}  Verify HotSpot Details For IAD

Verify CPE Table is Enabled Using ${WAN_ADDRESS} And ${NPI}
    [Documentation]    Verify CPE Table is Enabled Using Device Wan Address And npi code using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_Q}
    Should Contain    ${stdout}    ${MT_DEVICE_SERVICE_ID} ${NPI}
    Should Match Regexp    ${stdout}    ${CPE_TABLE}${WAN_ADDRESS}.*${MT_HOTSPOT_ENABLED}.*${NPI}

Get MT IP address From Utstat
    [Documentation]    Get MT IP address using utstat.
    ${stdout}    MT Run Command    ${UTSTAT_M}    ${MT_IP_ADDRESS}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get MT MAC Address From Utstat
    [Documentation]    Get MT MAC Address From Utstat
    ${stdout}    MT Run Command     ${UTSTAT_M}    ${MT_MAC}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get MT Atria Software Version From Utstat
    [Documentation]    Get MT Atria Software Version From Utstat.
    ${stdout}    MT Run Command    ${UTSTAT_ALL}    ${MT_ATRIA_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get ACU Hardware Part Number From Utstat
    [Documentation]    Get ACU Hardware Part Number From Utstat.
    ${stdout}    MT Run Command    ${UTSTAT_A}    ${MT_ACU_HARDWARE_PART_NUM}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get ACU Hardware Serial Number From Utstat
    [Documentation]    Get ACU Hardware Serial Number From Utstat.
    ${stdout}    MT Run Command    ${UTSTAT_A}    ${MT_ACU_SERIAL_NUMBER}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Sat Info Version From Utstat
    [Documentation]    Get Sat Info Version From sat info file.
    ${stdout}    MT Run Command    cat ${SAT_INFO}    ${MT_SAT_INFO_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get ACU ExpIpl Version From Utstat
    [Documentation]    Get ACU ExpIpl Version From Utstat.
    ${stdout}    MT Run Command    ${UTSTAT_A}    ${MT_EXPIPL_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get ACU ExpFirmWare Version From Utstat
    [Documentation]    Get ACU ExpFlirWare Version From Utstat
    ${stdout}     MT Run Command    ${UTSTAT_A}    ${MT_ACU_EXP_FIRMWARE_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Flight ID from Utstat
    [Documentation]    Get Flight Id Form utstat
    ${stdout}    Run Keyword If    ${M3_CONNECTED}
    ...    M3 Get Flight ID from Utstat
    ...  ELSE
    ...   MT Get Flight ID from Utstat
    [return]    ${stdout}

MT Get Flight ID from Utstat
    [Documentation]    Get Hardware Version from utstat for MT
    ${stdout}    MT Run Command    ${UTSTAT_Q}    ${UTSTAT_FLIGHT_ID}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Symbol Rate For ${BEAM}
    [Documentation]    Get Symbol Rate For specic beam id
    ${stdout}    MT Run Command    cat ${SAT_INFO}    | grep -A9 ${BEAM}| grep ymbol_ | awk '{print$3}'
    ${MT_BEAM_SYMBOL_RATE}  Strip String  ${stdout}
    [return]    ${MT_BEAM_SYMBOL_RATE}

Get Center Frequency For ${BEAM}
    [Documentation]    Get Center Frequency For specic beam id
    ${stdout}    MT Run Command    cat ${SAT_INFO}    | grep -A9 ${BEAM} | grep nter_F | awk '{print$3}'
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Sat Version
    [Documentation]    Get Sat Version from MT
    ${stdout}    MT Run Command    cat ${SAT_INFO}    ${MT_SAT_INFO_VERSION}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Sat Id
    [Documentation]    Get Sat Id from MT
    ${stdout}    MT Run Command    cat ${SAT_INFO}     ${MT_SAT_ID}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Get Beam Id Of MT
    [Documentation]    Get Beam Id from MT
    ${stdout}    MT Run Command    ${UTSTAT_L}    ${MT_BEAM_ID}
    ${stdout}    Parse The Data    ${stdout}
    [return]    ${stdout}

Verify MT On Beam ${BEAM}
    [Documentation]    Verify current MT Beam Id
    ${MT_SRC_BEAM}    Get Beam Id Of MT
    Should Contain    ${MT_SRC_BEAM}    ${BEAM}    msg="MT HANDOVER FAILED. MT IS NOT ON BEAM ${BEAM}"

Verify Handover In Progress For ${BEAM}
    [Documentation]    Verify Handover In Progress For specific beam
    Execute SSH Command And Return Rc    cat ${CAPTURE_IFCC_LOG} | grep "Event Received: Handover started" | grep "Beam ID: ${BEAM}" | grep "Handover in progress"

Verify Handover Completed For ${BEAM}
    [Documentation]    Verify Handover completion status for specific beam
    #Execute SSH Command And Return Rc    cat ${CAPTURE_IFCC_LOG} | grep "Event Received: Handover completed" | grep "Beam ID: ${BEAM}" | grep "Handover completed"
    ${stdout}    Execute SSH Command  cat ${CAPTURE_IFCC_LOG} | grep "Event Received: Handover completed"
    Log    ${stdout}
    Should Contain    ${stdout}    "Beam ID: ${BEAM}"

Get Default Beam Status
    [Documentation]    Return Default beam status
    ${MT_SRC_BEAM}    Get Beam Id Of MT
    ${DEFAULT_BEAM_STATUS}    Run Keyword And Return Status    Should Match Regexp    ${MT_SRC_BEAM}    ${FIRST_BEAM}
    [return]    ${DEFAULT_BEAM_STATUS}

Swap Beam Configurations
    [Documentation]    Swap beam configurations of test Variable
    ${TEMP_VAR}    Set Variable    ${FIRST_BEAM}
    Set Suite Variable    ${FIRST_BEAM}    ${SECOND_BEAM}
    Set Suite Variable    ${SECOND_BEAM}    ${TEMP_VAR}

Swap SMTS Configuration
    [Documentation]    Swap SMTS configurations of test Variable
    Set Suite Variable    ${SMTS_IP}    ${SWAMIS_SMTS_IP}
    Set Suite Variable    ${FIRST_BEAM}    ${SWAMIS_FIRST_BEAM}
    Set Suite Variable    ${SECOND_BEAM}    ${SWAMIS_SECOND_BEAM}

Verify And Swap SMTS Configuration
    [Documentation]    Verify and Swap SMTS configurations of test Variable
    ${MT_SRC_BEAM}    Get Beam Id Of MT
    ${PASSED}    Run Keyword And Return Status    Should Match Regexp    ${MT_SRC_BEAM}    (${FIRST_BEAM}|${SECOND_BEAM})
    Run Keyword If    ${PASSED}==False    Swap SMTS Configuration

Verify Device Type on Modem
    [Documentation]    Verify device serice type on modem
    [Arguments]    ${serviceId_ht}    ${rate}    ${priority}    ${weight}
    ${stdout}    MT Run Command    ${UTSTAT_Q}
    ${len}    Get Length    ${serviceId_ht}
    ${serviceId_ht}   Run Keyword If  ${len}<=${SERVICE_ID_LENGTH}      Set Variable    ${serviceId_ht}  ELSE    Get Substring    ${serviceId_ht}   0   ${SERVICE_ID_LENGTH}
    Should Contain    ${stdout}    ${MT_DEVICE_SERVICE_ID} ${serviceId_ht}
    Should Contain    ${stdout}    ${MT_DEVICE_RATE_LIMIT} ${rate}  ${MT_DEVICE_WEIGHT} ${weight}  ${MT_DEVICE_PRIORITY} ${priority}

Verify Rlcatalog Profiles Provisioned On Modem
    [Documentation]    Verify Rlcatalog Profiles Provisioned On Modem
    ${stdout}    Execute SSH Command    cat ${RL_CATALOG}
    ${stdout}    convert_json_to_dictiory    ${stdout}
    ${rlCatalog}    Get From Dictionary    ${stdout}    ${RLCATALOG_RLCATALOG}
    :FOR    ${ELEMENT}    IN    @{rlCatalog}
    \    ${serviceId_ht}    Get From Dictionary    ${ELEMENT}    ${RLCATALOG_DEVICE_SERVICE_ID}
    \    ${rate}    Get From Dictionary    ${ELEMENT}    ${RLCATALOG_DEVICE_RATE}
    \    ${priority}    Get From Dictionary    ${ELEMENT}    ${RLCATALOG_DEVICE_PRIORITY}
    \    ${weight}    Get From Dictionary    ${ELEMENT}    ${RLCATALOG_DEVICE_WEIGHT}
    \    Run Keyword And Continue On Failure    Verify Device Type on Modem    ${serviceId_ht}    ${rate}    ${priority}    ${weight}

Verify Flight ID From utstat
   [Documentation]    Verify Flight ID from utstat -Q with given input flight id
   [Arguments]    ${NAU_FLIGHT_ID}
   ${NEW_FLIGHT_ID}    Get Flight ID from Utstat
   Should Be Equal As Strings    ${NAU_FLIGHT_ID}     ${NEW_FLIGHT_ID}

Wait For Verify Flight ID From utstat
    [Documentation]  Waits to Verify Flight ID From utstat and naustat becomes same
    [Arguments]    ${NAU_FLIGHT_ID}
    Wait Until Keyword Succeeds    ${FLIGHT_ID_RETREVAL}    ${FLIGHT_ID_INTERVEL}    Verify Flight ID From utstat    ${NAU_FLIGHT_ID}

Verify Number Of Entries For Service Id In Modem
    [Documentation]    Returns the number of occurences of a service id from output of utstat -Q
    [Arguments]    ${SERVICE_ID}
    ${output}    MT Run Command    ${UTSTAT_Q} | grep ${MT_DEVICE_SERVICE_ID} | grep ${SERVICE_ID} | wc -l
    @{stdout}    Split To Lines    ${output}
    [return]    @{stdout}[-2]

Parse The Data
    [Documentation]    Parses the data received by running utstat command
    [Arguments]    ${data}
    ${stdout}    Split String    ${data}    [
    ${stdout}   Get From List    ${stdout}   0
    ${parsed_data}  Strip String  ${stdout}
    [return]    ${parsed_data}
