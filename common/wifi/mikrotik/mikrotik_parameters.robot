##############################################################
#
#  File name: mikrotik_parameters.robot
#
#  Copyright (c) ViaSat, 2019
#
##############################################################

*** Variables ***
${MIKROTIK_0842_IP}                       10.86.155.56
${MIKROTIK_0932_IP}                       10.86.155.57
${MIKROTIK_0842_NAME}                     0842
${MIKROTIK_0932_NAME}                     0932
${TUNNEL_GATEWAY}                         10.62.192.1
${FILE_TRANSFER_CMD}                      /tool fetch url="https://minio.tngqa.wfs.viasat.io/vwswdacure-qa-certificates/wifi1.viasat.com_2015wifi1.viasat.com.key\?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=JHGjhgJHGSDoiuoiOJlkNbhjGHJGjhg%2F20190328%2F%2Fs3%2Faws4_request&X-Amz-Date=20190328T160540Z&X-Amz-Expires=604800&X-Amz-SignedHeaders=host&X-Amz-Signature=ac23e85f42d4c4629f6e7e74ac455b00757ceb3284079ccb0eaa53fe86f5c3b3" dst-path="/wifi1.viasat.com_wifi1_cert_chain_20180820.crt" mode="https" host="minio.tngqa.wfs.viasat.io" keep-result="yes";:delay 2s; 
