*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Resource    ../common/bep/om/om_resource.robot
Resource    ../common/bep/fo/fo_resource.robot
Resource    ../common/bep/ira/ira_resource.robot
Resource    ../common/bep/psm/psm_resource.robot
Resource    ../common/bep/pom/pomresource.robot
Resource    ../common/bep/spb/spb_resource.robot
Resource    ../common/vps/vps_resource.robot
Variables   ../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***
${cust_reln_id}      904f6804-7db5-4bea-af17-7b557f5ec684
${delete_contact_keyword}       Delete Phone Contact Method
${add_contact_keyword}    Add Phone Contact Method To Party
${new_value}         +559196078963

*** Test Cases ***

Modify Party Information
    [Documentation]  Given a relationship id, get party id of either a payer or customer and modify contact info
    [Tags]    IRA
    ${role}    Get Party From Relationship Id     ${cust_reln_id}   CustomerRole
    Should Not Be Empty   ${role}   CustomerRole not available
    ${party_id}  Set Variable   ${role}[party][partyId]
    Run Keyword    ${delete_contact_keyword}   ${party_id}
    ${new_contact}   Run Keyword    ${add_contact_keyword}  ${party_id}  ${new_value}
    ${contact_values}   Get Dictionary Values   ${new_contact}
    Should Be Equal  ${contact_values}[0]   ${new_value}

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    Set Country Specific Variables

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@


