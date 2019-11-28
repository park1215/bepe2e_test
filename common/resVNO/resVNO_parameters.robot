##############################################################
#
#  File name: parameters.robot
#
#  Description: Parameters of All Keywords
#
#  Author:  adingankar/swile
#
#
##############################################################
*** Settings ***
#Resource          wait_and_retry_interval.robot

*** Variables ***

#************************************************************************************************
# RESVNO BO Variables
#************************************************************************************************
${service_plan}                                         Business Unlimited 60
${user}                                                 devteamall
${order_street_address}                                 6155 EL CAMINO REAL
${order_city}                                           CARLSBAD
${order_state}                                          CA
${order_zipcode}                                        92009
${order_country_code}                                   US
#${order_street_address}                                 349 Inverness Dr
#${order_city}                                           Englewood
#${order_state}                                          CO
#${order_zipcode}                                        80112
#${order_country_code}                                   US
${sb_order_street_address}                                 4868 Hwy 21
${sb_order_city}                                           Embarrass
${sb_order_state}                                          MN
${sb_order_zipcode}                                        55732
${sb_order_country_code}                                   USA
#${order_street_address}                                 519 EAST 5TH STREET
#${order_city}                                           South BOSTON
#${order_state}                                          MA
#${order_zipcode}                                        02127
#${order_country_code}                                   US
#${order_street_address}                                 4868 Hwy 21
#${order_city}                                           Embarrass
#${order_state}                                          MN
#${order_zipcode}                                        55732
#${order_country_code}                                   USA
${sales_channel}                                        B2B_PARTNERS
${order_requestor}                                      JHAYDENDSAGENT
${order_sold_by}                                        B2BCCESTARK
${order_entered_by}                                     JHAYDENDSAGENT
${customer_type}                                        EXEDE_BUSINESS
${system_id}                                            WB_DIRECT


########################### Parameters specific to account Transactions ################################
${account_starts_with}                                 BEPE2E%
#${account_starts_with}                                  %8
${plan_to_query}                                        Business%
${no_of_days_active_account}                            5
${transaction_type_name}                                equipmentSwap
${transaction_status_name}                              WORKING
