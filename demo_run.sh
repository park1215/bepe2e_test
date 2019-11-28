#!/bin/sh
MAC=$(sed 's/^.*_\(.\{2\}:.\{2\}:.\{2\}:.\{2\}:.\{2\}:.\{2\}\)$/\1/' <<< $1)
if [[ $1 == *"SB2"* ]]; then
  modem_type=SB2
  elif [[ $1 == *"AB"* ]]; then
    modem_type=AB
fi
echo $MAC
echo $2
echo $3
echo $4
echo $5
echo $modem_type
command="robot -x x_output.xml -l log_sprint$7.html -v modem_mac_colon:$MAC -v modem_type:$modem_type -v modem_ip:$2 -v service_plan:"$3" -v ext_sys_id:"$4" -v cpe_ip:$5 $6 demo/demo_sprint$7.robot"
echo $command
robot -x x_output.xml -l log_sprint$7.html -v modem_mac_colon:$MAC -v modem_type:$modem_type -v modem_ip:$2 -v service_plan:"$3" -v ext_sys_id:"$4" -v cpe_ip:$5 $6 demo/demo_sprint$7.robot
