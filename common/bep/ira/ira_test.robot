*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Resource    ../common/bep/ira/ira_resource.robot

*** Comments ***
Usage : robot --console VERBOSE -v full_name:'BEPTEST Azeem Customer 1' --exitonfailure ira_test.robot

*** Variables ***
${party_id}            ""
${groups}              AcceptanceTesting
${mex_org_id}          fe34ee49-6198-44b0-a96a-baa39bf59175
${full_name}           BEPTEST Azeem Customer 1
${newFullName}         BEPE2E TEST 1
${email}               bepe2e_april_30-1@viasat.io
${phoneNumber}         +559196078953
${addressLines}        [349 Inverness Dr S, Building D11, Office 3060]
${municipality}        Englewood
${region}              Colorado
${postalCode}          80112
${countryCode}         US
${reln_id}             8c064a89-ede0-4aaf-9fa5-c67f7d6a2a0e
${type_name}           PayerRole
${external_id}           beptest_5fce
${new_type_name}              viasat_my_sso_ldap
${existing_party_id}      43c447f7-7f37-4a97-bf5e-48b268f95fce

*** Test Cases ***
Create New Customer In IRA
    [Documentation]    Presuming Mexico Sales Channel, create a new party in IRA with certain Name & Group Association
    [Tags]    add_individual    ira
    ${full_name}  ${party_id}  ${group_name}    Add Individual To IRA    ${full_name}    ${groups}
    Set Suite Variable    ${party_id}
    Log To Console    ${party_id}

Get Party Information
    [Documentation]    Get Information For a specific Party
    [Tags]    get_party    ira
    ${full_name}  ${party_id}  ${groups}  ${version}    Get Party From IRA    ${party_id}
    #${result}    Get Party Version    ${party_id}
    #${reln_id}  ${reln_rev_ver}    Add Customer Relationship To Party    ${party_id}  ${groups}  ${mex_org_id}
    #${roles}  ${reln_version}  ${reln_id}  ${groups}    Get Relationship From IRA    ${party_id}
    ${value} =  Generate Random String  8  [NUMBERS]
    ${email} =   Catenate    SEPARATOR=  ${value}   @viasat.io
    ${result}    Add Email Contact Method To Party    ${party_id}  ${email}
    ${email_info}    Get Email Info Of Party    ${party_id}
    ${result}    Add Address Contact Method To Party    ${party_id}  ${addressLines}  ${municipality}  ${region}  ${postalCode}  ${countryCode}
    ${address_info}    Get Address Info Of Party    ${party_id}
    ${value} =  Generate Random String  12  [NUMBERS]
    ${phonenumber}    Catenate    SEPARATOR=  +   ${value}
    ${result}    Add Phone Contact Method To Party    ${party_id}  ${phoneNumber}
    ${phone_info}    Get Phone Info Of Party    ${party_id}
    #${result}    Update Individual Name    ${party_id}  ${newFullName}
    #${result}    Get PartyRoleId From Relationship for Typename    ${reln_id}    ${type_name}
    #Log To Console    ${version}
    Log   full name is :${full_name}    WARN
    Log     address ${address_info}   WARN
    Log     phone info is ${phone_info}    WARN
    Log     email info is: ${email_info}    WARN

Delete All Contact Methods
    Run Keyword And Continue On Failure    Delete Email Contact Method    ${party_id}
    Run Keyword And Continue On Failure    Delete Phone Contact Method    ${party_id}
    Run Keyword And Continue On Failure    Delete Address Contact Method    ${party_id}


Add External id Of Party To IRA
    [Documentation]    Get External Id of party
    [Tags]    external_id    ira
    ${value} =  Generate Random String  8  [NUMBERS]
    Log   Value is ${value}    WARN
    ${returned_value}      Add External Id Of Party    ${existing_party_id}    ${new_type_name}    ${value}
    Log    returned_value is:    WARN
    Log    ${returned_value}    WARN

Get Party from External Id
    [Documentation]    Get Party by External Id
    [Tags]    get_party    ira
    ${party_id}  ${groups}    Get Party From External Id    ${external_id}    ${new_type_name}
    Log    Final output is:    WARN
    Log    ${party_id} ${groups}   WARN


Add New Spain TIN To A Party
    [Documentation]     Adds the external id of type TIN for Spain to the party
    [Tags]    spainTin    ira    tin    spain
    ${value1}    Generate Random String  8  [NUMBERS]
    ${value2}    Generate Random String  1  [LETTERS]
    ${value2}    Convert To Uppercase    ${value2}
	${value}    Set Variable    ${value1}${value2}
    ${external_id}    Add Spain Tax Identifier    ${party_id}    ${value}
    #Log    external id is: ${external_id}
        
	
Add New Spain VAT To A Party
    [Documentation]     Adds the external id of type VAT for Spain to the party
    [Tags]    spainVAT    ira    vat    spain
    ${value1}    Set Variable    ES
    ${value2}    Generate Random String  8  [NUMBERS]
    ${value}    Set Variable    ${value1}${value2}
    ${external_id}    Add Spain VAT    ${party_id}    ${value}
    Log    external id is: ${external_id}

Add New Norway TIN To A Party
    [Documentation]     Adds the external id of type TIN for Spain to the party
    [Tags]    norwayTin    ira    tin    norway
    ${value}    Generate Random String  11  [NUMBERS]
    ${external_id}    Add Norway Tax Identifier    ${party_id}    ${value}
    Log    external id is: ${external_id}

Add New Norway VAT To A Party
    [Documentation]     Adds the external id of type VAT for Norway to the party
    [Tags]    norwayVAT    ira    vat    norway
    ${value1}    Set Variable    NO
    ${value2}    Generate Random String  8  [NUMBERS]
    ${value}    Set Variable    ${value1}${value2}
    ${external_id}    Add Norway VAT    ${party_id}    ${value}
    Log    external id is: ${external_id}

Add New Poland TIN To A Party
    [Documentation]     Adds the external id of type TIN for Poland to the party
    [Tags]    polandTIN    ira    tin    poland
    ${value}    Generate Random String  11  [NUMBERS]
    ${external_id}    Add Poland Tax Identifier    ${party_id}    ${value}
    Log    external id is: ${external_id}

Add New Poland VAT To A Party
    [Documentation]     Adds the external id of type VAT for Poland to the party
    [Tags]    polandVAT    ira    vat    poland
    ${value1}    Set Variable    PL
    ${value2}    Generate Random String  8  [NUMBERS]
    ${value}    Set Variable    ${value1}${value2}
    ${external_id}    Add Poland VAT    ${party_id}    ${value}
    Log    external id is: ${external_id}

