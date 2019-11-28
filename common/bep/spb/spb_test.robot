*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Resource    ../spb/spb_resource.robot

*** Comments ***
Usage : robot --console VERBOSE -v full_name:'BEPTEST Azeem Customer 1' --exitonfailure ira.robot

*** Variables ***
${party_id}            ""
${groups}              AcceptanceTesting
${mex_org_id}          fe34ee49-6198-44b0-a96a-baa39bf59175
${full_name}           "BEPTEST Azeem Customer 1"
${newFullName}         "BEPE2E TEST 1"
${email}               bepe2e_april_30-1@viasat.io
${phoneNumber}         +559196078953
${addressLines}        [349 Inverness Dr S, Building D11, Office 3060]
${municipality}        Englewood
${region}              Colorado
${postalCode}          80112
${countryCode}         US
${buyer_id}           2
${customer_id}         5
${HL_P_ID}    "b457ab6a-d11d-4028-8e7a-7d05f80602d5"
${EQ_P_ID}    "50f5b97c-159a-446f-9dc0-020a7dfde0d4"
${BD}   31
${COUNTRY_CODE}   ES

*** Test Cases ***
Bill Date
    ${BD}   Get Current Date   UTC   result_format=%d
    Verify Next Bill Date  5000013650  ${BD}
*** comments ***   
Subproducts
    ${result}   Get Subproduct From Netcracker By SubId   10   OK   5000011773
    Log   ${result}
    ${result}   Get Subproduct From Netcracker By Name   SERVICE_CONTRACT   OK   5000011773
    Log   ${result}
 
Get Something
    ${result}   Get SPB Instance   caec3e85-b8dd-4fce-a2d3-513e0dbde580
    Log To Console  ${result}

*** Comments ***
Upsert PI in SPB
    ${status}    Upsert to SPB    ${HL_P_ID}    ${EQ_P_ID}    ${buyer_id}    ${customer_id}

Get NC Account Number
    ${nc_account_number}    ${customer_payer_map_id}     Get NC Account & Customer Payer Map Id From Postgres    5    2
    Log    NAC account is ${nc_account_number}    WARN
    Set Suite Variable     ${nc_account_number}
    #Log   customer payer map id is  ${customer_payer_map_id}     WARN

Get NC Customer Reference Number
    ${nc_customer_ref_number}    Get Customer Ref From NC DB    ${nc_account_number}
    Log    CUSTOMER REF # Is:${nc_customer_ref_number}      WARN


Upsert PI in SPB
    [Documentation]    Presuming Mexico Sales Channel, create a new party in IRA with certain Name & Group Association
    [Tags]    add_individual    ira
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${full_name}    ${groups}
    Log To Console    ${party_id}
