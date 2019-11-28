*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Library     ../python_libs/jira_lib.py
Resource    ../common/wifi/wifi_resources.robot
Resource    ../common/bep/om/om_resource.robot
Resource    ../common/bep/fo/fo_resource.robot
Resource    ../common/vps/vps_resource.robot
Resource    ../common/bep/spb/spb_resource.robot
Resource    ../common/resource.robot
Variables   ../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
${index_13_customer_ref}        unused1
${index_14_account_num}         unused2
${index_17_payment_method_id}   13
# for now this is a customer relationship id. What will it be in the future?
${index_29_customer_ref}        e55f7db8-651b-4d84-aeb2-f9a97f8fd8e1
${index_35_payment_amount}      1280000
${index_37_payment_request_id}  1006
${batch_payment_request_prefix}  VPGB_MEX_
 
*** Test Cases ***
Test UATX1 VPS
    ${response}   ${vps}   useVpsApi   initialize
    Should Be True  ${response}
    Set Suite Variable  ${vps}
    Set Suite Variable   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Request Payment Transaction Id   ${VPS_REQUEST_PAYMENT_TRANSACTION_ID_DEFAULTS}
    Authorize Payment Method   ${VPS_AUTH_DEFAULTS}
*** comment ***
Submit Recurring Payment Request To SPB
    ${s3_instance}=   Run Keyword   createS3   ${S3_PAYMENT_REQUEST_BUCKET}
    ${request_file_contents}   Run Keyword   Create Payment Request Entry    ${index_13_customer_ref}  ${index_14_account_num}  ${index_17_payment_method_id}  ${index_29_customer_ref}  ${index_35_payment_amount}  ${index_37_payment_request_id}
    ${request_filename}   Run Keyword   Create Payment Request Filename   
    Set Suite Variable   ${request_filename}
    Log To Console   ${request_file_contents}
    Log To Console   ${request_filename}
    ${response}=    Call method    ${s3_instance}    writeToBucket   ${request_file_contents}    ${request_filename}
    Log To Console   ${response}
    
Verify Payment Request In SPB Database
    Log To Console   request filename = ${request_filename}
    ${spb_db_instance}=   Run Keyword   getSpbDbInstance
    ${result}   Wait Until Keyword Succeeds   3x   5s   Query SPB Batch Request Table   ${spb_db_instance}   ${request_filename}
    Log To Console   ${result}
    ${status}   ${message}    Should Not Be Equal   ${result}   Failure   SPB failed to process batch payment request
 
Verify Netcracker Payment Updates 
    
    
 *** comment ***
 
Get Payment Transaction ID
    Request Payment Transaction Id

Get OM Version Invoke
    ${result}   Get OM Version
    Log To Console   ${result}
    ${mac}   generateRandomMacAddress
    Log To Console   ${mac}

Test Case 2
    @{address_lines}   Create List   349 Inverness Drive South
    &{iso_country_code}    Create Dictionary   name=United States  alphabeticThreeCharacterCode=USA
    &{address}   Create Dictionary   addressLine=${address_lines}   city=ENGLEWOOD   regionOrState=CO   isoCountryCode=${iso_country_code}   zipOrPostCode=80112
    &{geoLocationInput}   Create Dictionary   latitude=39.55  longitude=-104.86   significantDigits=5

    @{product_type_ids}   Create List   cee9s0be-6557-3b44-8bfd-534a9692ad6
    ${seller_party_id}    Set Variable   fe34ee49-6198-44b0-a96a-baa39bf59175
    &{dates}  Create Dictionary   from=2019-05-23T00:00:00Z   to=2019-05-30T00:00:00Z
    ${result}   Get Available Install Dates   ${address}   ${geoLocationInput}  ${product_type_ids}   ${seller_party_id}   ${dates}
    Log To Console   ${result}

Test Case 0
    #${result}    Upsert OM Order   order-bcf8   cart-hre   cust-bde   ${None}  {addressLine:"Av. de las Americas 111",addressLine2:"Suite 25",isoCountryCode:{name:"Mexico",alphabeticThreeCharacterCode:"MEX"},city:"San Felipe V Etapa"}
    ${result}    Upsert OM Order   order-bc123   cart-hre   cust-bde   pay-888   ${None}

    Log To Console   ${result}
    #${result}    Get OM Order   order-bcf8
    #Log To Console   ${result}

Test Case 1
    # ${service_instance_id}   ${bep_order_id}   ${cure_configuration_name}   ${bom}   ${customer_id}   ${licensee_details}   ${location_details}
    ${count}  Set Variable   1
    ${count}    Convert To Integer  ${count}
    
    ${time}=   Get Current Date  time_zone=UTC   result_format=epoch   exclude_millis=1
    ${time}   Convert To Integer   ${time}
    ${timestr}    Convert To String  ${time}    
    ${timestr}   Get Substring   ${timestr}   -4
    
    &{bom_entry1}    Create Dictionary   model=MikroTik RB750Gr3   device_type=Controller  count=${count}
    &{bom_entry2}   Create Dictionary   model=Ruckus ZoneFlex T300   device_type=Access Point   count=${count}
    @{bom}   Create List   ${bom_entry1}   ${bom_entry2}
    &{licensee_details}    Create Dictionary   business_name=BEPE2E_Business_${time}
    &{location_details}    Create Dictionary   label=bepe2e_beta_Location_${timestr}   address1=${timestr} Finfeather   address2=c   city=Bryan   state=TX  postal_code=77801  country=US
    ${status}    Create Order   BEPE2E_Service_Id_${time}   BEPE2E_Order_Id_${time}   Cody and Titus Testing   ${bom}
    ...          BEPE2E_Customer_Id_${time}   ${licensee_details}    ${location_details}
    Should Be Equal As Integers   ${status}    204

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log   Configure suite variables here@
    ${response}   ${vps}   useVpsApi   initialize
    Should Be True  ${response}
    Set Suite Variable  ${vps}

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
 
Create Payment Request Filename
    [Documentation]   create a payment request filename that consists solely of a timestamp
    ${time}    Get Current Date   UTC  result_format=datetime
    ${timenew}   Convert Date   ${time}   result_format=%Y%m%d%H%M%S
    [return]   ${request_prefix}${index_37_payment_request_id}_${timenew}_request.txt
    
Create Payment Request Entry
    [Documentation]   create a single csv entry for a payment request from NC to SPB
    [Arguments]   ${index_13_customer_ref}  ${index_14_account_num}  ${index_17_payment_method_id}  ${index_29_customer_ref}  ${index_35_payment_amount}  ${index_37_payment_request_id}
    ${entry}   Set Variable    2.0,MXN,,,,,,,,,,,${index_13_customer_ref},${index_14_account_num},,,${index_17_payment_method_id},,,,,,,,,,,,${index_29_customer_ref},,,,,,${index_35_payment_amount},,${index_37_payment_request_id},,,,,,,
    [return]   ${entry}
 
Query SPB Batch Request Table
    [Documentation]  Query SPB batch request table for provided filenae
    [Arguments]   ${spb_db_instance}   ${filename}
    ${result}  Call Method    ${spb_db_instance}    queryBatchRequestTable   ${filename}
    Log  ${result}
    ${status}   ${message}   Should Not Be Equal   ${result}   ${None}     Payment request missing from SPB database
    ${status}=    Set Variable If   '${result}'!='None'  ${result} 
    [return]  ${status}