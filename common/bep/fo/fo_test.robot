*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime

Resource    fo_resource.robot

Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
${ADDRESS_LINE}     349 Inverness Drive South
${COUNTRY_NAME}     United States
${COUNTRY_CODE}     USA
${CITY}             ENGLEWOOD
${STATE}            CO
${ZIP}              80112
${LATITUDE}         39.55
${LONGITUDE}        -104.86
${PRODUCT_TYPE_ID}  cee9s0be-6557-3b44-8bfd-534a9692ad6
${PRODUCT_TYPE_ID2}  cef9s0be-6557-3b44-8bfd-534a9692ad7
${SELLER_PARTY_ID}  fe34ee49-6198-44b0-a96a-baa39bf59175
${INSTALL_INTERVAL}   7 days
 
*** Test Cases ***
Get FO Install Dates
    @{address_lines}   Create List   ${ADDRESS_LINE}
    &{iso_country_code}    Create Dictionary   name=${COUNTRY_NAME}  alphabeticThreeCharacterCode=${COUNTRY_CODE}
    &{address}   Create Dictionary   addressLine=${address_lines}   city=${CITY}   regionOrState=${STATE}   isoCountryCode=${iso_country_code}   zipOrPostCode=${ZIP}
    &{geoLocationInput}   Create Dictionary   latitude=${LATITUDE}  longitude=${LONGITUDE}   significantDigits=5
    @{product_type_ids}   Create List    ${PRODUCT_TYPE_ID}  ${PRODUCT_TYPE_ID2} 
    ${seller_party_id}    Set Variable   ${SELLER_PARTY_ID}
    ${from_time}    Get Current Date   UTC
    ${from_time_robot}    Add Time To Date   ${from_time}   1 day   exclude_millis=yes
    ${from_time_robot}   Replace String Using Regexp   ${from_time_robot}  \\d\\d:\\d\\d:\\d\\d   00:00:00
    ${to_time_robot}      Add Time To Date   ${from_time_robot}  ${INSTALL_INTERVAL}  exclude_millis=yes
    ${from_time}   Replace String Using Regexp   ${from_time_robot}  \\s   T
    ${to_time}   Replace String Using Regexp   ${to_time_robot}  \\s   T
    &{dates}  Create Dictionary   from=${from_time}Z    to=${to_time}Z
    # "to" time is inclusive so add one day for comparisons with available appointments
    ${to_time_robot}      Add Time To Date   ${to_time_robot}  1 day  exclude_millis=yes
    
    ${status}   ${data}   Get Available Install Dates   ${address}   ${geoLocationInput}  ${product_type_ids}   ${seller_party_id}   ${dates}
    Should Be True   ${status}

    Set Test Variable  ${product_type_ids}
    ${product_type_ids_temp}   Set Variable  ${product_type_ids}
    Set Test Variable  ${product_type_ids_temp}
    Set Test Variable  ${from_time_robot}
    Set Test Variable  ${to_time_robot}
    ${all_appointments}  Set Variable   ${data}[data][getAvailableAppointments][productAvailableAppointments]

    :FOR    ${item}    IN    @{all_appointments}
    \       ${product_type_id}   Set Variable  ${item}[productTypeIds]
    \       ${appointments}   Set Variable  ${item}[availableAppointments]
    \       ${appointment_number}   Get Length   ${appointments}
    \       Log   ${appointment_number} appointments available for product type ids ${product_type_id}   console=True
    \       Verify Valid Appointments   ${product_type_id}   ${appointments}
    ${status}  ${message}   Run Keyword And Ignore Error   Length Should Be   ${product_type_ids_temp}   0
    Run Keyword If   '${status}'=='FAIL'   Log  No appointments available for product type id ${product_type_ids_temp}   WARN

*** Keywords ***
Verify Valid Appointments
    [Documentation]   Verify that product type id was requested and that appointments are in requested date range
    [Arguments]   ${product_type_id}   ${appointments}
    
    :FOR  ${id}   IN   @{product_type_id}
    \   ${status}   ${message}    List should Contain Value   ${product_type_ids}   ${id}   #   make sure returned product type ids are those requested
    \   ${appointment_count}    Get Length  ${appointments}
    \   Run Keyword If  ${appointment_count}>0
    \   ...  Remove Values From List   ${product_type_ids_temp}   ${id}    #   empty out complete list of product type ids for which appointments were requested to verify all appointments provided
  
    :FOR   ${available_time}   IN   @{appointments}
    \   ${from_time_temp}   Replace String  ${available_time}[from]   Z   ${EMPTY}
    \   ${from_time_temp}   Replace String  ${from_time_temp}   T   ${SPACE}
    \   ${from_time_temp}   Convert Date   ${from_time_temp}   datetime
    \   Should Be True  '${from_time_temp}'>='${from_time_robot}'
    \   ${to_time_temp}   Replace String  ${available_time}[to]   Z   ${EMPTY}
    \   ${to_time_temp}   Replace String  ${to_time_temp}   T   ${SPACE}
    \   ${to_time_temp}   Convert Date   ${to_time_temp}   datetime
    \   Should Be True  '${to_time_temp}'<='${to_time_robot}'   
    Set Test Variable  ${product_type_ids_temp}

Suite Setup
    [Documentation]   Configure suite variables
    Log   Configure suite variables here@
    #ResVNO Smoke 

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
 
    
