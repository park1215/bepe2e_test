*** Settings ***
Documentation    Runs test cases listed in ${input_filename}, a csv file. First row has parameter names. The test case name must be in the column "test." It is a
...   shortened version  of the name and is a key to the actual name found in the ${test_case_names} dictionary. The test case will extract the remaining parameters from
...   that row in the csv file
...    Example:
...         test,account,start bill date
...         new_account,5000011773,9182019
...         prepay,5000011698,10182019
...    This csv file lists 2 tests, abbreviated names being "new_account" and "prepay." The account for the new_account test is 5000011773, and start bill date is 9182019
...    The name "new_account" maps to the test case "Run New Account Through End Of Discount"

Library     dynamic_testcases
Library     DateTime
Library     String
Library     OperatingSystem
Library     Collections
Library     bep_common

Suite setup    Suite Setup

*** Variables ***

&{test_case_names}=      new_account=Run New Account Through End Of Discount     prepay=Run Billing After Prepayment
${input_filename}    billing.csv

*** Test Cases ***
Dummy
    [Documentation]    Required for dynamic test case generation to work. Can be removed in post-processing
    Log To Console   dummy test case

*** Keywords ***
Suite Setup
    [Documentation]   Dynamically generates test cases listed in ${input_filename}
    File Should Exist   ${input_filename}   input file ${input_filename} does not exist
    ${test_cases}   Get Test Case List From Billing File
    # each entry in ${test_cases} contains the test case name (shortened) and the parameters required for that test to run
    Set Suite Variable   ${test_cases}
    Log To Console   test cases = ${test_cases}
    
    :FOR    ${test}    IN    @{test_cases}
    \     Add test case    ${test}[test]
    \     ...              ${test}[test]

##### Test Case keywords - each keyword composes one test case ##### 

Run New Account Through End Of Discount
    Log To Console   test=${TEST NAME}
    Get Test Parameters   ${TEST NAME}
    Log To Console  params=${params}
    
Run Billing After Prepayment
    Log To Console   test=${TEST NAME}
    Get Test Parameters   ${TEST NAME}
    Log To Console  params=${params}
     
##### End of Test Case keywords #####    

Get Test Case List From Billing File
    [Documentation]   Converts contents of csv file to a list of dictionaries, with keys being in the first row of the csv file
    ${input}   Get File   ${input_filename}
    
    # if input ends with newline, remove it
    ${input}   Remove String Using Regexp  ${input}   ${\n}\$
 
    # convert rows to lists
    @{delimiter_list}   Create List   \n   ,
    @{output_list}  Create List
    @{input_list}   Create List   ${input}
    @{test_descriptions}   convertStringToList    ${input_list}  ${delimiter_list}  0   ${output_list}

    # remove header row to use as dictionary keys
    ${columns}   Remove From List  ${test_descriptions}   0
    @{test_list}   Create List

    :FOR  ${row}  IN   @{test_descriptions}
    \       Log To Console  ${row}
    \       &{test_description}   Create Test Description   ${columns}  ${row}
    \       Append To List  ${test_list}  ${test_description}
    [return]   ${test_list}
    
Create Test Description
    [Documentation]   Given list of variable names and list of variable values, return dictionary
    [Arguments]   ${names}   ${values}
    &{test_description}   Create Dictionary
    ${items}   Get Length   ${names}
    :FOR   ${i}  IN RANGE   0   ${items}
    \    ${value}   Set Variable   ${values}[${i}]
    \    Set To Dictionary  ${test_description}   ${names}[${i}]=${value}
    \    Run Keyword If    '${names}[${i}]'=='test'     Set To Dictionary  ${test_description}   ${names}[${i}]=${test_case_names}[${value}]
    [return]   ${test_description}
    
Get Test Parameters
    [Documentation]   Using ${test_cases} list, find entry with provided test case name and save that entry in ${params}
    [Arguments]   ${test_name}
    ${tests_len}   Get Length   ${test_cases}
    :FOR   ${i}  IN RANGE   0   ${tests_len} 
    \    Run Keyword If   '${test_cases[${i}]}[test]'=='${test_name}'    Set Test Variable   ${params}   ${test_cases[${i}]}
    \    Run Keyword If   '${test_cases[${i}]}[test]'=='${test_name}'    Exit For Loop  
    Remove From List  ${test_cases}   ${i}

    
    