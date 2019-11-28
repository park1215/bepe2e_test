*** Settings ***
Documentation     Keywords to access OM API
Library   om_api.py
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Variables         ./om_parameters.py

*** Keywords ***
Get OM Order
    [Documentation]     Get order info specifiied by ${returns} from OM given an order id
    [Arguments]    ${order_id}
    ${status}    ${result}=     useOmApi   getOrder   ${order_id}
    Should be True  ${status}   getOrder to OM response is ${result}
    Log Response    ${result}
    [return]   ${result}

Upsert OM Order
    [Documentation]    Create or update an order in the OM domain. paymentTransactionId, location, expectedCompletionDate, and state are optional but
    ...   should be set to ${None} if not used
    [Arguments]     ${orderId}  ${cartId}  ${customerRelationshipId}  ${location}  ${paymentTransactionId}  ${cart_item_id}=None  ${billing_account}=None  ${expectedCompletionDate}=None   ${contract_id}=None  ${fulfillment_cart_item_id}=None  ${dest_pc_id}=None  ${src_pc_id}=None
    Log   Cart Item is:${cart_item_id}
    Log    billing account is ${billing_account}
    Log    expectedCompletionDate is: ${expectedCompletionDate}
    Log    contract_idis: ${contract_id}
    ${status}   ${message}   ${omExId}  useOmApi   upsertOrder    ${orderId}  ${cartId}  ${customerRelationshipId}  ${location}  ${paymentTransactionId}  ${expectedCompletionDate}  ${cart_item_id}  ${billing_account}   ${contract_id}   ${fulfillment_cart_item_id}  ${dest_pc_id}  ${src_pc_id}
    ${status2}   ${message2}   Should be True  ${status}   upsertOrder to OM response is ${message}
    Run Keyword And Ignore Error    Log Response    ${message}
    Set Suite Variable   ${omExId}
    [return]   ${message}
    #[Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Create And Upsert Order To OM
    [Documentation]    Create or update an order in the OM domain
    [Arguments]     ${reln_id}    ${cart_id}    ${cart_item_id}    ${billing_account_id}    ${execution_date}=None    ${contract_id}=None   ${fulfillment_cart_item_id}=None    ${dest_pc_id}=None   ${src_pc_id}=None   ${is_expected_open}=False
    Log    ${reln_id} ${cart_id} ${cart_item_id} ${billing_account_id} ${execution_date}=None ${fulfillment_cart_item_id}=None ${dest_pc_id}=None ${src_pc_id}=None
    ${om_order_id}    Generate A GUID
    ${om_payment_transaction_id}    Generate A GUID
    
    &{location}   createDictionary  addressLines=${ADDRESS_LINE}  countryCode=${COUNTRY_CODE}  city=${CITY}  zipOrPostCode=${POSTAL_CODE}
    Run Keyword If  '${STATE}'!=''   Set To Dictionary   ${location}  regionOrState=${STATE}
    ${status}   ${msg}   Run Keyword And Ignore Error   Variable Should Exist  ${LATITUDE}
    Run Keyword If  '${status}'=='PASS'   Set To Dictionary  ${location}  latitude=${LATITUDE}  longitude=${LONGITUDE}
    Set Test Variable    ${om_location}    ${location}
    ${result}   Upsert OM Order   ${om_order_id}    ${cart_id}    ${reln_id}   ${om_location}   ${om_payment_transaction_id}   ${cart_item_id}    ${billing_account_id}    ${execution_date}  ${contract_id}   ${fulfillment_cart_item_id}  ${dest_pc_id}  ${src_pc_id}
    Log Response    ${result}
 
    ${result}    Get OM Order   ${om_order_id}
    ${product_instance_id}    Parse Top Level Product Instance Id From OM    ${result}
    Run Keyword And Ignore Error    Should Not Contain    ${product_instance_id}    None
    ${product_type_id}    Run Keyword If    '${is_expected_open}'=='False'    Parse Top Level Product Type Id From OM    ${result}
    ${om_spb_billing_account}    Parse SPB Billing Account From OM    ${result}
    Should Be Equal    ${om_spb_billing_Account}    ${billing_account_id}
    Log   product instance id from OM is: ${product_instance_id}
    ${order_state}    Parse Order State    ${result}
    [return]   ${om_order_id}    ${product_instance_id}    ${product_type_id}   ${order_state}    ${om_payment_transaction_id}   ${execution_date}     ${om_location}

Cancel Order In OM
    [Documentation]    Cancel the previously upserted order
    [Arguments]     ${orderId}
    ${status}   ${message}   useOmApi   cancelOrder    ${orderId}
    Should be True  ${status}   cancelOrder to OM response is ${message}
    Run Keyword And Ignore Error    Log Response    ${message}
    [return]   ${message}
    #[Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Wait For Order To Be Processed
    [Documentation]    wait until order is processed
    [Arguments]     ${order_id}
    Wait Until Keyword Succeeds     10min    5s    Verify Order State Is Processed    ${order_id}

Get Product Instance And Type Id From OM
    [Documentation]    wait For Order To Generate Product Instance Id
    [Arguments]     ${order_id}
    ${result}    Get OM Order   ${order_id}
    ${product_instance_id}    Parse Top Level Product Instance Id From OM    ${result}
    ${product_type_id}   Parse Top Level Product Type Id From OM    ${result}
    Should Contain    ${product_instance_id}   -
    Should Contain    ${product_type_id}    -
    [return]   ${product_instance_id}    ${product_type_id}

Get Orders By Customer Relationship Id
    [Documentation]     Get Orders By Customer Relationship Id
    [Arguments]    ${customer_rel_id}
    ${status}    ${result}=     useOmApi   getOrdersByCustomerRelationshipId   ${customer_rel_id}
    Should be True  ${status}   getOrdersByCustomerRelationshipId to OM response is ${result}
    Log Response    ${result}
    [return]   ${result}

Get And Verify Orders By Customer Relationship Id
    [Documentation]     Get Orders By Customer Relationship Id
    [Arguments]    ${customer_rel_id}    ${expected_order_id}    ${expected_state}   ${expected_execution_date}    ${expected_order_line_item_id}   ${expected_billing_account}  ${expected_payment_transaction_id}  ${expected_service_location}
    ${result}    Get Orders By Customer Relationship Id    ${customer_rel_id}
    Set Test Variable   ${orders}   ${result}[data][getOrdersByCustomerRelationshipId]
    : FOR    ${order}    IN    @{orders}
    \   ${orderId}    Get From Dictionary    ${order}    orderId
    \   Run Keyword If    '${orderId}' == '${expected_order_id}'    Verify Order Details    ${order}    ${expected_state}   ${expected_execution_date}    ${expected_order_line_item_id}   ${expected_billing_account}  ${expected_payment_transaction_id}  ${expected_service_location}
    \   Run Keyword If    '${orderId}' == '${expected_order_id}'    Exit For Loop

Verify Order Details
    [Documentation]    Verify Order Details
    [Arguments]     ${order}    ${expected_state}   ${expected_execution_date}    ${expected_order_line_item_id}   ${expected_billing_account}  ${expected_payment_transaction_id}  ${expected_service_location}
    Set Test Variable   ${received_state}   ${order}[state]
    Run Keyword And Continue On Failure    Should Be Equal As Strings   ${expected_state}    ${received_state}
    Set Test Variable   ${received_execution_date}   ${order}[executionDate]
    Run Keyword And Continue On Failure    Should Be Equal As Strings   ${expected_execution_date}    ${received_execution_date}
    Run Keyword And Continue On Failure    Set Test Variable   ${received_order_line_item_id}   ${order}[orderLines][0][orderLineItemId]
    Run Keyword And Continue On Failure    Should Be Equal As Strings   ${expected_order_line_item_id}    ${received_order_line_item_id}
    Run Keyword And Continue On Failure    Set Test Variable   ${received_billing_account}   ${order}[orderLines][0][characteristics][0][value]
    Run Keyword And Continue On Failure    Should Be Equal As Strings   ${expected_billing_account}    ${received_billing_account}
    Set Test Variable   ${received_payment_transaction_id}   ${order}[paymentTransactionId]
    Run Keyword And Continue On Failure    Should Be Equal As Strings   ${expected_payment_transaction_id}    ${received_payment_transaction_id}
    Set Test Variable   ${received_service_location}   ${order}[serviceLocation]
    ############################# Following removed temporarily until BEPE2E-1191 is fixed ##################
   # Run Keyword And Continue On Failure    Should Be Equal As Strings   ${expected_service_location}    ${received_service_location}

Verify Order State Is Processed
    [Documentation]    Verify Order State Is Processed
    [Arguments]     ${order_id}
    ${result}    Get OM Order    ${order_id}
    ${order_status}    Parse Order State    ${result}
    Should Contain    ${order_status}    Processed

Wait For Order State To Be Updated
    [Documentation]    Wait For Order To Be Canceled
    [Arguments]     ${order_id}   ${expected_state}
    Wait Until Keyword Succeeds     90s    3s    Validate Order State To Given Value    ${order_id}    ${expected_state}

Validate Order State To Given Value
    [Documentation]    Validate Order State To Given Value
    [Arguments]     ${order_id}   ${expected_state}
    ${result}    Get OM Order    ${order_id}
    ${order_state}    Parse Order State    ${result}
    Should be Equal    ${order_state}    ${expected_state}
    Validate Order State in Order Lines    ${result}    ${expected_state}

Wait For Order To Be Canceled
    [Documentation]    Wait For Order To Be Canceled
    [Arguments]     ${orderId}
    Wait Until Keyword Succeeds     90s    3s    Validate Get Order For Cancelled Order    ${order_id}

Validate Get Order For Cancelled Order
    [Documentation]    validate state of order and orderLines is cancelled
    [Arguments]     ${orderId}
    ${result}    Get OM Order    ${orderId}
    ${order_state}    Parse Order State    ${result}
    Should be Equal    ${order_state}    Canceled
    ${order_line_state}    Parse Order Line State    ${result}
    Should be Equal    ${order_line_state}    Canceled

Add Future Order In Bucket
    [Documentation]    Add future order file in bucket
    [Arguments]     ${order_id}    ${order_datetime}    ${order_status}
    ${file_name} =   Catenate    SEPARATOR=_  ${order_id}   ${order_datetime}  ${order_status}
    Create File    ${file_name}
    
    ${s3dict}   Create Dictionary
    ${status}  ${message}   Run Keyword And Ignore Error  Variable Should Exist  ${spb_price_dict}
    Run Keyword If  '${status}'=='PASS'  Set To Dictionary  ${s3dict}  spb_price_dict=${spb_price_dict}
    ${status}  ${message}   Run Keyword And Ignore Error  Variable Should Exist  ${high_level_spb_category}
    Run Keyword If  '${status}'=='PASS'  Set To Dictionary   ${s3dict}  high_level_spb_category=${high_level_spb_category}
    ${status}  ${message}   Run Keyword And Ignore Error  Variable Should Exist  ${contract_spb_price_category}
    Run Keyword If  '${status}'=='PASS'  Set To Dictionary   ${s3dict}  contract_spb_price_category=${contract_spb_price_category}
    ${s3json}  Evaluate  json.dumps(${s3dict})   json
    Append to File  ${file_name}   ${s3json}
    
    ${status}    uploadFile     ${file_name}    ${OM_FUTURE_ORDERS_BUCKET}[${COUNTRY_CODE}]
    Should be True  ${status}
    Remove File    ${file_name}

Read Files From S3 Bucket
    [Documentation]    get all files form future order bucket
    ${status}    ${files}    getFiles     ${OM_FUTURE_ORDERS_BUCKET}[${COUNTRY_CODE}]
    Should be True  ${status}
    [return]   ${files}

Delete File From S3 Bucket
    [Documentation]    Delete File From S3 Bucket
    [Arguments]     ${file_name}
    ${status}    deleteFile     ${OM_FUTURE_ORDERS_BUCKET}[${COUNTRY_CODE}]    ${file_name}
    Should be True  ${status}

Create S3 Bucket For Future Order
    [Documentation]    This is used one time to create a bucket
    ${status}    createNewBucket     ${OM_FUTURE_ORDERS_BUCKET}[${COUNTRY_CODE}]
    Should be True  ${status}

Parse Product Name And Product Type Id From OM
    [Documentation]    Parse Product Name From OM's get Order response
    [Arguments]     ${result}
    Set Test Variable   ${productCandidates}   ${result}[data][getOrder][orderLines][0][productCandidateGraph][productCandidates]
    :FOR    ${productCandidate}    IN    @{productCandidates}
    \    ${productTypeId}    Get From Dictionary    ${productCandidate}    productTypeId
    \    ${product_name}    Get From Dictionary    ${productCandidate}    name
    \    ${kind}    Get From Dictionary    ${productCandidate}    kind
    \    Run Keyword If    '${kind}'=='${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]'    Exit For Loop
    [return]   ${product_name}    ${product_type_id}



Parse Order State
    [Documentation]    Parse Top Level Order State
    [Arguments]     ${result}
    Set Test Variable   ${order_state}   ${result}[data][getOrder][state]
    [return]   ${order_state}

Parse Order Line State
    [Documentation]    Parse Top Level Product Instance Id From OM's get Order response
    [Arguments]     ${result}
    Set Test Variable   ${order_line_state}   ${result}[data][getOrder][orderLines][0][state]
    [return]   ${order_line_state}

Validate Order State in Order Lines
    [Documentation]    Validate Order State in Order Lines
    [Arguments]     ${result}    ${expected_state}
    Set Test Variable   ${orderLines}   ${result}[data][getOrder][orderLines]
    :FOR    ${orderLine}    IN    @{orderLines}
    \    ${state}    Get From Dictionary    ${orderLine}    state
    \   Run Keyword And Continue On Failure   Should be Equal    ${state}    ${expected_state}
    [return]   ${orderLines}

Parse Top Level Product Instance Id From OM
    [Documentation]    Parse Top Level Product Instance Id From OM's get Order response
    [Arguments]     ${result}
    Set Test Variable   ${product_instance_id}   ${result}[data][getOrder][orderLines][0][productInstanceId]
    [return]   ${product_instance_id}

Parse Top Level Product Type Id From OM
    [Documentation]    Parse Top Level Product Type Id From OM's get Order response
    [Arguments]     ${result}
    Set Test Variable   ${productCandidates}   ${result}[data][getOrder][orderLines][0][productCandidateGraph][productCandidates]
    :FOR    ${productCandidate}    IN    @{productCandidates}
    \    ${productTypeId}    Get From Dictionary    ${productCandidate}    productTypeId
    \    ${kind}    Get From Dictionary    ${productCandidate}    kind
    \    Run Keyword If    '${kind}'=='${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SATELLITE_INTERNET_KIND]'    Exit For Loop
    [return]   ${product_type_id}

Parse SPB Billing Account From OM
    [Documentation]    Parse spb's billing account id From OM's get Order response
    [Arguments]     ${result}
    Set Test Variable   ${om_spb_billing_Account}  ${result}[data][getOrder][orderLines][0][characteristics][0][value]
    [return]   ${om_spb_billing_Account}

Get OM Version
    [Documentation]     Get version of OM deployed in preprod environment
    ${result}    useOmApi   getVersion
    [return]     ${result}

Verify Upsert With Fake Cart Id
    [Arguments]    ${ORDER_ID}    ${fake_cart_id}    ${reln_id}   ${om_location}   ${PAYMENT_TRANSACTION_ID}   ${date}
    ${result}   Upsert OM Order   ${ORDER_ID}    ${fake_cart_id}    ${reln_id}   ${om_location}   ${PAYMENT_TRANSACTION_ID}   ${date}
    Log   ${result}
    ${status}   ${message}   Run Keyword And Continue On Failure    Should Contain    ${result}    upsertOrder Failed:   upsertOrder to OM should have failed with fake card id, result=${result}

Verify Upsert With Empty Cart
    [Arguments]    ${ORDER_ID}    ${empty_cart_id}    ${reln_id}   ${om_location}   ${PAYMENT_TRANSACTION_ID}   ${date}
    ${result}   Upsert OM Order   ${ORDER_ID}    ${empty_cart_id}    ${reln_id}   ${om_location}   ${PAYMENT_TRANSACTION_ID}   ${date}
    Log   ${result}
    ${status}   ${message}    Run Keyword And Continue On Failure    Should Contain    ${result}    upsertOrder Failed:    upsertOrder to OM should have failed with empty card id, result=${result}

Verify Upsert With In-Progress Cart
    [Arguments]    ${ORDER_ID}    ${in_progress_cart_id}    ${reln_id}   ${om_location}   ${PAYMENT_TRANSACTION_ID}   ${date}
    ${result}   Upsert OM Order   ${ORDER_ID}    ${in_progress_cart_id}    ${reln_id}   ${om_location}   ${PAYMENT_TRANSACTION_ID}   ${date}
    Log   ${result}
    ${status}   ${message}    Run Keyword And Continue On Failure    Should Contain    ${result}    upsertOrder Failed    upsertOrder to OM should have failed with in progress cart, result=${result}

Get Product Type ID
    [Documentation]   Loop through top level of "products" in upserted order to find product type id corresponding to provided name
    [Arguments]    ${products}   ${name}
    ${productTypeId}   getProductTypeIdByName   ${products}   ${name}
    [return]   ${productTypeId}
    
Get Product Instance ID
    [Documentation]   Loop through top level of product instances to find instance id corresponding to provided product type id
    [Arguments]    ${products}   ${id}
    ${productInstanceId}      getProductInstanceIdByType    ${products}   ${id}
    [return]   ${productInstanceId}

Create OM SQS Queue
    [Documentation]     creates a sqs queue to subscribe OM topic
    ${status}    ${om_queue_name}    ${om_subscription_arn}    createQueueAndSubscribe    bepe2etest-om    ${OM_SNS_TOPIC}
    Should Be True    ${status}
    Set Suite Variable    ${om_queue_name}
    Set Suite Variable    ${om_subscription_arn}
    Log    ${om_queue_name}

Get Event From OM SNS
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]    ${order_id}    ${expected_old_sate}=Open    ${expected_new_sate}=Processed
    #Set Suite Variable    ${om_queue_name}     bepe2e-test-om
    ${attri}    getqueueattributes    ${om_queue_name}
    Log    Queue attri are: ${attri}
    ${start_state}    ${end_state}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get & Verify OM SNS Messages    ${order_id}
    Should Not Be Empty    ${message}    msg=Iterated through messages in the queue but did not find expcted message
    Should Contain    ${start_state}    ${expected_old_sate}
    Should Contain    ${end_state}    ${expected_new_sate}
    [return]    ${start_state}    ${end_state}    ${message}

Get Event From OM SNS For Given State
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]    ${order_id}    ${expected_old_state}   ${expected_end_state}
    ${attri}    getqueueattributes    ${om_queue_name}
    Log    Queue attri are: ${attri}
    ${start_state}    ${end_state}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get & Verify OM SNS Messages For Given State    ${order_id}    ${expected_end_state}
    Should Not Be Empty    ${message}    msg=Iterated through messages in the queue but did not find expcted message
    Should Contain    ${start_state}    ${expected_old_state}
    Should Contain    ${end_state}    ${expected_end_state}
    [return]    ${start_state}    ${end_state}    ${message}

#Get Event From OM SNS For Activating State
#    [Documentation]     keeps on polling messages until get a successful message
 #   [Arguments]    ${order_id}
#    #Set Suite Variable    ${om_queue_name}     bepe2e-test-om
#    ${attri}    getqueueattributes    ${om_queue_name}
#    Log    Queue attri are: ${attri}
#    ${start_state}    ${end_state}    ${message}    Wait Until Keyword Succeeds    480s    2s    Get & Verify OM SNS Messages    ${order_id}
#    Should Not Be Empty    ${message}    msg=Iterated through messages in the queue but did not find expcted message
 #   #Should Contain    ${start_state}    Open
 #   #Should Contain    ${end_state}    Processed
 #   [return]    ${start_state}    ${end_state}    ${message}

Get & Verify OM SNS Messages
    [Documentation]     gets and logs message for given product instance id
    [Arguments]    ${order_id}    ${expected_end_state}=Processed
    ${status}    ${start_state}    ${end_state}    ${message}    readAndDeleteMessageOMWithState    ${om_queue_name}      ${order_id}   ${expected_end_state}
    Should Be True    ${status}
    [return]    ${start_state}    ${end_state}    ${message}

Get & Verify OM SNS Messages For Given State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]    ${order_id}    ${expected_end_state}
    ${status}    ${start_state}    ${end_state}    ${message}    readAndDeleteMessageOMWithState    ${om_queue_name}      ${order_id}   ${expected_end_state}
    Should Be True    ${status}
    [return]    ${start_state}    ${end_state}    ${message}

Delele OM Queue
    [Documentation]     Deletes the queue
    ${status}   ${repsonse}    deleteSubscription     ${om_subscription_arn}
    Should Be True    ${status}
    ${status}   ${repsonse}    deleteQueue    ${om_queue_name}
    Should Be True    ${status}
