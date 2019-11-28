# Written By: ASD & JK
# Last Updated On: 12/18/2018
# Version: 1.3.7
# Summary: BOOM
# Documentation File:

:delay 15s
/ip address add address=10.86.155.56 netmask=255.255.255.0 interface=ether5;
/ip route add dst-address=10.86.155.0/24 gateway=10.86.155.1
/ip route add dst-address=172.30.168.0/24 gateway=10.86.155.1
/ip route add dst-address=10.43.164.0/24 gateway=10.86.155.1

