*** Settings ***
Library     Collections
Library     String
Library     Process
Library     OperatingSystem
Library     DateTime
Library     ../common/common_library.py
Resource    ../common/bep/om/om_resource.robot
Resource    ../common/bep/spb/spb_resource.robot
Resource    ../common/vps/vps_resource.robot
Resource    ../common/bep/ira/ira_resource.robot
Resource    ../common/bep/common/aws/aws.robot
Variables   ../python_libs/bep_parameters.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown

*** Variables ***


*** Test Cases ***
Read Billing PII
    Get Billing PII   56d44992-7930-4205-a636-fbf5e6a10b2e


*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log   Configure suite variables here@
    
Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@
    


