*** Settings ***
Documentation     Keywords to access FO API
Library   fo_api.py
Library     DateTime
Resource   ../common/bep_resource.robot
Variables   fo_parameters.py

*** Keywords ***
Get Available Install Dates
    [Documentation]  Request appointment within provided timespan in days
    [Arguments]   ${address}   ${timespan}
    ${date}   Get Current Date  UTC
    ${date}   Add Time To Date   ${date}   2 days
    ${from_date} 	Convert Date	${date}	result_format=%Y-%m-%d
    Set Suite Variable   ${from_date}
    ${to_date}   Add Time To Date   ${from_date}   ${timespan} days
    Set Suite Variable   ${to_date}
    ${dates}   Create Dictionary   from=${from_date}   to=${to_date}
    ${input}   Create Dictionary  address=${service_location}  dates=${dates}   country_code=${COUNTRY_CODE}
    ${status}   ${result}   useFOApi   getAvailableAppointments   ${input}
    Log To Console   result=${result}
    Should Be Equal As Strings  ${status}   True   Get install dates failed, ${result}
    Log  ${result}
    ${status}   ${message}   Run Keyword And Ignore Error   Dictionary Should Not Contain Key   ${result}  errors
    ${error}   Run Keyword If   '${status}'=='FAIL'   Fail   ${result}[errors][0][extensions][message]

    ${num_appts}   Get Length  ${result}[data][getAvailableAppointments][availableAppointments]
    Run Keyword And Ignore Error   Should Not Be Equal As Integers   ${num_appts}   0      No appointments available
    Verify Valid Appointments  ${result}[data][getAvailableAppointments][availableAppointments]
 
    # select an appointment and randomly determine if upsertWorkOrder will be scheduled - this section won't always be necessary
    ${appointments}   Set Variable  ${result}[data][getAvailableAppointments][availableAppointments]
    ${selected_appointment}    Run Keyword If   ${num_appts}>0   Evaluate  random.choice($appointments)  random
    ...   ELSE   Set Variable  ${None}
    Set Suite Variable   ${selected_appointment}
    #${schedule_bool}=    Run Keyword If   ${num_appts}>0 	 Evaluate	random.randint(0,1)  	modules=random
    #...   ELSE   Set Variable  0
    ${schedule_bool}   Set Variable  0
    Set Suite Variable  ${schedule_bool}
    
    [return]   ${appointments} 
    
Verify Valid Appointments
    [Documentation]   Verify that appointments are in requested date range
    [Arguments]    ${appointments}
    # give 24-hour margin on "to date"
    ${all_to_date}   Add Time To Date   ${to_date}   1 day
    :FOR   ${available_time}   IN   @{appointments}
    \   ${new_time}    Subtract Date From Date   ${available_time}[from]   ${from_date}
    \   Should Be True   ${new_time}>0    offered install date of ${available_time}[from] is earlier than requested earliest date of ${from_date}
    \   ${new_time}    Subtract Date From Date   ${all_to_date}   ${available_time}[from]   
    \   Should Be True   ${new_time}>0   offered install date of ${available_time}[from] is greater than requested latest date of ${to_date} 

Get FSM Work Order Information
    [Documentation]  Query FSM for info about work order
    [Arguments]   ${work_order_id}
    ${response}   getWorkOrderFromFSM   ${work_order_id}
    Should Be Equal As Strings  ${result}[0]   True   Get FSM Work Order Information failed, ${response}[1]
    [return]   ${response}[1]
    
Upsert Work Order To FO
    [Documentation]  invoke upsertWorkOrder mutation. Creates suite variables ${external_work_order_id} and 
    [Arguments]   ${appointment_id}=${None}

    # need working customer ref to test
    # Set Test Variable  ${customer_ref}   9527f26c-394e-48ff-b313-c6581e890fed

    ### Get FO PRODUCT ID from POM ###
    
    ${response}   Get Offers From POM  ${buyer_id}    ${SELLER_ID}    ${COUNTRY_CODE}   ${service_location}[coordinates]   FULFILLMENT
    :FOR  ${item}  IN  @{response}
    \   Run Keyword If  '${item}[name]'=='${COUNTRY_VARIABLES}[${COUNTRY_CODE}][INSTALLATION_PRODUCT_NAME]'  Run Keywords
    \   ...   Set Test Variable  ${fullfillment_products}  ${item}[products]   AND
    \   ...   Exit For Loop
    
    :FOR  ${product}   IN   @{fullfillment_products} 
    \   Run Keyword If   '${product}[name]'=='Install for Internet/VoIP/WiFi'   Exit For Loop   
    Should Be Equal As Strings   ${product}[name]   Install for Internet/VoIP/WiFi   Could not locate fulfillment product 'Install for Internet/VoIP/WiFi' in POM    
    ${chars}   Set Variable  ${product}[characteristics]  
    :FOR  ${characteristic}  IN   @{chars}
    \   Run Keyword If  '${characteristic}[name]'=='FO_PRODUCT_ID'   Set Test Variable  ${fo_product_id}   ${characteristic}[value]
    
    ###  Get characteristics and PID for internet product, and PID for fulfillment product, from PSM ###
    ${status}  ${result}    usePsmApi    getProductInstanceForFOWithRelnId    ${customer_ref}
    Should Be Equal As Strings  ${status}  True   ${result}
     
    ${internet_products}  Set Variable  ${result}[data][getProductInstances][productInstances]
    :FOR  ${product}  IN  @{internet_products}
    \   Run Keyword If  '${product}[kind]'=='FIXED_SATELLITE_INTERNET'   Set Test Variable  ${internet_product}   ${product}
    \   Run Keyword If  '${product}[kind]'=='FULFILLMENT'   Set Test Variable  ${fulfillment_product}   ${product}
    Variable Should Exist  ${internet_product}   Could not location internet product in product instances
    Log To Console  internet product = ${internet_product} 
    Variable Should Exist  ${fulfillment_product}   Could not location fulfillment product in product instances
    Set Suite Variable  ${external_work_order_id}  ${fulfillment_product}[productInstanceId]
     
    ${idu}  Create Dictionary  kind=IDU_EQUIPMENT
    ${odu}  Create Dictionary  kind=ODU_EQUIPMENT
    ${chars}  Set Variable  ${internet_product}[characteristics]
    ${new_chars}   Create List
    :FOR  ${char}   IN  @{chars}
    \   Run Keyword If  '${char}[name]'=='IDU_EQUIPMENT'   Set To Dictionary  ${idu}  name=${char}[value]
    \   Run Keyword If  '${char}[name]'=='ODU_EQUIPMENT'   Set To Dictionary  ${odu}  name=${char}[value]
    \   ${status}   ${msg}  Run Keyword And Ignore Error   List Should Contain Value  ${REQUIRED_WORK_ORDER_CHARACTERISTICS}   ${char}[name]
    \   Run Keyword If   '${status}'=='PASS'  Append To List  ${new_chars}  ${char}
    ${equipment}  Create List  ${idu}  ${odu}
    Set Suite Variable  ${fo_equipment_list}    ${equipment}
    ${work_order_products}   Create List
    Set Suite Variable  ${internet_pid}   ${internet_product}[productInstanceId]
    ${wo_product}   Create Dictionary  id=${internet_pid}   kind=${internet_product}[kind]   name=${internet_product}[name]     
    Set To Dictionary  ${wo_product}  equipment=${equipment}   characteristics=${new_chars}
    Append To List   ${work_order_products}   ${wo_product}
 
    ${date}   Get Current Date  UTC   
    ${phone_note}   Create Dictionary  content=${customer}[primaryPhoneNumber]  author=bepe2e   createTime=${date}
    ${notes}   Create List   ${phone_note}  
    ${work_order}  Create Dictionary   externalWorkOrderId=${external_work_order_id}  foProductId=${fo_product_id}   products=${work_order_products}   notes=${notes}
    Run Keyword If   ${appointment_id}!=${None}   Set To Dictionary  ${work_order}   appointmentId=${appointment_id}[availableAppointmentId]

    ${inputs}  Create Dictionary
    ${party_summary}   Create Dictionary  name=custRelnId  value=${customer_ref}
    # WORKAROUND FOR https://jira.viasat.com/browse/FOBEPAPI-163
    Set To Dictionary  ${customer}  primaryPhoneNumber=(800) 555-1212
    Set To Dictionary   ${inputs}   fulfillmentPartnerId=${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_PARTNER_ID]  serviceLocation=${service_location}   customer=${customer}
    ...   partySummary=${party_summary}   workOrder=${work_order}
    Log To Console  ${inputs}
    ${status}   ${result}   useFOApi   upsertWorkOrder   ${inputs}
    
    Run Keyword And Continue On Failure  Should Be True   ${status}   ${result}  
    
    [return]   ${status}   ${external_work_order_id}
    
Verify FO Work Order
    [Documentation]  Verify internal work order id exists and FIXED_SATELLITE_INTERNET PID is same as provided in upsertWorkOrder
    [Arguments]   ${external_work_order_id}
    ${status}   ${result}   useFOApi  getWorkOrder  ${external_work_order_id}
    Should Be True   ${status}   ${result}
    ${status}   ${msg}  Run Keyword   Dictionary Should Not Contain Key  ${result}   errors   ${result}
       
    ${status}   ${msg}  Run Keyword And Ignore Error   Set Test Variable  ${internal_work_order_id_input}   ${result}[data][getWorkOrder][workOrder][internalWorkOrderId]
    ${type} =    Run Keyword If  '${status}'=='PASS'  Evaluate    type($internal_work_order_id_input).__name__
    ...   ELSE  Set Variable  NoneType
    Should Not Be Equal As Strings  ${type}   Nonetype
    Log    ${internal_work_order_id_input}
    Log    ${result}[data][getWorkOrder][workOrder][status]
    Should Be Equal   ${internet_pid}    ${result}[data][getWorkOrder][workOrder][products][0][id]     FIXED_SATELLITE_INTERNET pid from FO getWO does not equal value in PSM
    ${received_equipment}  Set Variable  ${result}[data][getWorkOrder][workOrder][products][0][equipment]
    # ${fo_equipment_list} is suite variable created in "Upsert Work Order To FO"
    :FOR  ${equip}  IN  @{fo_equipment_list}
    \    ${received_equipment}   Find Equipment Item   ${equip}  ${received_equipment}
    ${equip_remaining}   Get Length  ${received_equipment}
    Should Be Equal As Numbers  ${equip_remaining}  0   Received work order from FO includes more equipment than provided in WO: ${received_equipment}
    
Find Equipment Item
    [Documentation]  Locate provided equipment entry in suite variable ${received_equipment}
    [Arguments]   ${equip}   ${received_equipment}
    ${i}   Set Variable  -1
    Convert To Number  ${i}
    :FOR  ${item}   IN  @{received_equipment}
    \   ${i}   Evaluate   ${i}+1
    \   Exit For Loop If  '${item}[kind]'=='${equip}[kind]' and '${item}[name]'=='${equip}[name]'
    ${status}   ${msg}  Run Keyword And Ignore Error   Should Be True   '${item}[kind]'=='${equip}[kind]' and '${item}[name]'=='${equip}[name]'  
    Run Keyword If  '${status}'=='PASS'  Remove From List  ${received_equipment}   ${i}
    [return]  ${received_equipment}
   
Verify Fulfillment Product Instance State
    [Arguments]   ${state}  ${expected_fsm_status}
    ${status}  ${result}    usePsmApi    getProductInstanceForFOWithRelnId    ${customer_ref}
    Should Be Equal As Strings  ${status}  True   ${result}
    ${internet_products}  Set Variable  ${result}[data][getProductInstances][productInstances]
    :FOR  ${product}  IN  @{internet_products}
    \   Run Keyword If  '${product}[kind]'=='FULFILLMENT'   Set Test Variable  ${fulfillment_product}   ${product}
    \   Exit For Loop If  '${product}[kind]'=='FULFILLMENT'
    Should Be Equal As Strings   ${product}[kind]    FULFILLMENT   fulfillment product is not present 
    Should Be Equal As Strings  ${product}[state]   ${state}     fulfillment product is not in ${state} state
    ${fsm_status}    getWorkOrderFromFSM    ${external_work_order_id}
    Log   ${fsm_status}
    Should Be Equal As Strings   ${fsm_status}[1][orderStatus]   ${expected_fsm_status}
    Should Be Equal As Strings   ${fsm_status}[1][customerToken]   ${customer_ref}    
 
    