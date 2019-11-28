
*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     psm_api.py
Variables   psm_parameters.py
Resource    psm_resource.robot
#Suite Setup      Suite Setup
#Suite Teardown   Suite Teardown

*** Variables ***
${PRODUCT_INSTANCE_ID}    745a6dc4-65ba-43b8-97ed-0e2468e660c9
${relationShip_id}     sdfjksdfkwefuiwehksdfsdfjklsdfjkdf100
 
*** Test Cases ***
Get Product Instances
    [Tags]     prdInstId
    ${result}   Get PSM Instance   ${PRODUCT_INSTANCE_ID}
    Log To Console   ${result}

Get PSM Instances By RelnId
    [Tags]     relnId
    ${result}    Get PSM Instance With RelnId    ${relationShip_id}
    Log To Console    ${result}

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    # if global variables not present for IDs, generate them
    Log   Configure suite variables here@
    #ResVNO Smoke 

Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@

    
