##############################################################
#
#  File name: fsm_parameters.robot
#
#  Description: Parameters of FSM Keywords
#
#  Author:  pgadekar
#
#  Copyright (c) ViaSat, 2019
#
##############################################################
*** Settings ***

*** Variables ***

${FSM_URL}                            https://fsm4.test.wildblue.net/fsm-fe/users/usersManagement/browseUsers.page?execution=e8s4
${PENDING_COMPLETE_SYSTEMIC}          Pending Complete Systemic
${COMPLETED}                          Completed
${SUCCESSFUL_MESSAGE}                 Order has been updated

####################### FSM GUI Element Locators #############################
${FSM_HOME_ELEMENT}                   id=pass
${FSM_USERNAME_ELEMENT}               id=j_username
${FSM_PASSWORD_ELEMENT}               name=j_password
${LOGIN_ELEMENT}                      id=login_submit
${SEARCH_INPUT_ELEMENT}               id=search:searchInput
${SERACH_ELEMENT}                     id=quickSearchButton
${STATUS_ELEMENT}                     id=basicDataFormId:changeStatusSelectMenu_label
${DATA_FORM_ELEMENT}                  id=basicDataFormId:j_idt481
${DROPDOWN_ELEMENT}                   xpath=//*[@id="basicDataFormId:changeStatusSelectMenu_label"]
${SELECT_COMPLETED_ELEMENT}           xpath=//*[@id="basicDataFormId:changeStatusSelectMenu_panel"]/div/ul/li[4]
${CHANGE_STATUS_ELEMENT}              xpath=//*[@id="basicDataFormId:changeStatusButton"]/span
${MESSAGE_ELEMENT}                    xpath=//*[@id="message"]/div/ul/li/span
${ADD_NOTE_ELEMENT}                   xpath=(//span[@class="ui-button-text"])[7]
