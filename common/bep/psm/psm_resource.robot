*** Settings ***
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Library    OperatingSystem
Library    Process
Library   ./psm_api.py
Variables         ./psm_parameters.py

*** Keywords ***
Upsert to PSM
    [Documentation]     Robot keyword to upsert to PSM
    [Arguments]    ${party_role_id}
    Log To Console    Upsert To PSM w/ partyRoleId
    ${status}  ${result}    usePsmApi    upsertProductInstance  ${party_role_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${hl_product_instance}    Set Variable  ${result}[data][UpsertProductInstance][productInstanceId]
    [return]    ${hl_product_instance}

Get PSM Instance
    [Documentation]     Robot keyword to get PSM Full Instance
    [Arguments]    ${product_instance_id}
    ${status}  ${result}    usePsmApi    getProductInstance  ${product_instance_id}
    Should Be True    ${status}
    Log Response    ${result}
    [return]    ${result}

Get SPB Price Category For Main Product From PSM
    [Documentation]     Robot keyword to Get SPB Price Category For Main Product From PSM
    [Arguments]    ${product_instance_id}
    ${result}    Get PSM Instance    ${product_instance_id}
    ${spb_price_cat}    Parse SPB Price Category For Main Product    ${result}
    [return]    ${spb_price_cat}

Parse SPB Price Category For Main Product
    [Documentation]     Robot keyword to Parse SPB Price Category For Main Product
    [Arguments]    ${result}
    Set Test Variable   ${characteristics}   ${result}[data][getProductInstances][productInstances][0][prices][0][characteristics]
    : FOR    ${characteristic}    IN    @{characteristics}
    \   Set Test Variable   ${name}   ${characteristic}[name]
    \   Run Keyword If    '${name}'=='SPB_PRICE_CATEGORY'    Set Test Variable   ${value}   ${characteristic}[value]
    \   Run Keyword If    '${name}'=='SPB_PRICE_CATEGORY'     Exit For Loop
    [return]   ${value}

Get Requested Product Instance Id From PSM
    [Documentation]     Robot keyword to Get requested Product Instance Id From PSM
    [Arguments]    ${product_instance_id}   ${kind}  
    ${result}    Get PSM Instance    ${product_instance_id}
    ${pid}    Parse Child Product Instance Id From Kind    ${result}    ${kind}
    ${status}   ${message}   Run Keyword And Ignore Error  Variable Should Exist  ${pid_dict}
    Run Keyword If  '${status}'=='PASS'  Run Keywords
    ...  Set To Dictionary  ${pid_dict}  ${kind}=${pid}  AND
    ...  Set Suite Variable  ${pid_dict}
    [return]    ${pid}


Get Discount Product Instance Id From PSM
    [Documentation]     Robot keyword to Get Discount Product Instance Id From PSM
    [Arguments]    ${product_instance_id}
    ${result}    Get PSM Instance    ${product_instance_id}
    ${discount_pid}    Parse Child Product Instance Id From Kind    ${result}    ${DISCOUNT_KIND}
    [return]    ${discount_pid}

Get Contract Product Instance Id From PSM
    [Documentation]     Robot keyword to Get Contract Product Instance Id From PSM
    [Arguments]    ${product_instance_id}
    ${result}    Get PSM Instance    ${product_instance_id}
    ${discount_pid}    Parse Child Product Instance Id From Kind    ${result}    ${CONTRACT_KIND}
    [return]    ${discount_pid}

Parse Child Product Instance Id From Kind
    [Documentation]     Robot keyword to Parse Discount Product Instance Id
    [Arguments]    ${result}   ${child_product_kind}
    Set Test Variable   ${productInstanceRelationships}   ${result}[data][getProductInstances][productInstanceRelationships]
    : FOR    ${productInstanceRelationship}    IN    @{productInstanceRelationships}
    \   Set Test Variable   ${kind}   ${productInstanceRelationship}[sourceProductInstance][kind]
    \   Log     ${child_product_kind}
    \   Run Keyword If    '${kind}'=='${child_product_kind}'    Set Test Variable   ${pid}   ${productInstanceRelationship}[sourceProductInstance][productInstanceId]
    \   Run Keyword If    '${kind}'=='${child_product_kind}'     Exit For Loop
    [return]   ${pid}


Validate PSM State Of Product
    [Documentation]     Robot keyword to get PSM Full Instance
    [Arguments]    ${individual_pid}    ${expected_state}
    ${result}    Get PSM Instance    ${individual_pid}
    ${received_state}    Parse Product State In PSM    ${result}
    Should Be Equal    ${received_state}    ${expected_state}

Get And Validate Product Instance Ids From PSM
    [Documentation]   Get And Validate Product Instance Ids From PSM
    [Arguments]   ${product_instance_id}    ${expected_billing_account_id}   ${discount_prod_type_id}    ${contract_prod_type_id}
    ${result}   Get PSM Instance   ${product_instance_id}
    Log   ${result}
    @{product_instance_ids}    Get Child Product Instance Ids From Response   ${result}    ${product_instance_id}
    #Set Test Variable     @{product_instance_ids}
    #Log   ${product_instance_ids}
    ${billing_Account_from_psm}    Get Billing Account From PSM    ${result}
    Should Be Equal    ${billing_Account_from_psm}    ${expected_billing_account_id}
    ${discount_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${discount_prod_type_id}
    Log    ${discount_product_instance_id}
    #Set Test Variable    ${discount_product_instance_id}
    ${contract_product_instance_id}    Get Child Product Instance Id From Prod Type Id    ${result}    ${contract_prod_type_id}
    Log    ${contract_product_instance_id}
    #Set Test Variable    ${contract_product_instance_id}
    [return]    @{product_instance_ids}    ${discount_product_instance_id}    ${contract_product_instance_id}

Get And Validate All Product Instance Ids From PSM
    [Documentation]   Get And Validate Product Instance Ids From PSM
    [Arguments]   ${product_instance_id}    ${expected_billing_account_id}   ${child_prod_kinds}
    ${result}   Get PSM Instance   ${product_instance_id}
    Log   ${result}
    @{product_instance_ids}   Create List    ${product_instance_id}
    
    ${prod_instance_dict}   Create Dictionary
    
    ${billing_Account_from_psm}    Get Billing Account From PSM    ${result}
    Should Be Equal    ${billing_Account_from_psm}    ${expected_billing_account_id}
    : FOR    ${child_product}    IN    @{child_prod_kinds}
    \   ${child_prod_instance_id}    Get Product Instance Id From Kind    ${result}    ${child_product}
    \   Append To List	${product_instance_ids}	${child_prod_instance_id}
    \   Set To Dictionary  ${prod_instance_dict}   ${child_product}=${child_prod_instance_id}
    ${expected_child_products_count}    Get Length    ${child_prod_kinds}
    ${received_pids_count}    Get Length    ${product_instance_ids}
    ${expected_pids_count}   Evaluate  ${expected_child_products_count}+1
    Should Be Equal As Strings      ${received_pids_count}    ${expected_pids_count}     Not all expected child prod instance ids found
    Log    ${product_instance_ids}
    Set Suite Variable   ${prod_instance_dict}
    [return]    @{product_instance_ids}

Parse Product State In PSM
    [Documentation]     Robot keyword to parse product state
    [Arguments]    ${result}
    Set Test Variable   ${product_state}   ${result}[data][getProductInstances][productInstances][0][state]
    [return]   ${product_state}

Get Billing Account From PSM
    [Documentation]     Robot keyword to get Get Billing Account From PSM from the response of get PI
    [Arguments]    ${get_pi_response}
    ${productInstances}    Set Variable    ${get_pi_response}[data][getProductInstances][productInstances]
    : FOR    ${pi}    IN    @{productInstances}
    \   ${characteristics}    Get From Dictionary    ${pi}    characteristics
    \   ${status}    ${billing_account}    Loop Over Characteristics    ${characteristics}    SPB:billingAccountId
    \   Run Keyword If    ${status}    Exit For Loop
    [return]    ${billing_account}

Get Child Product Instance Id From Prod Type Id
    [Documentation]     Robot keyword to get PID for a given prod type id
    [Arguments]    ${get_pi_response}    ${prod_type_id}
    ${productInstanceRelationships}    Set Variable    ${get_pi_response}[data][getProductInstances][productInstanceRelationships]
    #Log    ${productInstanceRelationships}
    : FOR    ${productInstanceRelationship}    IN    @{productInstanceRelationships}
    \   Log    ${productInstanceRelationship}
    \   ${received_prod_type_id}    Set Variable    ${productInstanceRelationship}[sourceProductInstance][productTypeId]
    #\   Log   ${received_prod_type_id} ${prod_type_id}   WARN
    \   ${received_product_instance_id}    Run Keyword If    '${received_prod_type_id}' == '${prod_type_id}'    Set Variable    ${productInstanceRelationship}[sourceProductInstance][productInstanceId]
    \   Run Keyword If    '${received_prod_type_id}' == '${prod_type_id}'    Exit For Loop
    Log    ${received_product_instance_id}
    [return]    ${received_product_instance_id}

Update OTC List
    [Documentation]  Check if product kind is in OTC list for country and add pid to list if so
    [Arguments]  ${otc_pid_list}  ${kind}  ${productInstanceId}
    ${status}  ${msg}  Run Keyword And Ignore Error   Dictionary Should Contain Key  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][OTCS]  ${kind}
    Run Keyword If  '${status}'=='PASS'  Append To List  ${otc_pid_list}   ${productInstanceId}
    [return]  ${otc_pid_list} 
    
Get Child Product Instance Ids From Response
    [Documentation]     Robot keyword that returns list of PIds from the response of get PI. {high-level-pid, contract-pid, discount-pid}
    [Arguments]    ${get_pi_response}    ${top_level_product_instance_id}
    @{product_instance_ids}   Create List    ${top_level_product_instance_id}
    ${productInstances}    Set Variable    ${get_pi_response}[data][getProductInstances][productInstanceRelationships]
    ${otc_pid_list}  Create List
    : FOR    ${pi}    IN    @{productInstances}
    \   ${productRelationshipType}    Get From Dictionary    ${pi}    productRelationshipType
    \   ${sourceProductInstance}    Run Keyword If    '${productRelationshipType}' == 'DEPENDS_ON'    Get From Dictionary    ${pi}    sourceProductInstance  
    \   ${productInstanceId}    Run Keyword If    '${productRelationshipType}' == 'DEPENDS_ON'    Get From Dictionary    ${sourceProductInstance}    productInstanceId
    \   Run Keyword If    '${productRelationshipType}' == 'DEPENDS_ON'    Update OTC List  ${otc_pid_list}  ${sourceProductInstance}[kind]   ${productInstanceId}    
    \   Run Keyword If    '${productRelationshipType}' == 'DEPENDS_ON'    Append To List	${product_instance_ids}	${productInstanceId}
    Log    ${product_instance_ids}
    Set Suite Variable  ${otc_pid_list}
    [return]    @{product_instance_ids}

Get Product Instance Id From Kind
    [Documentation]     Robot keyword that returns pid for a given child product kind
    [Arguments]    ${get_pi_response}    ${child_prod_kind}
    ${productInstances}    Set Variable    ${get_pi_response}[data][getProductInstances][productInstanceRelationships]
    : FOR    ${pi}    IN    @{productInstances}
    \   ${productRelationshipType}=   Set Variable    ${pi}[productRelationshipType]
    \   ${kind}=   Set Variable    ${pi}[sourceProductInstance][kind]
    \   ${productInstanceId}=   Set Variable    ${pi}[sourceProductInstance][productInstanceId]
    \   ${sourceProductInstance}    Run Keyword If    '${productRelationshipType}' == 'DEPENDS_ON' and '${kind}' == '${child_prod_kind}'   Exit For Loop
    [return]    ${productInstanceId}



Loop Over Characteristics
    [Documentation]     Robot keyword to loop over characteristics to get value of given field
    [Arguments]    ${characteristics}    ${given_key}
    : FOR    ${characteristic}    IN    @{characteristics}
    \   ${name}    Get From Dictionary    ${characteristic}    name
    \   ${value}    Run Keyword If    '${name}' == '${given_key}'    Get From Dictionary    ${characteristic}    value
    \   Run Keyword If    '${name}' == '${given_key}'    Exit For Loop
    [return]    True    ${value}

Verify Device State In SDP
    [Documentation]     Robot keyword to Verify Device State In SDP ith given state
    [Arguments]    ${product_instance_id}    ${expected_state}
    ${received_state}    ${received_product_instance_id}     ${latitude}   ${longitude}    getDeviceStateBasedOnId   ${product_instance_id}  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][MODEM][SDP_JWT_NAME]
    Should Be Equal As Strings    ${received_state}    ${expected_state}

Verify Service State In SDP
    [Documentation]     Robot keyword to Verify Device State In SDP ith given state
    [Arguments]    ${product_instance_id}    ${expected_state}
    ${received_product_instance_id}    ${received_state}    ${received_catalog_id}   getDeviceService   ${product_instance_id}
    Should Be Equal As Strings    ${received_state}    ${expected_state}

Request Upsert Characteristics
    [Documentation]     Robot keyword to Request Upsert Characteristics with given name, value and PI
    [Arguments]     ${product_instance_id}    ${characteristics_name}    ${characteristics_value}
    ${status}  ${result}    usePsmApi    requestUpsertCharacteristics    ${product_instance_id}    ${characteristics_name}    ${characteristics_value}
    Log Response    ${result}
    Should Be True    ${status}
    ${success}    Set Variable    ${result}[data][requestUpsertCharacteristic][success]
    Should Be True    ${success}

Request PI Life Cycle State Change To Active
    [Documentation]     Robot keyword to Request PI Life Cycle State Change To Active
    [Arguments]     ${product_instance_id}
    ${status}  ${result}    usePsmApi    requestProductInstanceLifecycleStateChange    ${product_instance_id}    ACTIVE
    Log Response    ${result}
    Should Be True    ${status}
    ${success}    Set Variable    ${result}[data][requestProductInstanceLifecycleStateChange][success]
    Should Be True    ${success}

Request PI Life Cycle State Change To Processed
    [Documentation]     Robot keyword to Request PI Life Cycle State Change To Processed
    [Arguments]     ${product_instance_id}
    ${status}  ${result}    usePsmApi    requestProductInstanceLifecycleStateChange    ${product_instance_id}    PROCESSED
    Log Response    ${result}
    Should Be True    ${status}
    ${success}    Set Variable    ${result}[data][requestProductInstanceLifecycleStateChange][success]
    Should Be True    ${success}

Insert Product Instance Relationship
    [Documentation]     Robot keyword Insert Product Instance Relationship
    [Arguments]     ${src_product_instance_id}   ${dest_product_instance_id}   ${relationship_type}
    ${status}  ${result}    usePsmApi    insertProductInstanceRelationship    ${src_product_instance_id}   ${dest_product_instance_id}   ${relationship_type}
    Log Response    ${result}
    Should Be True    ${status}
    ${productRelationshipType}    Set Variable    ${result}[data][insertProductInstanceRelationship][productRelationshipType]
    Should Be Equal    ${productRelationshipType}    ${relationship_type}

Request PI Life Cycle State Change To Suspended
    [Documentation]     Robot keyword to Request PI Life Cycle State Change To Suspended
    [Arguments]     ${product_instance_id}
    ${status}  ${result}    usePsmApi    requestProductInstanceLifecycleStateChange    ${product_instance_id}    SUSPENDED
    Log Response    ${result}
    Should Be True    ${status}
    ${success}    Set Variable    ${result}[data][requestProductInstanceLifecycleStateChange][success]
    Should Be True    ${success}

Request PI Life Cycle State Change To Deactivated
    [Documentation]     Robot keyword to Request PI Life Cycle State Change To Deactivated
    [Arguments]     ${product_instance_id}
    ${status}  ${result}    usePsmApi    requestProductInstanceLifecycleStateChange    ${product_instance_id}    DEACTIVATED
    Log Response    ${result}
    Should Be True    ${status}
    ${success}    Set Variable    ${result}[data][requestProductInstanceLifecycleStateChange][success]
    Should Be True    ${success}

Get PSM Instance With RelnId
    [Documentation]     Robot keyword to get PSM Full Instance With Customer Relationship Id
    [Arguments]     ${relationship_id}
    Log To Console     Query PSM For Product Instance Using Customer Relationship ID
    ${status}  ${result}    usePsmApi    getProductInstanceWithRelnId    ${relationship_id}
    Should Be True    ${status}
    ${product_instances}   Set Variable   ${result}[data][getProductInstances][productInstances]
    :FOR  ${prod}  IN  @{product_instances}
    \   Exit For Loop If    '${prod}[kind]'=='${INTERNET_KIND}'
    Should Be Equal As Strings   ${prod}[kind]   ${INTERNET_KIND}    Could not locate ${INTERNET_KIND} product instance
    [return]    ${prod}[productInstanceId]

Convert POM to PSM Dict
    [Documentation]     Temporary Robot keyword to convert POM to PSM dict to use in SPB upsert
    [Arguments]    ${full_product_instance}
    Log To Console    Convert POM to PSM for SPB Upsert
    ${status}  ${result}    usePsmApi    createPom2PsmDict    ${full_product_instance}
    Log Response    ${result}s
    Should Be True    ${status}
    [return]    ${result}

Create PSM SQS Queue
    [Documentation]     creates a sqs queue to subscribe PSM topic
    ${status}    ${psm_queue_name}    ${psm_subscription_arn}    createQueueAndSubscribe    bepe2etest-psm    ${PSM_SNS_TOPIC}
    Should Be True    ${status}
    Set Suite Variable    ${psm_queue_name}
    Set Suite Variable    ${psm_subscription_arn}
    Log    ${psm_queue_name}

Get & Verify Event From PSM SNS For Upsert Characteristics
    [Documentation]     keeps on polling messages until get a successful message used
    [Arguments]     ${product_instance_id}   ${characteristics_name}    ${expected_characteristics_value}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    ${received_chracteristics_value}    ${message}    Wait Until Keyword Succeeds    60s    2s    Get PSM SNS Messages For Upsert Characteristics   ${product_instance_id}    ${characteristics_name}
    Log    ${message}
    Should Be Equal As Strings    ${received_chracteristics_value}    ${expected_characteristics_value}
    [return]    ${message}

Get & Verify PSM Product Instance Event
    [Documentation]     Get & Verify PSM Product Instance Event
    [Arguments]     ${product_instance_id}   ${expected_state}
    ${status}    ${result}    usePsmApi    getProductInstanceEvents    ${product_instance_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${events}    Set Variable    ${result}[data][getProductInstanceEvents][events]
    : FOR    ${event}    IN    @{events}
    \    Run Keyword If  '${event}[caller]'=='bep-sism-nonprod_api'    Set Test Variable    ${state}    ${event}[request][state]
    \    ${event_present}	Set Variable If	 '${state}'=='${expected_state}'	  True	  False
    \    Log   ${event_present}
    \    Run Keyword If  '${state}'=='${expected_state}'    Exit For Loop
    Should Be True    ${event_present}    Did not find event for ${expected_state}
    Log    ${event_present}

Get PSM SNS Messages For Upsert Characteristics
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${product_instance_id}    ${characteristics_name}
    ${status}    ${chracteristics_value}    ${message}    readAndDeleteMessagePSMForGivenCharacteristics   ${psm_queue_name}     ${product_instance_id}    ${characteristics_name}
    Should Be True    ${status}
    [return]    ${chracteristics_value}    ${message}

Get & Verify Event From PSM SNS For Active State
    [Documentation]     keeps on polling messages until get a successful message used
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    @{product_instance_ids}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    Run Keyword If    '${COUNTRY_CODE}' == 'MX'    Set Test Variable    ${max_time}    600s    ELSE    Set Test Variable    ${max_time}    480s
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    ${max_time}    2s    Get PSM SNS Messages With Active State   ${pid_mapping}    @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event     ${pid_mapping}    ${product_instance_id}    ACTIVATING      ACTIVE    ${expected_billing_account_id}    ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Suspended State
    [Documentation]     keeps on polling messages until get a successful message used
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    @{product_instance_ids}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get PSM SNS Messages With Suspended State   ${pid_mapping}    @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event     ${pid_mapping}    ${product_instance_id}    SUSPENDING      SUSPENDED    ${expected_billing_account_id}    ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Resumed State
    [Documentation]     keeps on polling messages until get a successful message used
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    @{product_instance_ids}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get PSM SNS Messages With Resumed State   ${pid_mapping}    @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event     ${pid_mapping}    ${product_instance_id}    REACTIVATING      ACTIVE    ${expected_billing_account_id}    ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Deactivated State
    [Documentation]     keeps on polling messages until get a successful message used
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    @{product_instance_ids}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get PSM SNS Messages With Deactivated State   ${pid_mapping}    @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event     ${pid_mapping}    ${product_instance_id}    DEACTIVATING      DEACTIVATED    ${expected_billing_account_id}    ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Canceled State
    [Documentation]     keeps on polling messages until get a successful message used
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    @{product_instance_ids}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get PSM SNS Messages With Canceled State   ${pid_mapping}    @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event     ${pid_mapping}    ${product_instance_id}    CANCELING      CANCELED    ${expected_billing_account_id}    ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Accepted State
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    @{product_instance_ids}
    Log    @{product_instance_ids}[0]
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    Run Keyword If    '${COUNTRY_CODE}' == 'MX'    Set Test Variable    ${max_time}    600s    ELSE    Set Test Variable    ${max_time}    480s 

    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    ${max_time}    2s    Get PSM SNS Messages With Accepted State   ${pid_mapping}   @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event     ${pid_mapping}    @{product_instance_ids}[0]    ACCEPTING      ACCEPTED    ${expected_billing_account_id}  ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Given State For Fulfillment Product
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}   ${new_state}  ${product_instance_ids}
    # create dictionary where key = new state and value = old state. This should be somewhere else, like bep_parameters.py
    ${state_map}   Create Dictionary   ACCEPTED=ACCEPTING   PROCESSED=ACCEPTED
    Set Suite Variable   ${state_map} 
    Log    @{product_instance_ids}[0]
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    240s    2s    Get PSM SNS Messages With Given States   ${pid_mapping}    ${product_instance_ids}   ${state_map}[${new_state}]  ${new_state}
    Log    ${pid_mapping}
    Validate Values From PSM Fulfillment Events     ${pid_mapping}     ACCEPTING      ACCEPTED    ${expected_billing_account_id}   ${expected_pi_file_location}
    [return]    ${message}

Get & Verify Event From PSM SNS For Buy More
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]     ${expected_billing_account_id}   ${expected_pi_file_location}    ${old_state}   ${new_state}    @{product_instance_ids}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    &{pid_mapping}     Create Dictionary
    Log    ${pid_mapping}
    Set Test Variable    ${pid_mapping}
    ${pid_mapping}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get PSM SNS Messages With Accepted State   ${pid_mapping}   @{product_instance_ids}
    Log    ${pid_mapping}
    Validate Values From PSM Event For BuyMore    ${pid_mapping}    @{product_instance_ids}[0]    ${old_state}      ${new_state}    ${expected_billing_account_id}  ${expected_pi_file_location}
    [return]    ${message}

Validate Values From PSM Event For BuyMore
    [Documentation]     validate old state, new state, spb category, psm kind and billing account and spb:file location id in that sequence of the list
    [Arguments]   ${pid_mapping}    ${product_instance_id}    ${expected_old_state}      ${expected_new_state}    ${expected_billing_account_id}    ${expected_pi_file_location}
    :FOR  ${key}  IN  @{pid_mapping.keys()}
    \  ${value}  get from dictionary  ${pid_mapping}  ${key}
    \  ${received_old_state} 	Get From List	${value}	0
    \  ${received_new_state} 	Get From List	${value}	1
    \  ${received_spb_category} 	Get From List	${value}	2
    \  ${received_psm_kind} 	Get From List	${value}	3
    \  ${received_billing_account} 	Get From List	${value}	4
    \  ${kind}    Get From List	${value}	5
    \  ${received_pi_file_location} 	Get From List	${value}	6

    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_old_state}    ${expected_old_state}
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_new_state}    ${expected_new_state}
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_spb_category}    ${buy_more_high_level_spb_category}
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_psm_kind}    BUY_MORE
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_billing_account}    ${expected_billing_account_id}
    \  Run Keyword And Continue On Failure    Should Be Equal    ${kind}    BUY_MORE
    \  Run Keyword And Continue On Failure    Should Be Equal As Strings    ${received_pi_file_location}    ${expected_pi_file_location}


Validate Values From PSM Event
    [Documentation]     validate old state, new state, spb category, psm kind and billing account and spb:file location id in that sequence of the list
    [Arguments]   ${pid_mapping}    ${product_instance_id}    ${expected_old_state}      ${expected_new_state}    ${expected_billing_account_id}    ${expected_pi_file_location}
    :FOR  ${key}  IN  @{pid_mapping.keys()}
    \  ${value}  get from dictionary  ${pid_mapping}  ${key}
    \  ${kind}    Get From List	${value}	5
    \  ${received_old_state} 	Get From List	${value}	0
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_old_state}    ${expected_old_state}
    \  ${received_new_state} 	Get From List	${value}	1
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_new_state}    ${expected_new_state}
    \  ${received_billing_account} 	Get From List	${value}	4
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_billing_account}    ${expected_billing_account_id}
    \  ${received_spb_category} 	Get From List	${value}	2
    \  ${received_psm_kind} 	Get From List	${value}	3
    \  ${received_pi_file_location} 	Get From List	${value}	6
    \  Run Keyword And Continue On Failure    Should Be Equal As Strings    ${received_pi_file_location}    ${expected_pi_file_location}
    \   Run Keyword If   '${key}' == '${product_instance_id}'
    \   ...   Run Keyword And Continue On Failure      Should Be Equal    ${received_spb_category}    ${high_level_spb_category}
    \   ...   ELSE
    \   ...   Run Keywords
    \   ...   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == '${CONTRACT_KIND}'    Should Be Equal    ${received_spb_category}    ${contract_spb_price_category}    AND
    \   ...   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == '${DISCOUNT_KIND}'    Should Be Equal    ${received_spb_category}    ${discount_spb_price_category}   AND
    \   ...   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == '${CONTRACT_KIND}'    Should Be Equal    ${received_psm_kind}    BILLING   AND
    \   ...   Run Keyword And Continue On Failure    Run Keyword If    '${kind}' == '${DISCOUNT_KIND}'    Should Be Equal    ${received_psm_kind}    BILLING
    \  Run Keyword If    '${key}' == '${product_instance_id}'
    \  ...    Run Keyword And Continue On Failure    Should Be Equal    ${received_psm_kind}    ${INTERNET_KIND}

Validate Values From PSM Fulfillment Events
    [Documentation]     validate old state, new state, spb category, psm kind and billing account and spb:file location id in that sequence of the list
    [Arguments]   ${pid_mapping}    ${expected_old_state}      ${expected_new_state}    ${expected_billing_account_id}    ${expected_pi_file_location}
    :FOR  ${key}  IN  @{pid_mapping.keys()}
    \  ${value}  get from dictionary  ${pid_mapping}  ${key}
    \  ${received_old_state} 	Get From List	${value}	0
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_old_state}    ${expected_old_state}
    \  ${received_new_state} 	Get From List	${value}	1
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_new_state}    ${expected_new_state}
    \  ${received_billing_account} 	Get From List	${value}	4
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_billing_account}    ${expected_billing_account_id}
    \  ${received_spb_category} 	Get From List	${value}	2
    \  ${received_psm_kind} 	Get From List	${value}	3
    \  ${received_pi_file_location} 	Get From List	${value}	6
    \  Run Keyword And Continue On Failure    Should Be Equal As Strings    ${received_pi_file_location}    ${expected_pi_file_location}   received pi file location not equal to expected
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_psm_kind}     ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][FULFILLMENT_KIND]   product instance kind does not equal fulfillment kind
    \  Run Keyword And Continue On Failure    Should Be Equal    ${received_spb_category}    ${high_level_spb_category}    received fulfillment spb category does not equal expected
    
Log PSM SNS Events
    [Documentation]     keeps on polling messages until get a successful message
    #[Arguments]   ${product_instance_id}
    ${attri}    getqueueattributes    ${psm_queue_name}
    Log    Queue attri are: ${attri}
    Wait Until Keyword Succeeds    480s    2s    Get & Log PSM SNS Messages Temp

Get & Log PSM SNS Messages Temp
    [Documentation]     gets and logs message for given product instance id
    ${status}    readAndLogAndDeleteMessagePSM   ${psm_queue_name}
    Should Be True    ${status}

Get PSM SNS Messages With Active State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}    @{product_instance_ids}  
    ${status}    ${pid_mapping}    ${message}    readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   ACTIVATING    ACTIVE   ${pid_mapping}    @{product_instance_ids}
    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}     Not all 3 events (top level, contract, discount) found in PSM SNS
    [return]    ${pid_mapping}    ${message}

Get PSM SNS Messages With Suspended State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}    @{product_instance_ids}
    ${status}    ${pid_mapping}    ${message}    readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   SUSPENDING    SUSPENDED   ${pid_mapping}   @{product_instance_ids}
    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}     Not all 3 events (top level, contract, discount) found in PSM SNS
    [return]    ${pid_mapping}    ${message}

Get PSM SNS Messages With Deactivated State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}    @{product_instance_ids}
    ${status}    ${pid_mapping}    ${message}    readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   DEACTIVATING    DEACTIVATED   ${pid_mapping}   @{product_instance_ids}
    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}     Not all 3 events (top level, contract, discount) found in PSM SNS
    [return]    ${pid_mapping}    ${message}

Get PSM SNS Messages With Resumed State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}    @{product_instance_ids}
    ${status}    ${pid_mapping}    ${message}    readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   REACTIVATING    ACTIVE   ${pid_mapping}   @{product_instance_ids}
    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}     Not all 3 events (top level, contract, discount) found in PSM SNS
    [return]    ${pid_mapping}    ${message}


Get PSM SNS Messages With Canceled State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}    @{product_instance_ids}
    ${status}    ${pid_mapping}    ${message}    readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   CANCELING    CANCELED   ${pid_mapping}   @{product_instance_ids}
    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}     Not all 3 events (top level, contract, discount) found in PSM SNS
    [return]    ${pid_mapping}    ${message}

Get PSM SNS Messages With Accepted State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}     @{product_instance_ids}
    
    ${status}    ${pid_mapping}    ${message}   readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   ACCEPTING    ACCEPTED   ${pid_mapping}   @{product_instance_ids}  

    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}    Not all events found in PSM SNS
    [return]    ${pid_mapping}    ${message}


Get PSM SNS Messages With Given States
    [Documentation]     gets and logs message for given product instance id
    [Arguments]     ${pid_mapping}     ${product_instance_ids}  ${old_state}   ${new_state}
    
    ${status}    ${pid_mapping}    ${message}   readAndDeleteMessagePSMForGivenState   ${psm_queue_name}   ${old_state}     ${new_state}   ${pid_mapping}   @{product_instance_ids}  

    Should Be True    ${status}
    ${received_pids_count}    Get Length    ${pid_mapping}
    ${given_pids_count}    Get Length    ${product_instance_ids}
    Should Be Equal As Strings      ${given_pids_count}    ${received_pids_count}    Not all events found in PSM SNS
    [return]    ${pid_mapping}    ${message}

Delele PSM Queue
    [Documentation]     Deletes the queue
    ${status}   ${repsonse}    deleteSubscription     ${psm_subscription_arn}
    Should Be True    ${status}
    ${status}   ${repsonse}    deleteQueue    ${psm_queue_name}
    Should Be True    ${status}

Create SISM SQS Queue
    [Documentation]     creates a sqs queue to subscribe SISM topic
    ${status}    ${sism_queue_name}    ${sism_subscription_arn}    createQueueAndSubscribe    bepe2etest-sism    ${SISM_SNS_TOPIC}
    Should Be True    ${status}
    Set Suite Variable    ${sism_queue_name}
    Set Suite Variable    ${sism_subscription_arn}
    Log    ${sism_queue_name}

Get & Verify SISM SNS Messages
    [Documentation]     gets and logs message for given product instance id
    [Arguments]    ${product_instance_id}
    ${status}    ${state_type}    ${message}    readAndDeleteMessageSISM    ${sism_queue_name}      ${product_instance_id}
    Should Be True    ${status}
    #${length}    Get Length    ${message}
    #${queue_exausted}    Run Keyword And Return Status    Should Be Equal As Integers    ${length}    0
    #Run Keyword Unless    ${queue_exausted}    Should Contain    ${state_type}    INITIALIZING
    [return]    ${state_type}    ${message}

Get Event From SISM SNS
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]    ${product_instance_id}
    #Set Suite Variable    ${sism_queue_name}     test
    ${attri}    getqueueattributes    ${sism_queue_name}
    Log    Queue attri are: ${attri}
    ${state_type}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get & Verify SISM SNS Messages    ${product_instance_id}
    Should Not Be Empty    ${message}    msg=Iterated through messages in the queue but did not find expcted message
    Should Contain    ${state_type}    PENDING
    [return]    ${state_type}    ${message}

Delele SISM Queue
    [Documentation]     Deletes the queue
    ${status}   ${repsonse}    deleteSubscription     ${sism_subscription_arn}
    Should Be True    ${status}
    ${status}   ${repsonse}    deleteQueue    ${sism_queue_name}
    Should Be True    ${status}
