*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Library     ../python_libs/bep_common.py
Resource    ../common/bep/om/om_resource.robot
Resource    ../common/bep/spb/spb_resource.robot
Resource    ../common/vps/vps_resource.robot
Resource    ../common/bep/ira/ira_resource.robot
Resource    ../common/resource.robot
Variables   ../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***

${index_37_payment_request_id}   1356

*** Test Cases ***
Submit Recurring Payment Request To SPB
    [Tags]   submit
    ${customers}   Create Dictionary
    
    &{cust_ref_mx1}   Create Dictionary   pr_mandate=3404aed6-2e57-4e2e-a457-67d91040d019   cust_ref=5000000776   type=CC
    &{cust_ref_mx2}   Create Dictionary   pr_mandate=498fc98a-0c76-4f22-8cf0-e69e0b21947d   cust_ref=5000000780   type=CC
    @{cust_ref_mx}   Create List    ${cust_ref_mx1}   ${cust_ref_mx2}


    # mastercard
    &{cust_ref_es1}   Create Dictionary   pr_mandate=c7983fde-d0ee-447d-87a3-8d1544ba2251   cust_ref=5000001287   type=CC
    &{cust_ref_es3}   Create Dictionary   pr_mandate=e73f549e-a198-4496-a827-a12cf83e5963   cust_ref=5000001307   type=SEPA
    @{cust_ref_es}   Create List    ${cust_ref_es1}   ${cust_ref_es3}
    
    &{cust_ref_no1}    Create Dictionary  pr_mandate=2b5c1a2d-d211-4b8f-aeef-0c2e88a63635   cust_ref=5000013921  type=CC
    &{cust_ref_no2}    Create Dictionary  pr_mandate=2b5c1a2d-d211-4b8f-aeef-0c2e88a63635   cust_ref=5000013906  type=CC
    @{cust_ref_no}   Create List    ${cust_ref_no1}   ${cust_ref_no2} 
    
    Set To Dictionary  ${customers}   MX=${cust_ref_mx}    NO=${cust_ref_no}   ES=${cust_ref_es}
    
    ${customer_ref_list}   Set Variable   ${customers}[${COUNTRY_CODE}]

    ${request_filename}   ${request_file_contents}  Create Payment Request File   ${customer_ref_list}
    
    Create File   ${request_filename}   ${request_file_contents}

    Write File to NC SFTP Server    ${request_filename}

    Set Suite Variable   ${request_filename}
    Log   ${request_filename}  console=True
    Log   ${request_file_contents}  console=True

Verify Payment Request In SPB Database
    [Tags]   submit
    ${spb_db_instance}=   Run Keyword   getSpbDbInstance
    ${status}   ${result}   Wait Until Keyword Succeeds   16x   5s   Query SPB Batch Request Table   ${spb_db_instance}   ${request_filename}

Verify Payment Response in Archive Bucket
    ${prefix}   Set Variable  payments/${BATCH_PAYMENT_REQUEST}[${COUNTRY_CODE}][prefix]_${index_37_payment_request_id}
    ${s3_instance}=   Run Keyword   s3.useS3Bucket   ${S3_ARCHIVE_BUCKET}   ${S3_ARCHIVE_READ_ROLE}
    ${result}   Wait Until Keyword Succeeds   16x   5s    Get Payment Response File   ${prefix}   ${s3_instance}

    :FOR   ${response}   IN   @{result}
    \   ${response}   Convert To List   ${response}
    \   Run Keyword And Continue On Failure   Should Be Equal As Strings   ${response}[3]   0    Transaction ${response}[5] failed with code ${response}[3]
    
*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Set Country Specific Variables
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}    WARN
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}    WARN

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@

Get Payment Response File
    [Documentation]   poll s3 archive bucket for payment response file
    [Arguments]    ${prefix}   ${s3_instance}
    ${response}=    Call method    ${s3_instance}    keyExists   ${prefix}
    Should Be Equal As Strings  ${response}[0]   True   Could not find file ${response}[1][0] in bucket
    ${contents}=    Call method    ${s3_instance}    readFileFromBucket   ${response}[1][0]
    Should Be Equal As Strings  ${contents}[0]   True    Could not read file ${response}[1][0] from bucket
    @{delimiter_list}   Create List   \r\n   ,
    @{inputList}   Create List   ${contents}[1]
    @{outputList}  Create List
    ${content_lists}   bep_common.convertStringToList   ${inputList}  ${delimiter_list}   0   ${outputList}
    Log To Console   ${content_lists}
    [return]  ${content_lists} 
    
Create Payment Request File
    [Documentation]  Create the payment request file that is written to NC SFTP server
    [Arguments]    ${customer_ref_list}
    ${request_filename}   Run Keyword   Create Payment Request Filename   ${BATCH_PAYMENT_REQUEST}[${COUNTRY_CODE}][prefix]_    ${index_37_payment_request_id}
    ${index_37_payment_request_id}  Convert To Integer  ${index_37_payment_request_id}
    # for now create random request # (index 37) - netcracker will not acknowledge however
    # also random amounts
    ${request_file_contents}   Set Variable
    :For    ${cust}    IN    @{customer_ref_list}
    \   Log To Console   cust=${cust}
    \   ${random}=	 Evaluate	random.randint(0,99)   	modules=random
    \   ${index_35_payment_amount}    Evaluate   10000*${random}
    \   Log To Console   payment amount = ${index_35_payment_amount}
    \   ${type_index}   Set Variable  ${cust}[type]
    \   ${index_17_payment_type_id}   Set Variable   ${VPS_PAYMENT_TYPES}[${COUNTRY_CODE}][${type_index}]
    \   ${entry}   Run Keyword   Create Payment Request Entry   ${EXPECTED_CURRENCY_DICT}[alphabeticCode]  ${cust}[cust_ref]  ${cust}[cust_ref]  ${index_17_payment_type_id}   ${cust}[pr_mandate]  ${index_35_payment_amount}  ${index_37_payment_request_id}
    \   ${index_37_payment_request_id}   Evaluate   ${index_37_payment_request_id}+1
    \   ${request_file_contents}   Set Variable   ${request_file_contents}${entry}\n
    ${request_file_contents}   trim   ${request_file_contents}
    [return]   ${request_filename}  ${request_file_contents} 
    

