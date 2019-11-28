#!/bin/sh
MAC=$(sed 's/^.*_\(.\{2\}:.\{2\}:.\{2\}:.\{2\}:.\{2\}:.\{2\}\)$/\1/' <<< $1)
echo $MAC
command="robot -v modem_mac_colon:$MAC $2 -x demo_deprovision_out.xml demo/demo_disconnect_verify.robot"
echo $command
robot -v modem_mac_colon:$MAC $2 -x demo_deprovision_out.xml demo/demo_disconnect_verify.robot
