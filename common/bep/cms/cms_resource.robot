*** Settings ***
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Library    OperatingSystem
Library    Process
Library   ./cms_api.py
Library   ./cms_postgres_db.py
Library   ./sertifi_api.py
Variables         ./cms_parameters.py

*** Keywords ***
Create CMS SQS Queue
    [Documentation]     creates a sqs queue to subscribe CMS topic
    ${status}    ${cms_queue_name}    ${cms_subscription_arn}    createQueueAndSubscribe    bepe2etest-cms    ${CMS_SNS_TOPIC}
    Should Be True    ${status}
    Set Suite Variable    ${cms_queue_name}
    Set Suite Variable    ${cms_subscription_arn}
    Log    ${cms_queue_name}

Delete CMS Queue
    [Documentation]     Deletes the queue
    ${status}   ${repsonse}    deleteSubscription     ${cms_subscription_arn}
    Should Be True    ${status}
    ${status}   ${repsonse}    deleteQueue    ${cms_queue_name}
    Should Be True    ${status}

Create Contract Instance
    [Documentation]     Robot keyword to get contract instance
    [Arguments]     ${contract_instance_id}    ${customer_id}   ${first_name}   ${last_name}    ${phone}   ${email}   ${addressline1}   ${addressline2}
    ${status}  ${result}    useCmsApi    createContractInstance   ${contract_instance_id}    ${customer_id}    ${first_name}   ${last_name}    ${phone}   ${email}   ${addressline1}   ${addressline2}   ${CONTRACT_TEMPLATE_ID}   ${INVITE_SIGNER}
    Should Be True    ${status}
    Log Response    ${result}
    Set Test Variable   ${contract_instance_id}   ${result}[data][createContractInstance]
    [return]    ${contract_instance_id}

Get Contract Instance
    [Documentation]     Robot keyword to get contract instance
    [Arguments]    ${contract_instance_id}
    ${status}  ${result}    useCmsApi    getContractInstance  ${contract_instance_id}
    Should Be True    ${status}
    Log Response    ${result}
    [return]    ${result}

Verify Signed Status
    [Documentation]     Robot keyword to Verify Signed Status and returns sign url
    [Arguments]    ${result}    ${expected_status}
    Set Test Variable   ${signer_url}   ${result}[data][getContractInstance][signerUrl]
    Set Test Variable   ${signed_status}   ${result}[data][getContractInstance][signedStatus]
    Should Be Equal As Strings   ${expected_status}    ${signed_status}
    [return]    ${signer_url}

Get And Verify CMS DB Entry
    [Documentation]     Gets and validates the signed status with given expected state
    [Arguments]   ${contract_instance_id}    ${customer_id}    ${expected_signed_status}
    ${signed_status}    ${cms_file_id}    ${cms_pdf_id}    Get CMS DB Entry    ${contract_instance_id}    ${customer_id}
    Log   Signed Status in databse: ${signed_status}
    Should Be Equal As Strings   ${signed_status}    ${expected_signed_status}
    [return]     ${cms_file_id}    ${cms_pdf_id}

Wait For CMS DB Update For Contract Instance
    [Documentation]     wait until db updates the signed status with given expected state
    [Arguments]   ${contract_instance_id}    ${customer_id}    ${expected_signed_status}
    ${cms_file_id}    ${cms_pdf_id}    Wait Until Keyword Succeeds     10s    2s    Get And Verify CMS DB Entry   ${contract_instance_id}    ${customer_id}    ${expected_signed_status}
    [return]     ${cms_file_id}    ${cms_pdf_id}

Get CMS DB Entry
    [Documentation]     Robot keyword to Get CMS DB Entry
    [Arguments]    ${contract_instance_id}    ${customer_id}
    Log    ${contract_instance_id} ${customer_id}
    ${status}    ${row}    useCmsPgApi    getCustomerAgreementInfo    ${contract_instance_id}     ${customer_id}
    Should Be True    ${status}
    Log    ${row}
    Set Test Variable   ${signed_status}   ${row}[3]
    Set Test Variable   ${cms_file_id}   ${row}[4]
    Set Test Variable   ${cms_pdf_id}   ${row}[5]
    [return]     ${signed_status}    ${cms_file_id}    ${cms_pdf_id}

Get And Verify Contract Instance
    [Arguments]   ${contract_instance_id}
    ${result}    Get Contract Instance    ${contract_instance_id}
    ${signer_url}    Verify Signed Status    ${result}    False
    [return]     ${signer_url}

Add Signature With Sertifi API
    [Documentation]     Robot keyword to apply signutre via sertifi API
    [Arguments]    ${cms_file_id}     ${cms_pdf_id}    ${first_name}     ${last_name}    ${email}
    ${status}    ${result}    useSertifiApi    applySignatureAndParseRespose    ${SERTIFI_API_CODE}    ${cms_file_id}     ${cms_pdf_id}    ${first_name}     ${last_name}    ${email}
    Should Be True    ${status}
    Should Contain    ${result}    SUCCESS
    Log    ${result}

Get And Verify Event From CMS SNS
    [Documentation]     keeps on polling messages until get a successful message
    [Arguments]    ${contract_instance_id}    ${expected_signed_state}
    ${attri}    getqueueattributes    ${cms_queue_name}
    Log    Queue attri are: ${attri}
    ${signed_status}    ${message}    Wait Until Keyword Succeeds    60s    2s    Get CMS SNS Messages For Given State    ${contract_instance_id}
    Should Not Be Empty    ${message}    msg=Iterated through messages in the queue but did not find expcted message
    Should Contain    ${signed_status}    ${expected_signed_state}
    [return]    ${signed_status}    ${message}

Get CMS SNS Messages For Given State
    [Documentation]     gets and logs message for given product instance id
    [Arguments]    ${contract_instance_id}
    ${status}    ${signed_status}    ${message}    readAndDeleteMessageCMSWithState    ${cms_queue_name}      ${contract_instance_id}
    Should Be True    ${status}
    [return]   ${signed_status}    ${message}

Verify Email Received To Sign
    [Documentation]  get email of signing from s3 bucket
    [Arguments]       ${first_name}    ${last_name}
    ${file}    ${content}    Wait Until Keyword Succeeds     40s    5s    Fetch Email From S3 Bucket     ${first_name}    ${last_name}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][CMS_EMAIL_TEXT_BEFORE_SIGN]
    Log    ${content}

Verify Email Received For Signed Confirmation
    [Documentation]  Verify Email Received For Signed Confirmation
    [Arguments]       ${first_name}    ${last_name}
    ${file}    ${content}    Wait Until Keyword Succeeds     90s    5s    Fetch Email From S3 Bucket     ${first_name}    ${last_name}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][CMS_EMAIL_TEXT_AFTER_SIGN]
    Log    ${content}
    deleteEmailFile     ${BEPTEST_EMAIL_BUCKET}    ${file}

Fetch Email From S3 Bucket
    [Documentation]  Fetch Email From S3 Bucket, parse it based on text, full name
    [Arguments]       ${first_name}    ${last_name}    ${email_text}
    ${status}    ${file}   ${content}    getAndReadFilesFromEmailBucket    ${BEPTEST_EMAIL_BUCKET}    ${email_text}   ${first_name}    ${last_name}
    Should Be True    ${status}
    Log    ${content}
    deleteEmailFile     ${BEPTEST_EMAIL_BUCKET}    ${file}
    [return]   ${file}    ${content}
