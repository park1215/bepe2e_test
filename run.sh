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
echo $modem_type
command="robot -v modem_mac_colon:$MAC -v service_plan:"$2" -v cpe_ip:"$3" -v modem_type:$modem_type $4 -x demo_out.xml demo/demo_provision_verify.robot"
echo $command
robot -v modem_mac_colon:$MAC -v service_plan:"$2" -v cpe_ip:"$3" -v modem_type:$modem_type $4 -x demo_out.xml demo/demo_provision_verify.robot
