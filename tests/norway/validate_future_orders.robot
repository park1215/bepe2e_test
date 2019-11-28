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
${buyer_id}

*** Test Cases ***
Validate Previously Generated Future Orders
    [Documentation]  The future orders are generated by "generate_future_order.robot" suite. This suite reads the orders from bucket and validates orders are processesed.
    [Tags]     future-order
    Set Test Variable    ${CONTRACT_TERM}   12
    Set Test Variable    ${validation_status}   ${False}
    @{future_orders}    Read Files From S3 Bucket
    : FOR    ${order_detail}    IN    @{future_orders}
    \   Read File Contents   ${order_detail}
    \   ${order_id}    ${order_timestamp}    ${order_State} =	Split String	${order_detail}    _
    \   ${current_time}    ${order_timestamp_withoffset}    getCurrentIsoDatetimeAndOffeset    ${order_timestamp}
    \   Run Keyword If    '${current_time}' > '${order_timestamp_withoffset}' and '${order_State}' == 'Scheduled'    Run Keyword And Continue On Failure    Validate Orders Are Processed In OM SPB NC   ${order_id}
    \   Log   ${validation_status}
    \   Run Keyword If   ${validation_status}   Delete File From S3 Bucket    ${order_detail}

*** Keywords ***
Suite Setup
    [Documentation]   Configure suite variables
    Log     ${COUNTRY_CODE}
    Set Country Specific Variables
    ${result}    Get OM Version
    Log    OM Preprod Version: ${result}
    ${result}    Get SPB Version
    Log    SPB Preprod Version: ${result}
    ${result}    usePomApi  getVersion
    Log    OFM Preprod Version: ${result}
    
Suite Teardown
    [Documentation]  Restore all resources to original state
    Log   Configure suite variables here@

Validate Orders Are Processed In OM SPB NC
    [Arguments]    ${order_id}
    ${om_result}    Get OM Order    ${order_id}
    ${offer_name}    ${offer_id}    Parse Product Name And Product Type Id From OM    ${om_result}
    Verify Order State Is Processed     ${order_id}
    ${product_instance_id}    Parse Top Level Product Instance Id From OM    ${om_result}

    #Set Test Variable    ${product_instance_id}    ba0c8542-107f-4306-834e-8353c9533c3f

    #${spb_result}    Validate Product Status In SPB    ${product_instance_id}    PENDING
    #${billing_account}    Parse Billing Account From Get PI Response    ${spb_result}
    ${billing_account}    Parse SPB Billing Account From OM    ${om_result}
    ${recurring_payment_method}    Get Payment Method Type From Get Billing Account   ${billing_account}

    #${subscription_id}  ${nc_customer_ref}   Run Keyword And Continue On Failure    Get And Validate Product Instance Ids From SPB     ${product_instance_id}    PENDING    ${billing_account}
    Set Test Variable      ${subscription_id}   None
    Set Test Variable      ${nc_customer_ref}   None

    ${high_level_spb_category}    Get SPB Price Category For Main Product From PSM    ${product_instance_id}
  
    ${subproducts}   Set Variable  ${COUNTRY_VARIABLES}[${COUNTRY_CODE}][SUBPRODUCTS]
    ${pid_dict}   Create Dictionary
    Set Suite Variable  ${pid_dict}
    :FOR  ${kind}  IN  @{subproducts.keys()}
    \   Run Keyword   Get Requested Product Instance Id From PSM   ${product_instance_id}  ${kind}
    \   Validate PSM State Of Product  ${pid_dict}[${kind}]    ACCEPTED
    
    Validate PSM State Of Product    ${product_instance_id}    ACCEPTED

    ${nc_ids}   Run Keyword  Get Product Id And Tariff Id For Generic Main Product  ${offer_name}
    Log    ${nc_ids}
    @{product_instance_ids}    Get And Validate All Product Instance Ids From PSM    ${product_instance_id}   ${billing_account}   ${child_prod_kinds}

    #  ${nc_ids}  has product_id and tariff_id, ${spb_price_dict} has xxx_spb_price_category, KIND variables are in country_variables
    ${product_pid_mapping}   Create Generic PID Mapping For Main And Subproducts  ${billing_account}  ${subscription_id}  ${nc_customer_ref}   ${product_instance_id}
    ...   ${high_level_spb_category}  ${nc_ids}   ${spb_price_dict}
    Log     ${product_pid_mapping}

    #Verify Products From NC DB    ${billing_account}   ${product_pid_mapping}   PE   10
    Validate Payment Method Id In NC DB   ${billing_account}    ${recurring_payment_method}
    [Teardown]     Run Keyword If  '${KEYWORD_STATUS}'=='FAIL'    Set Test Variable    ${validation_status}   ${False}   ELSE   Set Test Variable    ${validation_status}   ${True}

Read File Contents
    [Arguments]   ${filename}
    ${s3}  s3.useS3Bucket   ${OM_FUTURE_ORDERS_BUCKET}[${COUNTRY_CODE}]
    ${result}   Call Method  ${s3}   readFileFromBucket   ${filename}
    ${contents_length}   Get Length  ${result}[1]
    Should Be Equal As Strings  ${result}[0]   True   Could not open future order file in S3 bucket:${result}[1]
    Run Keyword If  ${contents_length}>0   Parse S3 File  ${result}[1]

Parse S3 File
    [Arguments]  ${contents}
    ${entries}   Create List   spb_price_dict   high_level_spb_category   contract_spb_price_category
    ${content_dict}   Evaluate   json.loads('''${contents}''')   json
    ${status}  ${message}  Run Keyword And Ignore Error   Dictionary Should Contain Key  ${content_dict}   spb_price_dict
    Run Keyword If  '${status}'=='PASS'  Set Suite Variable  ${spb_price_dict}  ${content_dict}[spb_price_dict]
    ${status}  ${message}  Run Keyword And Ignore Error   Dictionary Should Contain Key  ${content_dict}   high_level_spb_category
    Run Keyword If  '${status}'=='PASS'  Set Suite Variable  ${high_level_spb_category}  ${content_dict}[high_level_spb_category]    
    ${status}  ${message}  Run Keyword And Ignore Error   Dictionary Should Contain Key  ${content_dict}   contract_spb_price_category
    Run Keyword If  '${status}'=='PASS'  Set Suite Variable  ${contract_spb_price_category}  ${content_dict}[contract_spb_price_category]    