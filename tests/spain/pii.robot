*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Library     ../python_libs/bep_common.py
Resource    ../common/bep/spb/spb_resource.robot
Resource    ../common/resource.robot
Variables   ../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***


*** Test Cases ***
Verify Billing PII
    [Documentation]   Obtain payer-related information as per example below, then locate in IRA's billing PII file to verify information is correct. Also need to verify that
    ...   info is updated when contact info is updated.
 #['BA', '7690007b-272a-44cc-9f3e-0c3f2ba57898', 'sktest 9111904', 'Ctra. Villena 88', 'Herrera de Pisuerga', '', 'Palencia', 'Spain', '34400', '+341231231234', 'sktest9111904@gmail.com', '', 'K8738473K', '']   
    #${expected_entry}   Create Dictionary    payer_role_id=7690007b-272a-44cc-9f3e-0c3f2ba57898  name=sktest 9111904  address=Ctra. Villena 88  city=Herrera de Pisuerga  locality=${NULL}
    #...   state=Palencia   country=Spain  postal_code=34400  phone_number=+341231231234  email_address=sktest9111904@gmail.com   company_name=${NULL}   tin=K8738473K  vat=${EMPTY}
    #${expected_entry}   Create Dictionary    payer_role_id=33499df6-4103-4a3b-9ff3-2b951703906c  name=Zyvgaxpq Pmkblkic  address=Ctra. Villena 44  city=Herrera de Pisuerga  locality=${EMPTY}
    #...   state=CL   country=Spain  postal_code=34400  phone_number=+559196078953  email_address=sprint_user@viasat.com   company_name=${EMPTY}   tin=72286048X  vat=${EMPTY}    
    ${expected_entry}   Create Dictionary    payer_role_id=43fc3f0b-9659-4a19-beab-9bb83e0c1591  name=Pagsxtnq Avoffxay  address=Calle de Jacometrezo 46  city=Madrid  locality=${EMPTY}
    ...   state=MA   country=Spain  postal_code=28013  phone_number=+559196078953  email_address=sprint_user@viasat.com   company_name=${EMPTY}   tin=20356719Y  vat=${EMPTY}    
    Verify IRA PII Entry   ${expected_entry} 

Verify Service Location PII
    [Documentation]   Obtain service location-related information as per example below, then locate in PSM's service location PII file to verify information is correct.
    #${expected_entry}   Create Dictionary    payer_role_id=43fc3f0b-9659-4a19-beab-9bb83e0c1591  name=Pagsxtnq Avoffxay  address=Calle de Jacometrezo 46  city=Madrid  locality=${EMPTY}
    #...   state=MA   country=Spain  postal_code=28013  phone_number=+559196078953  email_address=sprint_user@viasat.com
    ${expected_entry}   Create Dictionary   product_instance_id=3af7bd69-9e90-43d4-b7e7-7887ff73372f  name=BEP Nexus Sprint#3 Customer  address=Tendillas Square 2  city=Cordoba  locality=${EMPTY}
    ...   state=Cordoba   country=ES  postal_code=14002  phone_number=+559196078953  email_address=sprint_user@viasat.com
    Verify PSM PII Entry   ${expected_entry}
    
*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log   Configure suite variables here@
    
Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@


    

