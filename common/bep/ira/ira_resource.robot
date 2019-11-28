*** Settings ***
Resource   ../../resource.robot
Resource   ../common/bep_resource.robot
Library    OperatingSystem
Library    Process
Library   ./ira_api.py
Variables         ./ira_parameters.py

*** Keywords ***
Add Individual To IRA
    [Documentation]     Robot keyword to add individual to IRA
    [Arguments]    ${full_name}  ${groups}
    Log To Console    Add individual associated to specific groups ${groups} To IRA Store and get back party_id
    ${status}  ${result}    useIraApi    addIndividual   ${full_name}  ${groups}
    Log Response    ${result}
    Should Be True    ${status}    Error in response of addIndividual ${result}
    ${full_name}=   Set Variable    ${result}[data][addIndividual][fullName]
    ${party_id}=    Set Variable    ${result}[data][addIndividual][partyId]
    ${groups}=  Set Variable    ${result}[data][addIndividual][groups]
    [return]   ${full_name}  ${party_id}  ${groups}
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Update Individual Name
    [Documentation]     Robot keyword to update Individual Name in IRA
    [Arguments]    ${party_id}  ${updated_name}
    Log To Console   Update individual Name in IRA 
    ${status}  ${result}    useIraApi    updateIndividual   ${party_id}  ${updated_name}
    Log Response    ${result}
    Should Be True    ${status}
    ${updated_name}    Set Variable    ${result}[data][updateIndividual]
    [return]   ${updated_name}

Add Payer Role To Party
    [Arguments]    ${party_id}  ${reln_id}
    Log To Console    Add Payer Role To Party In IRA
    ${status}  ${result}    useIraApi    addPayerRole   ${party_id}  ${reln_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${party_role_id}    Set Variable  ${result}[data][addPayerRole][partyRoleId]
    [return]    ${party_role_id}

Add Email Contact Method To Party
    [Documentation]     Robot keyword to add Email Contact in IRA
    [Arguments]    ${party_id}  ${email_address}
    Log To Console   Add email address to Party defined in IRA
    ${status}  ${result}    useIraApi    addEmailContactMethod   ${party_id}  ${email_address}
    Log Response    ${result}
    Should Be True    ${status}
    ${email}    Set Variable    ${result}[data][addEmailContactMethod][email]
    [return]   ${email}

Add Phone Contact Method To Party
    [Documentation]     Robot keyword to add Phone Contact to Party in IRA
    [Arguments]    ${party_id}  ${phone_number}
    Log To Console   Add Phone Number to Party defined in IRA
    ${status}  ${result}    useIraApi    addPhoneContactMethod   ${party_id}  ${phone_number}
    Log Response    ${result}
    Should Be True    ${status}
    ${phone_number}    Set Variable    ${result}[data][addPhoneContactMethod]
    [return]   ${phone_number}

Add Address Contact Method To Party
    [Documentation]     Robot keyword to add Address to Party in IRA
    [Arguments]    ${party_id}  ${address_lines}  ${municipality}  ${region}  ${postal_code}  ${country_code}
    Log To Console   Add Address to Party defined in IRA
    ${status}  ${result}    useIraApi    addAddressContactMethod   ${party_id}  ${address_lines}  ${municipality}  ${region}  ${postal_code}  ${country_code}
    Log Response    ${result}
    Should Be True    ${status}
    ${address}    Set Variable    ${result}[data][addAddressContactMethod]
    [return]   ${address}

Add Customer Relationship To Party
    [Documentation]     Robot keyword to add Customer Relationship to Party in IRA
    [Arguments]    ${party_id}  ${organisation_group}  ${organisation_id}
    Log To Console   Add Customer Relationship to Party defined in IRA
    ${status}  ${result}    useIraApi    addCustomerRelationship   ${party_id}  ${organisation_group}  ${organisation_id}
    Should Be True    ${status}
    Log Response    ${result}
    ${reln_id}    Set Variable    ${result}[data][addCustomerReln][relnId]
    ${reln_rev_ver}    Set Variable    ${result}[data][addCustomerReln][version]
    [return]   ${reln_id}  ${reln_rev_ver}

Add Customer Info To IRA
    [Documentation]     Robot keyword to add Customer info to Party in IRA
    [Arguments]    ${party_id}   ${email}    ${billing_address}  ${PHONE_NUMBER}
    ${external_id_type_name}   ${external_id_value}        Run Keyword If    "${COUNTRY_CODE}" == '${MX}'    Generate External Id For Mexico
    ...    ELSE    Set And Get IRA External Id
    Log     ${party_id}, ${email}, ${address_line}, ${city}, ${state}, ${POSTAL_CODE}, ${COUNTRY_CODE}, ${PHONE_NUMBER}, ${external_id_type_name}, ${external_id_value}, ${GROUPS}, ${SELLER_ID}
    ${status}  ${result}    useIraApi    addCustomerInfo    ${party_id}   ${email}   ${billing_address}[addressLine]   ${billing_address}[municipality]   ${billing_address}[region]
    ...   ${billing_address}[postalCode]   ${billing_address}[countryCode]   ${PHONE_NUMBER}   ${external_id_type_name}   ${external_id_value}    ${GROUPS}    ${SELLER_ID}

    Should Be True    ${status}    Failed adding customer info in IRA ${result}
    Log Response    ${result}
    [return]   ${result}
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Fatal Error

Add And Get Customer Info To IRA
    [Documentation]     Robot keyword to add Customer info to Party in IRA
    [Arguments]    ${party_id}   ${email}    ${address_line}    ${city}   ${state}   ${POSTAL_CODE}   ${PHONE_NUMBER}
    ${response}    Add Customer Info To IRA    ${party_id}   ${email}    ${billing_address}   ${PHONE_NUMBER}
    ${returned_email}=   Set Variable    ${response}[data][id1][email]
    ${returned_address}=   Set Variable    ${response}[data][id2][address]
    ${returned_phone_number}=   Set Variable    ${response}[data][id3][phoneNumber]
    ${tin_external_id}=   Set Variable    ${response}[data][id4][value]
    ${reln_id}=   Set Variable    ${response}[data][id5][relnId]
    [return]   ${returned_email}  ${returned_address}  ${returned_phone_number}  ${tin_external_id}  ${reln_id}

Generate External Id For Mexico
    [Documentation]     Robot keyword to Generate External Id For Mexico
    # [A-Z]{3,4}[0-9]{6}[A-Z0-9]{3}
    ${value1}   Generate Random String  4  [LETTERS]
    ${value1}    Convert To Uppercase   ${value1}
    ${value2}   Generate Random String  9  [NUMBERS]
    ${random_value}  Set Variable  ${value1}${value2}
    [return]   ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]    ${random_value}

Generate External Id For Spain TIN
    [Documentation]     Robot keyword to Generate External Id For Spain TIN
    ${value1}    Generate Random String  8  [NUMBERS]
    ${value2}    Generate Random String  1  [LETTERS]
    ${value2}    Convert To Uppercase    ${value2}
	${value}    Set Variable    ${value1}${value2}
    [return]   ${value}

Get Party From IRA
    [Documentation]     Robot keyword to get All Party Related Information in IRA
    [Arguments]    ${party_id}
    Log To Console   Retrieve All Party Related Information in IRA
    ${status}  ${result}    useIraApi    getParty   ${party_id}
    #Should Be True    ${status}
    Log Response    ${result}
    ${full_name}     Set Variable  ${result}[data][getParty][fullName]
    ${party_id}      Set Variable  ${result}[data][getParty][partyId]
    ${groups}    Set Variable  ${result}[data][getParty][groups]
    ${version}       Set Variable  ${result}[data][getParty][version]
    Log many    ${full_name}  ${party_id}  ${groups}
    [return]   ${full_name}  ${party_id}  ${groups}  ${version}

Get Relationship From IRA
    [Documentation]     Robot keyword to get Relationship Information in IRA
    [Arguments]    ${relationship_id}
    Log To Console   Retrieve All Party Related Information in IRA
    ${status}  ${result}    useIraApi    getRelationship   ${relationship_id}
    Log To Console    ${result}  
    Should Be True    ${status}

    ${roles}    Set Variable  ${result}[data][getRelationship][roles]
    ${reln_version}    Set Variable  ${result}[data][getRelationship][version]
    ${reln_id}    Set Variable  ${result}[data][getRelationship][relnId]
    ${groups}    Set Variable  ${result}[data][getRelationship][groups]
    [return]    ${roles}  ${reln_version}  ${reln_id}  ${groups}
    
Get Party From Relationship Id
    [Documentation]     Robot keyword to get Relationship Information in IRA
    [Arguments]    ${relationship_id}   ${role_type}
    Log To Console   Retrieve All Party Related Information in IRA
    ${status}  ${result}    useIraApi    getRelationship   ${relationship_id}
    Log To Console    ${result}  
    Should Be True    ${status}
    ${roles}   Set Variable   ${result}[data][getRelationship][roles]
    ${desired_role}  Set Variable
    :FOR   ${role}  IN  @{roles}
    \    Run Keyword If   '${role}[__typename]'!='${role_type}'    Continue For Loop
    \    ${desired_role}   Set Variable   ${role}
    [return]    ${desired_role}     

Get PartyRoleId From Relationship for Typename
    [Documentation]     Robot keyword to get partyRoleId for type_name that could be either Customer, Payer or Seller Role
    [Arguments]    ${relationship_id}    ${type_name}
    ${status}  ${result}    useIraApi    getRelationship   ${relationship_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${roles}    Set Variable  ${result}[data][getRelationship][roles]
    #${stdout}    convertJsonToDictionary    ${roles}
    :FOR    ${ELEMENT}    IN    @{roles}
    \    ${key_type_name}    Get From Dictionary    ${ELEMENT}    __typename
    \    ${status}  ${message}=  Run Keyword And Ignore Error  Should Be Equal   ${type_name}  ${key_type_name}
    \    ${partyRoleId}    Get From Dictionary    ${ELEMENT}    partyRoleId     
    \    Exit For Loop If  '${status}'=='PASS'
    Should Not Be Empty    ${partyRoleId}
    [return]    ${partyRoleId}

Get Address Info Of Party
    [Documentation]     Robot keyword to get Address Information of a Party
    [Arguments]    ${party_id}
    ${status}  ${result}    useIraApi    getAddressContactMethodFromParty   ${party_id}
    #Log To Console    ${result}
    Log Response    ${result}
    Should Be True    ${status}
    ${full_address}    Set Variable  ${result}[data][getParty][contactMethods]
    [return]   ${full_address}

Get Phone Info Of Party
    [Documentation]     Robot keyword to get Phone Information of a Party
    [Arguments]    ${party_id}
    ${status}  ${result}    useIraApi    getPhoneContactMethodFromParty   ${party_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${phone_number}    Set Variable  ${result}[data][getParty][contactMethods]
    [return]   ${phone_number}

Get Email Info Of Party
    [Documentation]     Robot keyword to get Email Information of a Party
    [Arguments]    ${party_id}
    ${status}  ${result}    useIraApi    getEmailContactMethodFromParty   ${party_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${email}    Set Variable    ${result}[data][getParty][contactMethods]
    [return]   ${email}

Get Email Contact Method Id From Party
    [Documentation]    Get Contact Method Id for email From Party Id
    [Arguments]    ${party_id}
    ${email_info}    Get Email Info Of Party    ${party_id}
    :FOR    ${contact_method}    IN   @{email_info}
    \   ${not_empty_dict}    Run Keyword And Return Status    Should Not Be Empty    ${contact_method}
    \   ${value}	 Run Keyword If    ${not_empty_dict}    Get From Dictionary	${contact_method}	email
    \   ${email_exists}    Run Keyword And Return Status    Should Not Be Equal  ${value}   ${None}
    \   ${contact_method_id}	 Run Keyword If    ${email_exists}    Get From Dictionary	${contact_method}	contactMethodId
    \   Run Keyword If    ${email_exists}    Exit For Loop
    [return]   ${contact_method_id}

Get Phone Contact Method Id From Party
    [Documentation]    Get Contact Method Id for phone From Party Id
    [Arguments]    ${party_id}
    ${phone_info}    Get Phone Info Of Party    ${party_id}
    :FOR    ${contact_method}    IN   @{phone_info}
    \   ${not_empty_dict}    Run Keyword And Return Status    Should Not Be Empty    ${contact_method}
    \   ${value}	 Run Keyword If    ${not_empty_dict}    Get From Dictionary	${contact_method}	phoneNumber
    \   ${phone_exists}    Run Keyword And Return Status    Should Not Be Equal  ${value}   ${None}
    \   ${contact_method_id}	 Run Keyword If    ${phone_exists}    Get From Dictionary	${contact_method}	contactMethodId
    \   Run Keyword If    ${phone_exists}    Exit For Loop
    [return]   ${contact_method_id}

Get Address Contact Method Id From Party
    [Documentation]    Get Contact Method Id for address From Party Id
    [Arguments]    ${party_id}
    ${address_info}    Get Address Info Of Party    ${party_id}
    :FOR    ${contact_method}    IN   @{address_info}
    \   ${not_empty_dict}    Run Keyword And Return Status    Should Not Be Empty    ${contact_method}
    \   ${value}	 Run Keyword If    ${not_empty_dict}    Get From Dictionary	${contact_method}	address
    \   ${address_exists}    Run Keyword And Return Status    Should Not Be Equal  ${value}   ${None}
    \   ${contact_method_id}	 Run Keyword If    ${address_exists}    Get From Dictionary	${contact_method}	contactMethodId
    \   Run Keyword If    ${address_exists}    Exit For Loop
    [return]   ${contact_method_id}

Get Party Version
    [Documentation]     Robot keyword to get Party Version
    [Arguments]    ${party_id}
    ${status}  ${result}    useIraApi    getPartyVersion   ${party_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${version}    Set Variable    ${result}[data][getParty][version]
    [return]   ${version}

Get Party From External Id
    [Documentation]     Robot keyword to get part by external id
    [Arguments]    ${external_id}    ${type_name}
    ${status}  ${result}    useIraApi    getPartyByExternalId   ${external_id}    ${type_name}
    Log Response    ${result}
    Should Be True    ${status}
    ${party_id}    Run Keyword And Continue On Failure    Set Variable  ${result}[data][getPartyByExternalId][partyId]
    ${groups}    Run Keyword And Continue On Failure    Set Variable  ${result}[data][getPartyByExternalId][groups]
    Log    Party Id and groups are: ${party_id} ${groups}
    [return]    ${party_id}  ${groups}

Add External Id Of Party
    [Documentation]     Robot keyword to add external id of party
    [Arguments]    ${party_id}    ${type_name}    ${value}
    ${status}  ${result}    useIraApi    addExternalId   ${party_id}    ${type_name}    ${value}
    #${result}    Evaluate    type($result)
	Log Response    ${result}
    Log To Console   status code = ${result}
    Should Be True    ${status}
    ${response}=   Set Variable    ${result}[data][addExternalId]
    ${external_id}    Get From Dictionary    ${response}    value
	Log To Console    External ID: ${external_id}
    [return]    ${external_id}

Add Spain Tax Identifier
    [Documentation]     Robot keyword to add external id of type TIN for Spain to the party
    [Arguments]    ${party_id}     ${value}
    ${external_id}    Add External Id Of Party    ${partyId}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]    ${value}
    [return]    ${external_id}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][TIN]

Add Spain VAT
    [Documentation]    Robot keyword to add an external id of type VAT for Spain to the party
    [Arguments]    ${party_id}    ${value}
    ${external_id}    Add External Id Of Party    ${partyId}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][VAT]    ${value}
    [return]    ${external_id}    ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][VAT]

Add Norway Tax Identifier
    [Documentation]     Robot keyword to add external id of type TIN for Norway to the party
    [Arguments]    ${party_id}     ${value}
    ${external_id}    Add External Id Of Party    ${partyId}    ${IRA_NOR_TIN}    ${value}
    [return]    ${external_id}     ${IRA_NOR_TIN}

Add Norway VAT
    [Documentation]    Robot keyword to add an external id of type VAT for Norway to the party
    [Arguments]    ${party_id}    ${value}
    ${external_id}    Add External Id Of Party    ${partyId}    ${IRA_EUR_VAT_TYPE}    ${value}
    [return]    ${external_id}    ${IRA_EUR_VAT_TYPE}

Add Poland Tax Identifier
    [Documentation]     Robot keyword to add external id of type TIN for Poland to the party
    [Arguments]    ${party_id}     ${value}
    ${external_id}    Add External Id Of Party    ${partyId}    ${IRA_POL_TIN}    ${value}
    [return]    ${external_id}    ${IRA_POL_TIN}

Add Poland VAT
    [Documentation]    Robot keyword to add an external id of type VAT for Poland to the party
    [Arguments]    ${party_id}    ${value}
    ${external_id}    Add External Id Of Party    ${partyId}    ${IRA_EUR_VAT_TYPE}    ${value}
    [return]    ${external_id}    ${IRA_EUR_VAT_TYPE}

Delete Contact Method
    [Documentation]     Robot keyword to delet contact method
    [Arguments]    ${contact_method_id}
    ${status}  ${result}    useIraApi    deleteContactMethod   ${contact_method_id}
    Log Response    ${result}
    Should Be True    ${status}
    ${status2}    Run Keyword And Continue On Failure    Set Variable  ${result}[data][deleteContactMethod]
    Should Be True    ${status2}

Delete Email Contact Method
    [Documentation]     Robot keyword to delet contact method for email
    [Arguments]    ${party_id}
    ${contact_method_id}    Get Email Contact Method Id From Party    ${party_id}
    Delete Contact Method    ${contact_method_id}

Delete Phone Contact Method
    [Documentation]     Robot keyword to delet contact method for email
    [Arguments]    ${party_id}
    ${contact_method_id}    Get Phone Contact Method Id From Party    ${party_id}
    Delete Contact Method    ${contact_method_id}

Delete Address Contact Method
    [Documentation]     Robot keyword to delet contact method for email
    [Arguments]    ${party_id}
    ${contact_method_id}    Get Address Contact Method Id From Party    ${party_id}
    Delete Contact Method    ${contact_method_id}
    
Locate IRA Party By Phone Number
    [Documentation]   Returns all parties with given phone number. Returned structure {partyId1:{reln1{role:party role id},reln2{role:party role id},...},partyId2{...}}
    ...   Example:
    ...   {'277dfdff-d4a3-48cb-9a42-b1c5a04023b3': {'3ed2ce5d-b827-4814-96ab-aa5534fd084b': {'CustomerRole': 'f00607c8-6859-4852-9994-a09bf5722960',
    ...   'PayerRole': '6d9998c1-b22a-4748-b9cf-06677d6816c6'}}, '7035c741-c155-40e0-8ffb-65fdac300051': {'fb681fb5-e0ba-4eca-b820-18d62168d15d': {'CustomerRole':
    ...   '9d9e0624-83be-49a4-819d-c638909074da', 'PayerRole': '363b24f8-963f-407d-acd7-50612f11a6ec'}}}
    ...    The phone number (+5231241656 in this case) is associated with two party Ids, 277dfdff-d4a3-48cb-9a42-b1c5a04023b3 and 7035c741-c155-40e0-8ffb-65fdac300051.
    ...    Each one of the parties has both a payer role and a customer role in a single relationship.
    [Arguments]   ${phone_number}
    ${status}  ${result}    useIraApi    locatePartyByPhoneNumber   ${phone_number} 
    Should Be True    ${status}
    [return]   ${result}