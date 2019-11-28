*** Settings ***
Documentation     A resource file with reusable keywords and variables.
...               The system specific keywords created here form our own
...               domain specific language.
Library           Selenium2Library
Library           OperatingSystem
Library           Process
Library           DateTime
Library           String
Library           Collections
Library           RequestsLibrary
#Library           DependencyLibrary
Library           common_library.py
Library           ../tools/backOfficeProvisioning/backofficeLibrary.py
Library            ../tools/backOfficeProvisioning/backofficeAPI.py
Library            bep/common/aws/sqs.py
Library            bep/common/aws/s3.py
#Library           json
Resource          ssh_library.robot
Resource          modem/modem_resources.robot
Resource          modem/modem_parameters.robot
Variables         ../python_libs/modem_parameters.py
Variables         ../python_libs/bep_parameters.py
Variables         ../python_libs/credentials.py
Resource          cpe/cpe_resource.robot
Resource          cpe/cpe_parameters.robot
Resource          browser.robot
Resource          fsm/fsm_resource.robot
Resource          fsm/fsm_parameters.robot
Resource          resVNO/resVNO_resource.robot
Resource          resVNO/resVNO_parameters.robot
Resource          wifi/ruckus/ruckus_parameters.robot
Resource          wifi/ruckus/ruckus_resource.robot
Resource          wifi/mikrotik/mikrotik_resources.robot
Resource          wifi/mikrotik/mikrotik_parameters.robot
Resource          wifi/wifi_resources.robot
Resource          wifi/wifi_parameters.robot

*** Variables ***


*** Keywords ***
 Run And Log Speed Test
    [Documentation]     Executes the speed test with speedtest-cli git tool and logs the speed test results
    ${stdout}    Execute SSH Command    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -    60 secs
    Log    ${stdout}    WARN

Clear SSH Known Hosts Entry
    [Documentation]    Runs a system AWK command to clear the ssh signature from the running users known_hosts file
    [Arguments]    ${host_ip}
    Run Process   ${FILE_UPLOAD_EXE} [return]  ${result}


Delele All SNS Subscriptions
    [Documentation]     Delele All SNS Subscriptions
    #${subs}    getSubscriptions
    #:FOR    ${sub}    IN    @{subs}
    #\    ${SubscriptionArn}    Get From Dictionary    ${sub}    SubscriptionArn
    #\    ${status}    ${res}    deleteSubscription     ${SubscriptionArn}
    #\    Run Keyword And Continue On Failure    Should Be True    ${status}
    Wait Until Keyword Succeeds    30s    10s    Get And Delete All Subscriptions


Get And Delete All Subscriptions
    ${status}   ${repsonse}    listAndDeleteAllSubscriptions
    Should Be True    ${status}
    ${status}   ${subscription_count}    getTotalSubscriptionCount
    Should Be True    ${status}
    Should Be Equal As Strings   ${subscription_count}    0