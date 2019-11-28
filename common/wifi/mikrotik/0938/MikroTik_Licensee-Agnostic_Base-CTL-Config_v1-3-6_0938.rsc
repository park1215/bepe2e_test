# Written By: Greg Bolton
# Last Updated On: 08/23/2018
# Version: 1.3.7
# Summary: This script will configure a MikroTik device to be a full MikroTik Controller, with hotspot.
# Documentation File:

{
# VARIABLES
# Start of user input section.
:global LocNames Test;
:global UserCIDR 21;
:global WANPort ether1;
:global SYSID 260938;
:global VPNPASS aY8IITPQIa6Q;
:global APTypeID 3;
:global StartAccessVLAN 10;
:global MACPreAuthPW Vi@S@tpr3@uth;
:global MGMTIP 10.55.12.33;
:global MGMTCIDR 29;
:global SSID ;
:global 2GChannel ;
:global 5GChannel ;
:global TXPower ;
# End of user input section.
#================================================
#DO NOT CHANGE ANYTHING BELOW THIS LINE!
#================================================

:local HasMGMT false;
:local VLANIDPull;
:local FirstLoc;
:local BoardType [/system routerboard get model];
:local BaseMAC;
:local MSGHWID;
:local MSG;
:global BridgeMAC;
:local FullSYSID;
:local Counter;
:local MGMTNetwork;
:local VPNUp false;
:local CIDRPLACE 16,17,18,19,20,21,22,23,24;
:local SLASH24S 256,128,64,32,16,8,4,2,1;
:local SECOCTCALC;
:local IPSECOCT;
:local IPTHIRDOCTSTART;
:local IPTHIRDOCTEND;
:local NetAddressPull;
:local BridgePortsDone false;
:local AddressPull;
:local FlashStorage false;
:local NamePull;
# USER INPUT VALIDATION
:if ([:typeof $MGMTIP] != "nothing") do={
	:set HasMGMT true;
	:if ([:typeof $MGMTIP] != "ip") do={
		:set MSG "ERROR: The global variable MGMTIP was not set to a valid IP address before running this script. Please fix the error and rerun the script.";
		:log info $MSG;
		:log info "TERMINATING SCRIPT.";
		:put $MSG;
		:put "\r\n";
		:put "TERMINATING SCRIPT.";
		:end;
	};
	:if ([:typeof $MGMTCIDR] != "num" || $MGMTCIDR > 30 || $MGMTCIDR < 16) do={
		:set MSG "ERROR: The global variable MGMTCIDR was not set to a valid CIDR before running this script. Please fix the error and rerun the script.";
		:log info $MSG;
		:log info "TERMINATING SCRIPT.";
		:put $MSG;
		:put "\r\n";
		:put "TERMINATING SCRIPT.";
		:end;
	};
};
:if ([:typeof $StartAccessVLAN] != "nothing" && ([:typeof $StartAccessVLAN] != "num" || $StartAccessVLAN < 2 || $StartAccessVLAN > 4095)) do={
	:set MSG "ERROR: The global variable StartAccessVLAN was not set to a valid VLAN ID before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $SYSID] != "num" || $SYSID > 99999999) do={
	:set MSG "ERROR: The global variable SYSID was not set to a valid TRACKOS System ID before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $UserCIDR] != "num" || $UserCIDR < 16 || $UserCIDR > 24) do={
	:set MSG "ERROR: The global variable UserCIDR was not set to a valid CIDR size before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $VPNPASS] = "nothing") do={
	:set MSG "ERROR: The global variable VPNPASS was not set before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $LocNames] = "nothing") do={
	:set MSG "ERROR: The global variable LocNames was not set before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $APTypeID] != "num") do={
	:set MSG "ERROR: The global variable APTypeID was not set to a valid AP Type ID before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if (($APTypeID = 2 || $APTypeID = 3 || $APTypeID = 4) && [:typeof $StartAccessVLAN] = "nothing") do={
	:set MSG "ERROR: The global variable StartAccessVLAN was not set but is needed for AP Type 2, 3, or 4 before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ($APTypeID = 1) do={
	:if ([/system package get [find where name=wireless] disabled] = no) do={
		:if ([:typeof $SSID] = "nothing") do={
			:set MSG "ERROR: The global variable SSID was not set before running this script. Please fix the error and rerun the script.";
			:log info $MSG;
			:log info "TERMINATING SCRIPT.";
			:put $MSG;
			:put "\r\n";
			:put "TERMINATING SCRIPT.";
			:end;
		};
	} else={
		:set MSG "ERROR: The wireless package was not enabled before running this script. Please fix the error and rerun the script.";
		:log info $MSG;
		:log info "TERMINATING SCRIPT.";
		:put $MSG;
		:put "\r\n";
		:put "TERMINATING SCRIPT.";
		:end;
	};
};
:if ([:typeof $2GChannel] != "nothing" && $2GChannel != 1 && $2GChannel != 6 && $2GChannel != 11 && $2GChannel != 2412 && $2GChannel != 2437 && $2GChannel != 2462) do={
	:set MSG "ERROR: The global variable 2GChannel was not set to a valid wireless channel before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $5GChannel] != "nothing" && $5GChannel != 149 && $5GChannel != 153 && $5GChannel != 157 && $5GChannel != 161 && $5GChannel != 5745 && $5GChannel != 5765 && $5GChannel != 5785 && $5GChannel != 5805 && $5GChannel != 36 && $5GChannel != 5180 && $5GChannel != 40 && $5GChannel != 5200 && $5GChannel != 44 && $5GChannel != 5220 && $5GChannel != 48 && $5GChannel != 5240 && $5GChannel != 52 && $5GChannel != 5260 && $5GChannel != 56 && $5GChannel != 5280 && $5GChannel != 60 && $5GChannel != 5300 && $5GChannel != 64 && $5GChannel != 5320) do={
	:set MSG "ERROR: The global variable 5GChannel was not set to a valid wireless channel before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:typeof $TXPower] != "nothing" && ($TXPower < 1 || $TXPower > 30)) do={
	:set MSG "ERROR: The global variable TXPower was not set to a valid wireless power level before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};
:if ([:len [/interface find where name="$WANPort"]] = 0) do={
	:set MSG "ERROR: The global variable WANPort was not set to a valid interface before running this script. Please fix the error and rerun the script.";
	:log info $MSG;
	:log info "TERMINATING SCRIPT.";
	:put $MSG;
	:put "\r\n";
	:put "TERMINATING SCRIPT.";
	:end;
};

# LOGIC USED THROUGH OUT SCRIPT
:if ([:len $SYSID] = 3) do={
	:set FullSYSID "00000$SYSID";
};
:if ([:len $SYSID] = 4) do={
	:set FullSYSID "0000$SYSID";
};
:if ([:len $SYSID] = 5) do={
	:set FullSYSID "000$SYSID";
};
:if ([:len $SYSID] = 6) do={
	:set FullSYSID "00$SYSID";
};
:if ([:len $SYSID] = 7) do={
	:set FullSYSID "0$SYSID";
};
# DETERMINE IF FILES NEED TO BE STORED IN FLASH
:if ([:len [/file find where name="flash" type=disk]] > 0) do={
	:set FlashStorage true;
};
# SET SYSTEM IDENTITY
:set BaseMAC [/interface ethernet get [find where name=$WANPort] mac-address];
/system identity set name=$BaseMAC;
:set MSGHWID $BaseMAC;

# CREATE LOGGING ACTIONS AND LOGGING
/system logging action set memory memory-lines=800 memory-stop-on-full=no name=memory target=memory;
/system logging action add target=remote bsd-syslog=no name=VIASATSYSLOGV1 remote=63.79.12.165 remote-port=514 src-address=0.0.0.0;
/system logging add action=VIASATSYSLOGV1 disabled=no topics=script,info;

:set MSG "IDENTITY, LOGGING ACTION, AND LOGGING CONFIGURATIONS HAVE BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE BRIDGES
:local MACAddressFunction do={
	:global BridgeMAC;
	:local MACHEX 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F;
	:local MastMACLastCharNum ([:find $MACHEX [:pick [/interface ethernet get 0 value-name=mac-address] 16 17]]);
	:local MastMACSecCharNum ([:find $MACHEX [:pick [/interface ethernet get 0 value-name=mac-address] 15 16]]);
	:local MACFunctionCounter1 0;
	:local MACFunctionCounter2 1;
	:set BridgeMAC ("1".[:pick [/interface ethernet get 0 value-name=mac-address] 1 17]);
	:while ([len [/interface bridge find where mac-address=$BridgeMAC]] > 0) do={
		:set MACFunctionCounter1 ($MACFunctionCounter1 + 1);
		:set MastMACLastCharNum ([:find $MACHEX [:pick [/interface ethernet get 0 value-name=mac-address] 16 17]] + $MACFunctionCounter1);
		:if ($MastMACLastCharNum > 15) do={
			:set MastMACSecCharNum ([:find $MACHEX [:pick [/interface ethernet get 0 value-name=mac-address] 15 16]] + $MACFunctionCounter2);
			:set MastMACLastCharNum ($MastMACLastCharNum - 16);
		};
		:set BridgeMAC ("1".[:pick [/interface ethernet get 0 value-name=mac-address] 1 15].($MACHEX->$MastMACSecCharNum).($MACHEX->$MastMACLastCharNum));
		:if ($MACFunctionCounter1 > 16) do={
			:set MACFunctionCounter2 ($MACFunctionCounter2 + 1);
			:set MACFunctionCounter1 ($MACFunctionCounter1 - 18);
		};
	};
};
:if ($HasMGMT = true) do={
	$MACAddressFunction;
	/interface bridge add name=MGMT_BRIDGE auto-mac=no admin-mac=$BridgeMAC arp=reply-only protocol-mode=none disabled=no comment="VIASAT - MANAGEMENT BRIDGE";
};
:foreach Loc in=$LocNames do={
	$MACAddressFunction;
	/interface bridge add name="$Loc_HS_BRIDGE" auto-mac=no admin-mac=$BridgeMAC arp=enabled protocol-mode=none disabled=no comment="VIASAT - HOTSPOT BRIDGE FOR $Loc";
};

:set MSG "BRIDGE CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE VLAN
:if ([:typeof $StartAccessVLAN] != "nothing") do={
	:foreach Loc in=$LocNames do={
		/interface vlan add name="MGMT_BRIDGE_VLAN_$StartAccessVLAN" arp=enabled vlan-id=$StartAccessVLAN interface=MGMT_BRIDGE disabled=no comment="VIASAT - VLAN $StartAccessVLAN FOR $Loc HOTSPOT BRIDGE";
		:set StartAccessVLAN ($StartAccessVLAN + 1);
	}
	:set MSG "VLAN CREATION FOR HOTSPOTS HAS BEEN COMPLETED.";
	:log info "info hwid=$MSGHWID,msg=$MSG";
	:put $MSG;
};

# SET BASE WLAN
:if ($APTypeID = 1) do={
	:if ([:typeof $2GChannel] = "nothing") do={
		:set 2GChannel auto;
	};
	:if ([:typeof $5GChannel] = "nothing") do={
		:set 5GChannel auto;
	};
	:if ($2GChannel = 1) do={
		:set 2GChannel 2412;
	};
	:if ($2GChannel = 6) do={
		:set 2GChannel 2437;
	};
	:if ($2GChannel = 11) do={
		:set 2GChannel 2462;
	};
	:if ($5GChannel = 36) do={
		:set 5GChannel 5180;
	};
	:if ($5GChannel = 40) do={
		:set 5GChannel 5200;
	};
	:if ($5GChannel = 44) do={
		:set 5GChannel 5220;
	};
	:if ($5GChannel = 48) do={
		:set 5GChannel 5240;
	};
	:if ($5GChannel = 52) do={
		:set 5GChannel 5260;
	};
	:if ($5GChannel = 56) do={
		:set 5GChannel 5280;
	};
	:if ($5GChannel = 60) do={
		:set 5GChannel 5300;
	};
	:if ($5GChannel = 64) do={
		:set 5GChannel 5320;
	};
	:if ($5GChannel = 149) do={
		:set 5GChannel 5745;
	};
	:if ($5GChannel = 153) do={
		:set 5GChannel 5765;
	};
	:if ($5GChannel = 157) do={
		:set 5GChannel 5785;
	};
	:if ($5GChannel = 161) do={
		:set 5GChannel 5805;
	};
	:if ([:typeof $TXPower] = "nothing") do={
		:set TXPower 18;
	};
	:set Counter 1;
	:foreach WLAN in=[/interface wireless find where band~"2"] do={
		/interface wireless set $WLAN band=2ghz-b/g/n bridge-mode=disabled default-forwarding=no disabled=no frequency=$2GChannel mode=ap-bridge name="USER_WLAN_2G_$Counter" ssid=$SSID rate-set=configured wireless-protocol=802.11 wmm-support=enabled rx-chains=0,1 tx-chains=0,1 tx-power-mode=all-rates-fixed tx-power=$TXPower;
		:set Counter ($Counter + 1);
	};
	:set Counter 1;
	:foreach WLAN in=[/interface wireless find where band~"5"] do={
		/interface wireless set $WLAN band=5ghz-a/n bridge-mode=disabled default-forwarding=no disabled=no frequency=$5GChannel mode=ap-bridge name="USER_WLAN_5G_$Counter" ssid=$SSID rate-set=configured wireless-protocol=802.11 wmm-support=enabled rx-chains=0,1 tx-chains=0,1 tx-power-mode=all-rates-fixed tx-power=$TXPower;
		:set Counter ($Counter + 1);
	};
	:set MSG "SETTING BASE WLAN HAS BEEN COMPLETED.";
	:log info "info hwid=$MSGHWID,msg=$MSG";
	:put $MSG;
};

# CREATE VIASAT VPN
/interface l2tp-client add add-default-route=no allow=mschap2 connect-to="phobos.bcs.viasat.io" name="VIASAT_RESTON_VPN" password=$VPNPASS profile=default-encryption user="$FullSYSID" keepalive-timeout=60 comment="L2TP CONNECTION TO VIASAT GBS BCS DMZ 1 VPN SERVER" disabled=no;

:set MSG "VIASAT VPN CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# BRIDGE PORTS ASSIGNMENTS
:if ([:typeof $StartAccessVLAN] != "nothing") do={
	:foreach Loc in=$LocNames do={
		:set VLANIDPull [/interface vlan get [find where comment~"$Loc"] vlan-id];
		/interface bridge port add interface="MGMT_BRIDGE_VLAN_$VLANIDPull" bridge="$Loc_HS_BRIDGE" disabled=no horizon=2;
	};
};
:if ($HasMGMT = true) do={
	:foreach Int in=[/interface ethernet find where name!=$WANPort] do={
		/interface bridge port add interface=[/interface ethernet get $Int name] bridge="MGMT_BRIDGE" horizon=1;
	};
};
:if ($APTypeID = 1) do={
	:if ($LocNames ~ ";") do={
		:set FirstLoc [:pick $LocNames 0 [:find $LocNames ";"]];
	} else={
		:set FirstLoc $LocNames;
	};
	:foreach WLAN in=[/interface wireless find] do={
		/interface bridge port add bridge="$FirstLoc_HS_BRIDGE" disabled=no interface=[/interface wireless get $WLAN name];
	};
};

# Dis-associating ether5 from MGMT_BRIDGE for BEPE2E
/interface bridge port remove numbers=4

:set MSG "BRIDGE PORT ASSIGNMENTS HAVE BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE IP ADDRESSES
:if ($HasMGMT = true) do={
	/ip address add address="$MGMTIP/$MGMTCIDR" comment="VIASAT - BASE IP FOR MGMT BRIDGE" disabled=no interface=MGMT_BRIDGE;
	/ip address add address=192.168.73.1/24 comment="VIASAT - PROVISIONING IP FOR MGMT BRIDGE" disabled=no interface=MGMT_BRIDGE;	
};
:set Counter 1;
:foreach Loc in=$LocNames do={
	:set SECOCTCALC (($Counter - 1) / (256 / ($SLASH24S->[:find $CIDRPLACE $UserCIDR])));
	:set IPSECOCT (40 + $SECOCTCALC);
	:set IPTHIRDOCTSTART ((($SLASH24S->[:find $CIDRPLACE $UserCIDR]) * ($Counter - 1)) - (256 * $SECOCTCALC));
	/ip address add address="10.$IPSECOCT.$IPTHIRDOCTSTART.1/$UserCIDR" comment="VIASAT - BASE IP FOR $Loc HOTSPOT BRIDGE" disabled=no interface="$Loc_HS_BRIDGE";
	:set Counter ($Counter + 1);
};

:set MSG "IP ADDRESS CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE DHCP CLIENT
:if ([:len [/ip dhcp-client find where interface=$WANPort]] = 0) do={
	/ip dhcp-client add interface=$WANPort add-default-route=yes default-route-distance=1 use-peer-dns=no use-peer-ntp=no disabled=no comment="VIASAT - DHCP CLIENT FOR WAN PORT 1";
	:set MSG "DHCP CLIENT ON WAN PORT CREATION HAS BEEN COMPLETED.";
	:log info "info hwid=$MSGHWID,msg=$MSG";
	:put $MSG;
};
# SET MIKROTIK DNS
/ip dns set allow-remote-requests=yes servers=199.204.4.254;

:set MSG "SETING MIKROTIK DNS HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;
# CREATE ROUTES
/ip route add comment="ROUTE ALL TRAFFIC TO VIASAT GBS BCS DMZ 1 OVER THE VIASAT RESTON VPN" distance=1 dst-address=10.62.175.0/25 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
/ip route add comment="VIASAT - VIASAT JUMPBOX OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=63.79.13.2 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
/ip route add comment="VIASAT - COMMAND.NNU.COM OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=63.79.12.165 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
/ip route add comment="VIASAT - SOLO.NNU.COM OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=63.79.12.177 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
/ip route add comment="VIASAT - NNMI OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=199.204.5.44 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
/ip route add comment="VIASAT - TECH RADIUS LOGIN OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=63.79.12.100 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
:if ($APTypeID = 3) do={
	/ip route add comment="VIASAT - RUCKUS VSCG OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=199.204.5.51 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
	/ip route add comment="VIASAT - RUCKUS VSCG OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=199.204.5.52 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
	/ip route add comment="VIASAT - RUCKUS VSCG OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=199.204.5.24/30 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
};
:if ($APTypeID = 4) do={
	/ip route add comment="VIASAT - UNIFI CONTROLLER OVER VIASAT VPN ROUTE" disabled=no distance=1 dst-address=199.204.5.29 gateway="VIASAT_RESTON_VPN" check-gateway=ping;
};
/ip route add comment="ROUTE TRAFFIC TO TITAN PUBLIC OVER THE VIASAT RESTON VPN" disabled=no distance=1 dst-address=65.103.147.140 gateway="VIASAT_RESTON_VPN" check-gateway=ping;

:set MSG "ROUTE CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE IP POOLS
:if ($HasMGMT = true) do={
	/ip pool add name=PROVISIONING_DHCP_POOL ranges=192.168.73.10-192.168.73.254;
};
:set Counter 1;
:foreach Loc in=$LocNames do={
	:set SECOCTCALC (($Counter - 1) / (256 / ($SLASH24S->[:find $CIDRPLACE $UserCIDR])));
	:set IPSECOCT (40 + $SECOCTCALC);
	:set IPTHIRDOCTSTART ((($SLASH24S->[:find $CIDRPLACE $UserCIDR]) * ($Counter - 1)) - (256 * $SECOCTCALC));
	:set IPTHIRDOCTEND ($IPTHIRDOCTSTART + ($SLASH24S->[:find $CIDRPLACE $UserCIDR]) - 1);
	/ip pool add name="$Loc_HS_IP_POOL" ranges="10.$IPSECOCT.$IPTHIRDOCTSTART.20-10.$IPSECOCT.$IPTHIRDOCTEND.254";
	:set Counter ($Counter + 1);
};

:set MSG "IP POOL CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE DHCP SERVIERS
:if ($HasMGMT = true) do={
	/ip dhcp-server add address-pool=PROVISIONING_DHCP_POOL authoritative=yes add-arp=yes disabled=no interface=MGMT_BRIDGE lease-time=1m name=MGMT_DHCP_SERVER;
};
:foreach Loc in=$LocNames do={
	/ip dhcp-server add address-pool="$Loc_HS_IP_POOL" authoritative=yes disabled=no interface="$Loc_HS_BRIDGE" lease-time=1h name="$Loc_HS_DHCP_SERVER";
};

:set MSG "DHCP SERVIER CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE DHCP NETWORKS
:if ($HasMGMT = true) do={
	:set MGMTNetwork [/ip address get [find where comment="VIASAT - BASE IP FOR MGMT BRIDGE"] network];
	/ip dhcp-server network add address="$MGMTNetwork/$MGMTCIDR" gateway=$MGMTIP dns-server=$MGMTIP netmask=$MGMTCIDR comment="VIASAT - BASE DHCP NETWORK FOR MGMT BRIDGE";
	/ip dhcp-server network add address=192.168.73.0/24 netmask=24 comment="VIASAT - PROVISIONING DHCP NETWORK FOR MGMT BRIDGE";
};
:foreach Loc in=$LocNames do={
	:set NetAddressPull [/ip address get [find where interface~"$Loc"] network];
	:set AddressPull [/ip address get [find where interface~"$Loc"] address];
	:set AddressPull [:pick $AddressPull 0 [:find $AddressPull "/"]];
	/ip dhcp-server network add address="$NetAddressPull/$UserCIDR" gateway="$AddressPull" dns-server="199.204.4.254" netmask="$UserCIDR" comment="VIASAT - BASE DHCP NETWORK FOR $Loc HOTSPOT BRIDGE";
};

:set MSG "DHCP NETWORK CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# IMPORT SSL CERTIFICATES FOR HOTSPOT SERVER PROFILE
#:while ($VPNUp = false) do={
#	:if ([:ping 172.16.0.2 count=2] > 0) do={
#		:set VPNUp true;
#	};
#	:delay 2s;
#};
#/tool fetch url="https://titan.bcs.viasat.io/provisioning/ManagedServices/Configuration/Certs/wifi1_cert_chain_20180820.crt" dst-path="wifi1_cert_chain_20180820.crt" mode=https;
#/tool fetch url="https://titan.bcs.viasat.io/provisioning/ManagedServices/Configuration/Certs/2015wifi1.viasat.com.key" dst-path="2015wifi1.viasat.com.key" mode=https;
:delay 1s;
/certificate import passphrase="" file-name="wifi1_cert_chain_20180820.crt";
:delay 1s;
/certificate import passphrase="Nomorewires15" file-name="2015wifi1.viasat.com.key";
:delay 1s;
:foreach FileClean in=[/file find where name~"wifi1_cert_chain_20180820.crt"] do={
	/file remove $FileClean;
};
:foreach FileClean in=[/file find where name~"2015wifi1.viasat.com.key"] do={
	/file remove $FileClean;
};
:set MSG "IMPORTATION OF SSL CERTIFICATES FOR HOTSPOT SERVER PROFILE HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE HOTSPOT PROFILES
:set NamePull [/certificate get [find where private-key=yes crl=yes trusted=yes] name];
/ip hotspot profile add dns-name="WIFI1.VIASAT.COM" hotspot-address=8.37.109.255 login-by=https name=HS_PROFILE radius-interim-update=20m ssl-certificate=$NamePull use-radius=yes;
:if ([:typeof $MACPreAuthPW] != "nothing") do={
	/ip hotspot profile set [/ip hotspot profile find where name=HS_PROFILE] login-by=mac,https,http-pap mac-auth-password=$MACPreAuthPW;
};

:set MSG "HOTSPOT PROFILE CREATION HAVE BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE HOTSPOTS SERVERS
:foreach Loc in=$LocNames do={
	/ip hotspot add addresses-per-mac=unlimited disabled=no idle-timeout=15m interface="$Loc_HS_BRIDGE" login-timeout=1m name="$FullSYSID_$Loc_HS_SERVER" profile=HS_PROFILE;
};

:set MSG "HOTSPOT SERVERS CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# SET HOTSPOT USER PROFILE
/ip hotspot user profile set default idle-timeout=1h !keepalive-timeout shared-users=unlimited;

:set MSG "SETTING HOTSPOT USER PROFILE HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE WALLED GARDEN WHITE LIST
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO NETWORK 199.204.4.0/22 BEFORE LOGGING IN" disabled=no dst-address=199.204.4.0/22;
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO NETWORK 63.79.12.0/23 BEFORE LOGGING IN" disabled=no dst-address=63.79.12.0/23;
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO CRL.ENTRUST.NET BEFORE LOGGING IN" disabled=no dst-host="CRL.ENTRUST.NET";
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO OCSP.ENTRUST.NET BEFORE LOGGING IN" disabled=no dst-host="OCSP.ENTRUST.NET";
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO SSL.GOOGLE-ANALYTICS.COM BEFORE LOGGING IN" disabled=no dst-host="SSL.GOOGLE-ANALYTICS.COM";
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO PROMO.EXEDE.COM BEFORE LOGGING IN" disabled=no dst-host="PROMO.EXEDE.COM";
/ip hotspot walled-garden ip add action=accept comment="VIASAT - ALLOW ACCESS TO PROMO.VIASAT.COM BEFORE LOGGING IN" disabled=no dst-host="PROMO.VIASAT.COM";
/ip hotspot walled-garden add action=allow comment="VIASAT - ALLOW ACCESS TO PAYMENTS.VWS.VIASAT.COM BEFORE LOGGING IN" disabled=no dst-host="PAYMENTS.VWS.VIASAT.COM";
/ip hotspot walled-garden add action=allow comment="VIASAT - ALLOW ACCESS TO PAYMENTS-STATIC.VWS.VIASAT.COM BEFORE LOGGING IN" disabled=no dst-host="PAYMENTS-STATIC.VWS.VIASAT.COM";
/ip hotspot walled-garden add action=allow comment="VIASAT - ALLOW ACCESS TO PAYMENTS - CLOUDFRONT BEFORE LOGGING IN" disabled=no dst-host="d1451j2h8ru1el.cloudfront.net";
/ip hotspot walled-garden add action=allow comment="VIASAT - ALLOW ACCESS TO WIFI1.VIASAT.COM BEFORE LOGGING IN" disabled=no dst-host="WIFI1.VIASAT.COM";
/ip hotspot walled-garden add action=allow comment="VIASAT - ALLOW ACCESS TO REDIR.NNU.COM BEFORE LOGGING IN" disabled=no dst-host="REDIR.NNU.COM";
/ip hotspot walled-garden add action=allow comment="VIASAT - ALLOW ACCESS TO PORTAL.NNU.COM BEFORE LOGGING IN" disabled=no dst-host="PORTAL.NNU.COM";

:set MSG "WALLED GARDEN WHITE LIST CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE STATIC DNS
:if ($APTypeID = 3) do={
	/ip dns static add address=199.204.5.51 name=ruckuscontroller disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.51 name=zonedirector disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.52 name=ruckuscontroller disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.52 name=zonedirector disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.25 name=ruckuscontroller disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.25 name=zonedirector disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.24 name=ruckuscontroller disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	/ip dns static add address=199.204.5.24 name=zonedirector disabled=no comment="VIASAT - DNS TO DIRECT RUCKUS APS TO THE RUCKUS VSCG";
	:set MSG "STATIC DNS CREATION FOR RUCKUS HAS BEEN COMPLETED.";
	:log info "info hwid=$MSGHWID,msg=$MSG";
	:put $MSG;
};
:if ($APTypeID = 4) do={
	/ip dns static add address=199.204.5.29 name=unifi disabled=no comment="VIASAT - DNS TO DIRECT UNIFI APS TO THE UNIFI CONTROLLER";
	:set MSG "STATIC DNS CREATION FOR UNIFI HAS BEEN COMPLETED.";
	:log info "info hwid=$MSGHWID,msg=$MSG";
	:put $MSG;
};

# SET NTP SERVER
/system ntp client set enabled=yes server-dns-names="TIME.NNU.COM";

:set MSG "SETTING NTP SERVER HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE RADIUS
/radius add address=63.79.12.100 comment="VIASAT - RADIUS USED FOR TECH RADIUS" disabled=no secret=ttekw9_33e service=login timeout=3s;
/radius add address=63.79.12.165 comment="VIASAT - DEFAULT RADIUS FOR HOTSPOT SERVER PROFILE" disabled=no secret=ttekw9_33e service=hotspot timeout=5s;
/radius incoming set accept=yes port=3799;

:set MSG "RADIUS CREATION HAVE BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# SET IP SERVICES + BEP
/ip service set api disabled=yes address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";
/ip service set api-ssl disabled=yes address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";
/ip service set ftp disabled=yes address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";
/ip service set ssh disabled=no address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24,10.86.155.0/24,10.43.164.0/24,172.30.168.0/24";
/ip service set telnet disabled=yes address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";
/ip service set winbox disabled=no address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";
/ip service set www disabled=yes address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";
/ip service set www-ssl disabled=yes address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24";

:set MSG "SETTING IP SERVICE HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE ADMIN LOGIN, GROUPS, AND AAA + BEP
/user aaa set default-group=full interim-update=5m use-radius=yes;
/user group add comment="VIASAT - RADIUS VWSTSR LOGIN GROUP" name=vwstsr policy=local,telnet,ssh,read,test,winbox,web,!ftp,!reboot,!write,!policy,!password,!sniff,!sensitive,!api,!romon,!dude,!tikapp;
/user group add comment="VIASAT - RADIUS VWSTSRELEV LOGIN GROUP" name=vwstsrelev policy=local,telnet,ssh,reboot,read,write,test,winbox,web,sniff,sensitive,!ftp,!policy,!password,!api,!romon,!dude,!tikapp;
/user group add comment="VIASAT - RADIUS NONE LOGIN GROUP" name=none;
/user group add comment="VIASAT - LOCAL GROUP FOR BANDWIDTH TESTING ONLY" name=bandwidthtesting policy=test,winbox,!local,!telnet,!ssh,!ftp,!reboot,!read,!write,!policy,!password,!web,!sniff,!sensitive,!api,!romon,!dude,!tikapp;
/user add address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24,10.86.155.0/24,10.43.164.0/24,172.30.168.0/24" comment="VIASAT - LOGIN FOR LOCAL MGMT" group=full name="VWSAdmin" password="kLC236A2%z4R";
:delay 1s;
:foreach UserRemove in=[/user find where name!="VWSAdmin"] do={
	/user remove $UserRemove;
};
:delay 1s;
/user add address="63.79.12.0/23,208.180.0.144/28,199.204.4.0/22,8.37.96.0/20,172.108.138.64/28,172.16.0.0/16,10.55.0.0/17,10.56.0.0/15,10.232.0.0/19,10.62.175.0/25,65.103.147.128/28,65.103.147.160/27,192.168.73.0/24" comment="VIASAT - LOGIN FOR BANDWIDTH TESTING ONLY" group=bandwidthtesting name="VWSBandwidth" password="VWStesting1942";

:set MSG "ADMIN LOGIN, GROUPS, AND AAA CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;
# CREATE THE CURRENT_CONFIG_VERSION FILE
:if ([:len [/file find where name~"CURRENT_CONFIG_VERSION"]] = 0) do={
	:if ($FlashStorage = false) do={
		/interface ethernet export file="CURRENT_CONFIG_VERSION";
	} else={
		/interface ethernet export file="flash/CURRENT_CONFIG_VERSION";
	};
	:delay 1s;
	:set NamePull [/file get [find where name~"CURRENT_CONFIG_VERSION"] name];
	/file set [find where name="$NamePull"] contents=":global CurrentConfigVersion 20171116;:global AttemptedUpdateVersion 20171116;";
	:set MSG "CREATE THE CURRENT_CONFIG_VERSION FILE.";
	:log info "info hwid=$HWID,msg=$MSG";
	:put $MSG;
};
# CREATE SCHEDULERS
/system scheduler add interval=5m name=VWSadminlogin on-event=":if ([:len [/system script job find where script=VWSadminlogin]] = 0) do={/system script run VWSadminlogin}" start-time=startup disabled=no;
/system scheduler add name=VWSstartupevent on-event=VWSstartupevent start-time=startup disabled=no;
/system scheduler add name=VWScheckin on-event=VWScheckin start-time=startup interval=5m disabled=no;
/system scheduler add name=VWSautoexport on-event=VWSautoexport start-time=startup interval=1w disabled=no;
/system scheduler add name=VWSdevicemonitor on-event=VWSdevicemonitor start-time=startup interval=5m disabled=no;
/system scheduler add comment="THIS SCHEDULER WILL RUN THE LATEST VERSION OF THE AUTO_CONFIG_UPDATE SCRIPT DAILY" interval=1d name="AUTO_CONFIG_UPDATE_DAILY" on-event=":delay 0s;\r\n:local ScriptName [/system script get [find where name~\"AUTO_CONFIG_UPDATE\"] name];\r\n/system script run \$ScriptName;\r\n" start-time="02:00:00";
/system scheduler add comment="THIS SCHEDULER WILL RUN THE LATEST VERSION OF THE AUTO_CONFIG_UPDATE SCRIPT AFTER A REBOOT" name="AUTO_CONFIG_UPDATE_STARTUP" on-event=":delay 60s;\r\n:local ScriptName [/system script get [find where name~\"AUTO_CONFIG_UPDATE\"] name];\r\n/system script run \$ScriptName;\r\n" start-time="startup";
:set MSG "SCHEDULER CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE SCRIPTS
/system script add name=VWSadminlogin source=":global OLDLOGINS \r\n:global CURRENTLOGINS \r\n:global NAMEINFO \r\n:global ADDRESSINFO \r\n:global VIAINFO \r\n:global WANIP\r\n:local IDENTITY [/system identity get name]\r\n:local COUNTER 0\r\n\r\n:set OLDLOGINS \"START\"\r\n:set CURRENTLOGINS \r\n:set NAMEINFO \r\n:set ADDRESSINFO \r\n:set VIAINFO \r\n\r\n:while (\$COUNTER < 1) do={\r\n:set CURRENTLOGINS [/user active find]\r\n:foreach LOGIN in=[\$CURRENTLOGINS] do={\r\n\t:if ([:len [:find \$OLDLOGINS \$LOGIN]] = 0) do={\r\n\t\t:set NAMEINFO \r\n\t\t:set ADDRESSINFO \r\n\t\t:set VIAINFO \r\n\t\t:foreach INT in=[\$CURRENTLOGINS] do={\r\n\t\t\t:set NAMEINFO (\$NAMEINFO,[/user active get \$INT name])\r\n\t\t\t:set ADDRESSINFO (\$ADDRESSINFO,[/user active get \$INT address])\r\n\t\t\t:set VIAINFO (\$VIAINFO,[/user active get \$INT via])\r\n\t\t\t}\r\n\t\t:local NAME (\$NAMEINFO -> [:find \$CURRENTLOGINS \$LOGIN])\r\n\t\t:local ADDRESS (\$ADDRESSINFO -> [:find \$CURRENTLOGINS \$LOGIN])\r\n\t\t:local VIA (\$VIAINFO -> [:find \$CURRENTLOGINS \$LOGIN])\r\n\t\t:if (\$OLDLOGINS != \"START\") do={\r\n\t\t\t:log info \"AdminLogin hwid=\$IDENTITY,ipaddress=\$WANIP,msg=USER \$NAME LOGGED IN VIA \$VIA FROM \$ADDRESS - LOCAL SESSION ID \$LOGIN\"\r\n\t\t\t}\r\n\t\t}\r\n\t}\r\n:foreach LOGIN in=[\$OLDLOGINS] do={\r\n\t:if ([:len [:find \$CURRENTLOGINS \$LOGIN]] = 0) do={\r\n\t\t:local NAME (\$NAMEINFO -> [:find \$OLDLOGINS \$LOGIN])\r\n\t\t:local ADDRESS (\$ADDRESSINFO -> [:find \$OLDLOGINS \$LOGIN])\r\n\t\t:local VIA (\$VIAINFO -> [:find \$OLDLOGINS \$LOGIN])\r\n\t\t:if (\$OLDLOGINS != \"START\") do={\r\n\t\t\t:log info \"AdminLogin hwid=\$IDENTITY,ipaddress=\$WANIP,msg=USER \$NAME LOGGED OUT VIA \$VIA - LOCAL SESSION ID \$LOGIN\"\r\n\t\t\t}\r\n\t\t:set NAMEINFO \r\n\t\t:set ADDRESSINFO \r\n\t\t:set VIAINFO \r\n\t\t:foreach INT in=[\$CURRENTLOGINS] do={\r\n\t\t\t:set NAMEINFO (\$NAMEINFO,[/user active get \$INT name])\r\n\t\t\t:set ADDRESSINFO (\$ADDRESSINFO,[/user active get \$INT address])\r\n\t\t\t:set VIAINFO (\$VIAINFO,[/user active get \$INT via])\r\n\t\t\t}\r\n\t\t}\r\n\t}\r\n:set OLDLOGINS \$CURRENTLOGINS\r\n:delay 1s\r\n}\r\n\r\n";
/system script add name=VWSstartupevent source="# VWSstartupevent Script v1.0 - Replaces the NNUstartupevent script\r\n# WHILE 63.79.12.161 IS NOT PINGABLE, LOOP A 5S DELAY THEN TRY PINGING AGAIN\r\n:local PINGCOUNT [/ping 63.79.12.161 count=5]\r\n:while (\$PINGCOUNT < 3) do={\r\n\t:delay 5s; \r\n\t:set PINGCOUNT [/ping 63.79.12.161 count=5]\r\n\t}\r\n# Run the VWSreboot Script\r\n:execute \"VWSreboot\"\r\n:delay 2s\r\n# Run the VWSadminlogin Script\r\n:execute \"VWSadminlogin\"\r\n:delay 2s\r\n# Run the VWSautoexport Script\r\n:execute \"VWSautoexport\"";
/system script add name=VWScheckin source="# VWScheckin Script v2.1\r\n# IF THERE ARE MORE THAN 1 VWScheckin JOB, TERMINATE ANY INSTANCES OF THE VWScheckin JOB AND LOG THE REMOVAL\r\n:local NUMOFCHECKINSCRIPTS [:len [/system script job find where script=VWScheckin]] ;\r\n:if (\$NUMOFCHECKINSCRIPTS > 1) do={\r\n\t:foreach job in=[/system script job find where script=VWScheckin] do={\r\n\t\t:log error \"~~~Removing VWScheckin job due to backup of jobs~~~\" ;\r\n\t\t[/system script job remove \$job] ;\r\n\t\t}\r\n\t}\r\n# GET CURRENT PUBLIC IP FROM VWS AND GET IT INTO A GLOBAL VARIABLE\r\n/tool fetch mode=http url=\"https://service.nnu.com/nnu_ipecho.py\" dst-path=\"publicip.txt\" ;\r\n:delay 1s ;\r\n:local PUBIP [/file get publicip.txt contents] ;\r\n/file remove \"publicip.txt\" ;\r\n:global WANIP [:pick \$PUBIP 0 [:len \$PUBIP]] ;\r\n# FIND THE WAN INTERFACE\r\n:local GATEWAYSTATUS [:tostr [/ip route get [/ip route find where active=yes dst-address=\"0.0.0.0/0\" !routing-mark] gateway-status]] ;\r\n:local WANINT ;\r\n:local CHAR ;\r\n:local COUNTER 0 ;\r\n:local GWLEN [:len \$GATEWAYSTATUS] ;\r\n:do {\r\n\t:set COUNTER (\$COUNTER + 1) ;\r\n\t:set CHAR [:pick \$GATEWAYSTATUS (\$GWLEN - \$COUNTER) (\$GWLEN - \$COUNTER + 1)]} while=(\$CHAR != \" \") ;\r\n:set WANINT [:pick \$GATEWAYSTATUS (\$GWLEN - \$COUNTER + 1) \$GWLEN] ;\r\n# FIND THE VPN ADDRESS\r\n:local VPN \"not connected\"\r\n:foreach VPNINT in=[/ip route find dst-address=172.16.0.1/32 active=yes dynamic=yes] do={\r\n\t:local ADDRESS [/ip address get [/ip address find where interface=[/ip route get \$VPNINT gateway]] address] ;\r\n\t:set \$VPN [:pick \$ADDRESS 0 [:find \$ADDRESS \"/\"]]\r\n\t}\r\n# GET SYSTEM STATS\r\n:delay 2s\r\n:local CPU [/system resource get cpu-load] ;\r\n:local MEMORY [/system resource get free-memory] ;\r\n:local UPTIME [/system resource get uptime] ;\r\n:local VERSION [/system resource get value-name=version] ;\r\n:local MODEL [/system resource get value-name=board-name] ;\r\n:local IBYTES 0 ;\r\n:local OBYTES 0 ; \r\n#PERFORM A CHECKIN ON EACH MODEM IN THE MDMLIST.txt\r\n:if ([:len [/file find name=MDMLIST.txt]] != 0) do={\r\n\t:local MDMLIST [/file get MDMLIST.txt contents] ;\r\n\t:local ARRAY \"\" ;\r\n\t:set ARRAY [:toarray \$ARRAY] ;\r\n\t:local END [:find \$MDMLIST \"\\r\\n\"] ;\r\n\t:if ([:typeof \$END] = \"nil\") do={:set END [:len \$MDMLIST]} ;\r\n\t:set END (\$END + 2) ;\r\n\t:do {\r\n\t\t:local LINE [:pick \$MDMLIST 0 (\$END - 2)] ;\r\n\t\t:set ARRAY (\$ARRAY , [\$LINE]) ;\r\n\t\t:set MDMLIST [:pick \$MDMLIST \$END [:len \$MDMLIST]] ;\r\n\t\t:set END [:find \$MDMLIST \"\\r\\n\"] ;\r\n\t\t:if ([:typeof \$END] = \"nil\") do={:set END [:len \$MDMLIST]} ;\r\n\t\t:set END (\$END + 2) ;\r\n\t\t} while=( [:len \$MDMLIST] >= \$END)\r\n\t:foreach MDM in=\$ARRAY do={\r\n\t\t:set MDM [:toarray \$MDM] ;\r\n\t\t:local LEN [:len \$MDM] ;\r\n\t\t:local MDMHWID (\$MDM->0) ;\r\n\t\t:local MDMINT (\$MDM->1) ;\r\n\t\t:local MDMIP (\$MDM->2) ;\r\n\t\t:local MDMTABLE (\$MDM->3) ;\r\n\t\t:local USERS 0 ;\r\n\t\t:local MIBYTES [/interface get \$MDMINT value-name=rx-byte] ;\r\n\t\t:set IBYTES (\$IBYTES + \$MIBYTES) ;\r\n\t\t:local MOBYTES [/interface get \$MDMINT value-name=tx-byte] ;\r\n\t\t:set OBYTES (\$OBYTES + \$MOBYTES) ;\r\n\t\t:if ([/ping 8.8.8.8 count=2 routing-table=\$MDMTABLE src-address=\$MDMIP] > 0) do={\r\n\t\t\t:log info (\"AP-UP hwid=\$MDMHWID ,ipaddress=\$MDMIP ,vpn=\$VPN\") ;\r\n\t\t\t} else={\r\n\t\t\t:log info (\"AP-DOWN hwid=\$MDMHWID ,ipaddress=\$MDMIP ,vpn=\$VPN\") ;\r\n\t\t\t} ;\r\n\t\t:log info (\"stats hwid=\$MDMHWID,ipaddress=\$MDMIP,users=\$USERS,cpu=\$CPU,freememKB=\$MEMORY,uptime=\$UPTIME,iobytes=\$MIBYTES/\$MOBYTES,version=\$VERSION,model=\$MODEL\") ;\r\n\t\t}\r\n\t}\r\n# PERFORM A CHECKIN ON THE BASE UNIT\r\n{\r\n\t:local ID [/system identity get name] ;\r\n\t:local USERS [:len [/ip hotspot active find]] ;\r\n\t:if (\$IBYTES = 0) do={\r\n\t\t:set IBYTES [/interface get \$WANINT value-name=rx-byte] ;\r\n\t\t} ;\r\n\t:if (\$OBYTES = 0) do={\r\n\t\t:set OBYTES [/interface get \$WANINT value-name=tx-byte] ;\r\n\t\t}\t;\r\n\t:log info (\"checkin hwid=\$ID,ipaddress=\$WANIP,vpn=\$VPN\") ; :log info (\"stats hwid=\$ID,ipaddress=\$WANIP,users=\$USERS,cpu=\$CPU,freememKB=\$MEMORY,uptime=\$UPTIME,iobytes=\$IBYTES/\$OBYTES,version=\$VERSION,model=\$MODEL\") ;\r\n} ;\r\n#PERFORM A CHECKIN ON EACH VG\r\n:foreach VG in=[/ip hotspot find where name!=HS_SERVER invalid=no] do={\r\n\t:local DCI true\r\n\t:local ID [/ip hotspot get \$VG name] ;\r\n\t:if (\$ID = [/system identity get name]) do={\r\n\t\t:set DCI false\r\n\t\t} ;\r\n\t:if (\$ID = \"ERATE_HS_SERVER\") do={\r\n\t\t:set DCI false\r\n\t\t} ;\t\t\r\n\t:local USERS [:len [/ip hotspot active find where server=\$ID]] ;\r\n\t:local OBYTES [/interface get [/interface find where name=[/ip hotspot get \$VG interface]] value-name=rx-byte] ;\r\n\t:local IBYTES [/interface get [/interface find where name=[/ip hotspot get \$VG interface]] value-name=tx-byte] ;\r\n\t:if (\$DCI != false) do={\r\n\t\t:log info (\"checkin hwid=\$ID,ipaddress=\$WANIP,vpn=\$VPN\") ;\r\n\t\t:log info (\"stats hwid=\$ID,ipaddress=\$WANIP,users=\$USERS,cpu=\$CPU,freememKB=\$MEMORY,uptime=\$UPTIME,iobytes=\$IBYTES/\$OBYTES,version=\$VERSION,model=\$MODEL\") ;\r\n\t\t} ;\r\n\t}";
/system script add name=VWSautoexport source="/tool fetch address=\"msbackups.nnu.com\" mode=ftp user=msbackups password=B@ckuPs987 src-path=\"/srv/ftp/BACKUPS/export.rsc\" dst-path=/\r\n:delay 1s\r\n:import export.rsc\r\n";
/system script add name=VWSdevicemonitor source="#IF YOU HAVE MORE THAN 100 APS THAT NEED TO BE MONITORED YOU NEED MULTIPLE APLIST FILES\r\n#IF YOU DO NOT USE A MAC ADDRESS FOR THE HWID THIS SCRIPT WILL NEED TO BE MODIFIED\r\n#YOU MUST PUT THE APLIST FILES IN THE ROOT DIRECTORY OF THE MIKROTIK AND IT MUST BE IN THE PROPER FORMAT\r\n\r\n#GET THE VPN ADDRESS\r\n:local VPN \"not connected\"\r\n:foreach VPNINT in=[/ip route find dst-address=172.16.0.1/32 active=yes dynamic=yes] do={\r\n\t:local ADDRESS [/ip address get [/ip address find where interface=[/ip route get \$VPNINT gateway]] address] ;\r\n\t:set \$VPN [:pick \$ADDRESS 0 [:find \$ADDRESS \"/\"]]\r\n\t}\r\n\r\n:foreach APLISTS in=[/file find where name~\"APList\"] do={\r\n\r\n\t#DUMP THE CONTENTS OF THE APLIST FILE INTO A LOCAL VARIABLE\r\n\t:local APLIST [/file get \$APLISTS contents]\r\n\t#SET X TO 0\r\n\t:local X 0\r\n\t#SET THE APNUMBER TO 0\r\n\t:local APNUM 0\r\n\t#WHILE THE APNUMBER AND X ARE THE SAME THING CONTINUE PARSING THE APLIST VARIABLE AND PINGING APS\r\n\t:while (\$APNUM = \$X) do={\r\n\t#INCREASE THE COUNTER VARIABLE OF x\r\n\t:set X (\$X + 1)\r\n\t#FIND WITHIN THE APLIST VARIABLE THE CHARACTER NUMBER THAT HAS VALUE OF X WHICH IS THE AP NUMBER\r\n\t:local APSTART [:find \$APLIST \"\$X,\"]\r\n\t#IF THE VALUE OF APSTART IS NOT NOTHING, THEN CONTINUE (THIS PREVENTS AN EXTRA REPETITION WHERE THE VALUE OF X IS AN AP NUMBER THAT DOESN'T EXIST)\r\n\t:if ([:typeof \$APSTART] != \"nil\") do={\r\n\t\t#SET THE END POINT TO 38 CHARACTERS AFTER THE START OF THE AP NUMBER\r\n\t\t:local APEND (\$APSTART + 38)\r\n\t\t#CREATE THE VARIABLE APINFO THAT HAS THE CONTENTS OF THE APLIST VARIABLE BETWEEN THE START AND END POINTS FOR THAT AP\r\n\t\t:local APINFO [:pick \$APLIST \$APSTART \$APEND]\r\n\t\t#FIND THE END OF THE LINE IN ORDER TO PREVENT ANY CHARACTERS FROM THE NEXT LINE FROM CAUSING PROBLEMS\r\n\t\t:set APEND [:find \$APINFO \"+\"]\r\n\t\t#SET THE APINFO VARIABLE TO ONLY CONTAIN THE APPROPRIATE LINE\r\n\t\t:set APINFO [:pick \$APINFO 0 \$APEND]\r\n\t\t#PARSE FOR THE AP NUMBER\r\n\t\t:local APNUMEND [:find \$APINFO \",\"]\r\n\t\t#CREATE A VARIABLE WITH THE AP NUMBER\r\n\t\t:local APNUMBER [:pick \$APINFO 0 \$APNUMEND]\r\n\t\t#PARSE FOR THE AP MAC ADDRESS/HWID BEGINNING AND END POSITIONS\r\n\t\t:local APMACSTART (\$APNUMEND + 1)\r\n\t\t:local APMACEND [:find \$APINFO \";\"]\r\n\t\t#CREATE A VARIABLE WITH THE APMAC/HWID\r\n\t\t:local APMAC [:pick \$APINFO \$APMACSTART \$APMACEND]\r\n\t\t#PARSE FOR THE BEGINNING AND END OF THE AP IP ADDRESS TO PING\r\n\t\t:local APIPSTART (\$APMACEND + 1)\r\n\t\t:local APIPEND (\$APIPSTART + 15)\r\n\t\t#CREATE A VARIABLE WITH THE IP\r\n\t\t:local APIP [:pick \$APINFO \$APIPSTART \$APIPEND]\r\n\t\t:set APNUM (\$APNUMBER)\r\n\t\t#PING THE AP AND SEND AN UP OR DOWN MSG TO TRACKOS\r\n\t\t:if ([/ping \$APIP count=4 interval=00:00:00.5] > 0) do={\r\n\t\t\t:log info (\"AP-UP hwid=\$APMAC ,ipaddress=\$APIP ,vpn=\$VPN\")\r\n\t\t\t} else={\r\n\t\t\t:log info (\"AP-DOWN hwid=\$APMAC,ipaddress=\$APIP,vpn=\$VPN\")\r\n\t\t\t}\r\n\t\t}\r\n\t}\r\n}";
/system script add name=VWSreboot source="# VWSreboot Script v1.4\r\n# GET CURRENT PUBLIC IP FROM VWS\r\n/tool fetch mode=http url=\"https://service.nnu.com/nnu_ipecho.py\" dst-path=\"publicip.txt\"\r\n:delay 1s\r\n:local PUBIP [/file get publicip.txt contents]\r\n:global WANIP [:pick \$pubip 0 ([:len \$pubip]-1)] \r\n/file remove \"publicip.txt\"\r\n# FIND THE VPN ADDRESS\r\n:local VPN \"not connected\"\r\n:foreach VPNINT in=[/ip route find dst-address=172.16.0.1/32 active=yes dynamic=yes] do={\r\n\t:local ADDRESS [/ip address get [/ip address find where interface=[/ip route get \$VPNINT gateway]] address] ;\r\n\t:set \$VPN [:pick \$ADDRESS 0 [:find \$ADDRESS \"/\"]]\r\n\t}\r\n# FIND THE IDENTITY\r\n:local IDENTITY [/system identity get name]\r\n# SEND THE REBOOT TRAP\r\n:log info (\"reboot hwid=\$IDENTITY,ipaddress=\$WANIP,vpn=\$VPN\")\r\n:log info (\"reboot hwid=\$IDENTITY,ipaddress=\$WANIP,vpn=\$VPN\")\r\n:foreach HOST in [/ip hotspot host find] do={/ip hotspot host remove \$HOST}";
/system script add comment="THIS SCRIPT IS USED TO KEEP THE CONFGIURATION OF THIS DEVICE UP TO DATE" name="AUTO_CONFIG_UPDATE_V1" source="# Written By: Greg Bolton\r\n# Last Updated On:11/14/2017\r\n# Version: 1.0.0\r\n# Summary: This script will determine if a configuration update is available, or if the previous update failed. It will then take the need actions.\r\n# VARIABLES\r\n#================================================\r\n#DO NOT CHANGE ANYTHING ON THIS LINE OR BELOW!\r\n#================================================\r\n:local HWID [/system identity get name];\r\n:local MSG;\r\n:local FlashStorage false;\r\n:global LatestUpdateVersion;\r\n:global UpdateVersionArray;\r\n:global CurrentConfigVersion;\r\n:global AttemptedUpdateVersion;\r\n:local NamePull;\r\n:local Counter;\r\n# DETERMINE IF FILES NEED TO BE STORED IN FLASH\r\n:if ([:len [/file find where name=\"flash\" type=disk]] > 0) do={\r\n\t:set FlashStorage true;\r\n};\r\n# CHECK FOR CURRENT CONFIG VERSION FILE\r\n:if ([:len [/file find where name~\"CURRENT_CONFIG_VERSION\"]] > 0) do={\r\n\t:set NamePull [/file get [find where name~\"CURRENT_CONFIG_VERSION\"] name];\r\n\t/import \$NamePull;\r\n} else={\r\n\t:set MSG \"ERROR:00001 - NO CURRENT_CONFIG_VERSION FOUND.\";\r\n\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n\t:end;\r\n};\r\n# DOWNLOAD UPDATE CONFIG VERSION FILE\r\n:if (\$FlashStorage = false) do={\r\n\t/tool fetch mode=ftp address=208.180.231.109 user=\"vwsconfiglogin\" password=\"Fvam1l9xUJDi8hq\" src-path=\"AUTO_UPDATE/UPDATE_CONFIG_VERSION.rsc\" dst-path=\"UPDATE_CONFIG_VERSION.rsc\";\r\n} else={\r\n\t/tool fetch mode=ftp address=208.180.231.109 user=\"vwsconfiglogin\" password=\"Fvam1l9xUJDi8hq\" src-path=\"AUTO_UPDATE/UPDATE_CONFIG_VERSION.rsc\" dst-path=\"/flash/UPDATE_CONFIG_VERSION.rsc\";\r\n};\r\n:delay 1s;\r\n# IMPORT BOTH FILES\r\n:set NamePull [/file get [find where name~\"UPDATE_CONFIG_VERSION\"] name];\r\n/import \$NamePull;\r\n:delay 1s;\r\n/file remove [find where name=\"\$NamePull\"];\r\n# DETERMINE IF UPDATE IS NEEDED\r\n:if (\$LatestUpdateVersion = \$CurrentConfigVersion) do={\r\n\t:set MSG \"UPDATE:00001 - CONFIG_VERSION \$CurrentConfigVersion.\";\r\n\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n} else={\r\n# APPLY ANY UPDATES THAT ARE NEEDED\r\n\t:foreach Version in=\$UpdateVersionArray do={\r\n\t\t:if (\$Version > \$CurrentConfigVersion) do={\r\n# DETERMINE IF PREVIOUS UPDATE FAILED\r\n\t\t\t:set Counter [:len [/system script job find where script~\"AUTO_CONFIG_UPDATE\"]];\r\n\t\t\t:if (\$Counter > 1) do={\r\n\t\t\t\t:set MSG \"ERROR:00002 - CONFIG_VERSION \$AttemptedUpdateVersion LOCKED UP.\";\r\n\t\t\t\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n\t\t\t\t:foreach job in=[/system script job find where script=VWScheckin] do={\r\n\t\t\t\t\t:set MSG \"~~~Removing AUTO_CONFIG_UPDATE job due to backup of jobs~~~\";\r\n\t\t\t\t\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n\t\t\t\t\t[/system script job remove \$job] ;\r\n\t\t\t\t};\r\n\t\t\t};\r\n\t\t\t:if (\$AttemptedUpdateVersion = \$Version) do={\r\n\t\t\t\t:set MSG \"ERROR:00003 - CONFIG_VERSION \$AttemptedUpdateVersion FAILED.\";\r\n\t\t\t\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n\t\t\t\t:end;\r\n\t\t\t};\r\n\t\t\t:if (\$FlashStorage = false) do={\r\n\t\t\t\t/tool fetch mode=ftp address=208.180.231.109 user=\"vwsconfiglogin\" password=\"Fvam1l9xUJDi8hq\" src-path=\"AUTO_UPDATE/MIKROTIK_AUTO_UPDATE_\$Version.rsc\" dst-path=\"MIKROTIK_AUTO_UPDATE_\$Version.rsc\";\r\n\t\t\t\t:delay 1s;\r\n\t\t\t} else={\r\n\t\t\t\t/tool fetch mode=ftp address=208.180.231.109 user=\"vwsconfiglogin\" password=\"Fvam1l9xUJDi8hq\" src-path=\"AUTO_UPDATE/MIKROTIK_AUTO_UPDATE_\$Version.rsc\" dst-path=\"/flash/MIKROTIK_AUTO_UPDATE_\$Version.rsc\";\r\n\t\t\t\t:delay 1s;\r\n\t\t\t};\r\n\t\t\t:set AttemptedUpdateVersion \$Version;\r\n\t\t\t:set NamePull [/file get [find where name~\"CURRENT_CONFIG_VERSION\"] name];\r\n\t\t\t/file set [find where name=\"\$NamePull\"] contents=\":global CurrentConfigVersion \$CurrentConfigVersion;:global AttemptedUpdateVersion \$AttemptedUpdateVersion;\";\r\n\t\t\t:set MSG \"UPDATE:00002 - CONFIG_VERSION \$AttemptedUpdateVersion.\";\r\n\t\t\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n\t\t\t:set NamePull [/file get [find where name~\"MIKROTIK_AUTO_UPDATE_\$Version\"] name];\r\n\t\t\t/import \$NamePull;\r\n\t\t\t:delay 1s;\r\n\t\t\t/file remove [find where name=\"\$NamePull\"];\r\n\t\t\t:set CurrentConfigVersion \$Version;\r\n\t\t\t:set NamePull [/file get [find where name~\"CURRENT_CONFIG_VERSION\"] name];\r\n\t\t\t/file set [find where name=\"\$NamePull\"] contents=\":global CurrentConfigVersion \$CurrentConfigVersion;:global AttemptedUpdateVersion \$AttemptedUpdateVersion;\";\r\n\t\t\t:set MSG \"UPDATE:00003 - CONFIG_VERSION \$CurrentConfigVersion.\";\r\n\t\t\t:log info \"info hwid=\$HWID,msg=\$MSG\";\r\n\t\t};\r\n\t};\r\n};\r\n";
:set MSG "SCRIPT CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# ENABLE BTEST
/tool bandwidth-server set enabled=yes authenticate=yes;

:set MSG "ENABLING BTEST HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# SET BRIDGE TO USE IP FIREWALL
/interface bridge settings set use-ip-firewall=yes use-ip-firewall-for-pppoe=no use-ip-firewall-for-vlan=no;

:set MSG "SETTING BRIDGE TO USE IP FIREWALL HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# SETUP SNMP
/snmp community set [find default=yes] addresses=199.204.5.44 authentication-password="59B*CRqBX7rs" encryption-password="tV*80^JaTPxH" name="VWSsnmpV3" security=authorized;
/snmp set enabled=yes contact=$FullSYSID trap-version=3;

# CREATE FIREWALL ADDRESS LIST
/ip firewall address-list add address=10.62.175.0/25 comment="TRAFFIC TO VIASAT GBS BCS DMZ 1 IS NAT EXEMPT" list=NAT_EXEMPT;
/ip firewall address-list add address=63.79.12.0/23 comment="VIASAT - OLD NNU PRODUCTION NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=65.103.147.128/28 comment="VIASAT - JUMPBOX" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=208.180.0.144/28 comment="VIASAT - BCS STAGING BLDG NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=199.204.4.0/22 comment="VIASAT - NEW VIASAT PRODUCTION NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=8.37.96.0/21 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=8.37.104.0/21 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=172.108.138.64/28 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=208.180.0.152/29 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=10.62.175.0/25 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=VIASAT_NETWORKS;
/ip firewall address-list add address=63.79.12.0/23 comment="VIASAT - ACCEPT ICMP FROM OLD NNU PRODUCTION NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=208.180.0.144/28 comment="VIASAT - ACCEPT ICMP FROM BCS STAGING BLDG NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=199.204.4.0/22 comment="VIASAT - ACCEPT ICMP FROM NEW VIASAT PRODUCTION NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=8.37.96.0/21 comment="VIASAT - ACCEPT ICMP FROM VIASAT OFFICE NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=8.37.104.0/21 comment="VIASAT - ACCEPT ICMP FROM VIASAT OFFICE NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=172.108.138.64/28 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=208.180.0.152/29 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=ACCEPT_ICMP;
/ip firewall address-list add address=10.62.175.0/25 comment="VIASAT - VIASAT OFFICE NETWORK" disabled=no list=ACCEPT_ICMP;
:if ($HasMGMT = true) do={
	/ip firewall address-list add address=10.86.155.0/24 comment="Ether 5 - Mgmt for BEPE2E" disabled=no list=LOCAL_MGMT_ACCESS;
	/ip firewall address-list add address=10.86.155.0/24 comment="Ether 5 - Allow ping for BEPE2E" disabled=no list=ACCEPT_ICMP;
	/ip firewall address-list add address=172.30.168.0/24 comment="10.86.155.1 - Mgmt for BEPE2E" disabled=no list=LOCAL_MGMT_ACCESS;
	/ip firewall address-list add address=172.30.168.0/24 comment="10.86.155.1 - Allow ping for BEPE2E" disabled=no list=ACCEPT_ICMP;
	/ip firewall address-list add address=10.43.164.0/24 comment="10.86.155.1 - Mgmt for BEPE2E" disabled=no list=LOCAL_MGMT_ACCESS;
	/ip firewall address-list add address=10.43.164.0/24 comment="10.86.155.1 - Allow ping for BEPE2E" disabled=no list=ACCEPT_ICMP;
    /ip firewall address-list add address="$MGMTNetwork/$MGMTCIDR" comment="VIASAT - DNS ACCEPT FOR LOCAL MGMT NETWORK" disabled=no list=LOCAL_DNS_ACCEPT;
	/ip firewall address-list add address="$MGMTNetwork/$MGMTCIDR" comment="VIASAT - MGMT ACCESS FROM LOCAL MGMT NETWORK" disabled=no list=LOCAL_MGMT_ACCESS;
	/ip firewall address-list add address="$MGMTNetwork/$MGMTCIDR" comment="VIASAT - MASQUERADE FOR LOCAL MGMT NETWORK" disabled=no list=LOCAL_MGMT_MASQ;
	/ip firewall address-list add address="$MGMTNetwork/$MGMTCIDR" comment="VIASAT - ACCEPT ICMP FROM LOCAL MGMT NETWORK" disabled=no list=ACCEPT_ICMP;
	/ip firewall address-list add address=192.168.73.0/24 comment="VIASAT - MGMT ACCESS FROM LOCAL PROVISIONING MGMT NETWORK" disabled=no list=LOCAL_MGMT_ACCESS;
};
:foreach Loc in=$LocNames do={
	:set NetAddressPull [/ip address get [find where interface~"$Loc"] network];
	/ip firewall address-list add address="$NetAddressPull/$UserCIDR" comment="VIASAT - $Loc USER NETWORK ADDED TO NETWORK GROUP A" disabled=no list=USER_NETWORK_GROUPA;
	/ip firewall address-list add address="$NetAddressPull/$UserCIDR" comment="VIASAT - $Loc USER NETWORK ADDED TO NETWORK GROUP B" disabled=no list=USER_NETWORK_GROUPB;
	/ip firewall address-list add address="$NetAddressPull/$UserCIDR" comment="VIASAT - DNS ACCEPT FOR $Loc USER NETWORK" disabled=no list=LOCAL_DNS_ACCEPT;
	/ip firewall address-list add address="$NetAddressPull/$UserCIDR" comment="VIASAT - MASQUERADE FOR $Loc USER NETWORK" disabled=no list=USER_MASQ_ACCESS;
	/ip firewall address-list add address="$NetAddressPull/$UserCIDR" comment="VIASAT - ACCEPT ICMP FROM $Loc USER NETWORK" disabled=no list=ACCEPT_ICMP;
};

:set MSG "FIREWALL ADDRESS LIST CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE FIREWALL FILTERS
/ip firewall filter add chain=forward protocol=tcp connection-state=invalid action=reject reject-with=tcp-reset comment="VIASAT - RESET FORWARD PACKETS WITH INVALID CONNECTION STATES" disabled=no;
/ip firewall filter add chain=input protocol=tcp connection-state=invalid action=reject reject-with=tcp-reset comment="VIASAT - RESET INPUT PACKETS WITH INVALID CONNECTION STATES" disabled=no;
/ip firewall filter add chain=output protocol=tcp connection-state=invalid action=reject reject-with=tcp-reset comment="VIASAT - RESET OUTPUT PACKETS WITH INVALID CONNECTION STATES" disabled=no;
/ip firewall filter add action=accept chain=input comment="VIASAT - ACCEPT REDIRECT VIASATWIFI.COM TO WIFI1.VIASAT.COM VIA WEB PROXY" dst-port=48678 protocol=tcp;
/ip firewall filter add action=accept chain=input connection-state=established,related comment="VIASAT - ACCEPT INPUT PACKETS WITH RELATED OR ESTABLISHED CONNECTION STATE" disabled=no;
/ip firewall filter add action=accept chain=input comment="VIASAT - ACCEPT FULL INPUT ACCESS OVER VWS VPN" in-interface=VIASAT_RESTON_VPN disabled=no;
/ip firewall filter add action=accept chain=forward comment="VIASAT - ACCEPT FULL FORWARD ACCESS OVER VWS VPN" in-interface=VIASAT_RESTON_VPN disabled=no;
/ip firewall filter add action=accept chain=input dst-port=53 protocol=udp src-address-list=LOCAL_DNS_ACCEPT comment="VIASAT - ACCEPT LOCAL UDP DNS REQUESTS" disabled=no;
/ip firewall filter add action=accept chain=input dst-port=53 protocol=tcp src-address-list=LOCAL_DNS_ACCEPT comment="VIASAT - ACCEPT LOCAL TCP DNS REQUESTS" disabled=no;
/ip firewall filter add action=accept chain=input protocol=icmp src-address-list=ACCEPT_ICMP comment="VIASAT - ACCEPT ICMP FROM APPROVED NETWORKS" disabled=no;
/ip firewall filter add action=accept chain=input dst-port=3799 protocol=udp src-address-list=VIASAT_NETWORKS comment="VIASAT - ACCEPT INCOMING RADIUS SERVICE FROM VIASAT NETWORKS TO MIKROTIK" disabled=no;
/ip firewall filter add action=accept chain=input dst-port=8291,22 protocol=tcp src-address-list=VIASAT_NETWORKS comment="VIASAT - ACCEPT MGMT ACCESS FROM VIASAT NETWORKS TO MIKROTIK" disabled=no;
/ip firewall filter add action=accept chain=forward disabled=no src-address-list=VIASAT_NETWORKS comment="VIASAT - ACCEPT MGMT ACCESS FROM VIASAT NETWORKS TO DOWNSTREAM EQUIPMENT";
/ip firewall filter add action=accept chain=input comment="VIASAT - ACCEPT TCP BTEST FROM 12.108.226.139 (NAS PENSACOLA - BLDG 3910 - BARRACKS - CTL)" src-address=12.108.226.139 disabled=no;
:if ($HasMGMT = true) do={
	/ip firewall filter add action=accept chain=input connection-state=new dst-limit=10/1h,9,src-address/1h dst-port=8291,22 protocol=tcp src-address-list=LOCAL_MGMT_ACCESS comment="VIASAT - ACCEPT LOCAL MGMT NETWORKS FOR MGMT ACCESS" disabled=no;
	/ip firewall filter add action=drop chain=forward src-address-list=USER_NETWORK_GROUPA dst-address-list=LOCAL_MGMT_ACCESS comment="VIASAT - BLOCK END USERS FROM MGMT NETWORK" disabled=no;
};
/ip firewall filter add action=drop chain=forward src-address-list=USER_NETWORK_GROUPA dst-address-list=USER_NETWORK_GROUPB comment="VIASAT - CLIENT ISOLATION BETWEEN NETWORK GROUP A AND NETWORK GROUP B" disabled=no;
/ip firewall filter add action=drop chain=forward src-address-list=USER_NETWORK_GROUPB dst-address-list=USER_NETWORK_GROUPA comment="VIASAT - CLIENT ISOLATION BETWEEN NETWORK GROUP B AND NETWORK GROUP A" disabled=no;
/ip firewall filter add action=drop chain=input comment="VIASAT - DROP ALL OTHER INBOUND ACCESS";

:set MSG "FIREWALL FILTER CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE FIREWALL NAT
/ip firewall nat add action=redirect chain=dstnat comment="VIASAT - REDIRECT VIASATWIFI.COM TO WIFI1.VIASAT.COM VIA WEB PROXY" dst-address=199.204.5.36 dst-port=80 protocol=tcp to-ports=48678;
:if ($HasMGMT = true) do={
	/ip firewall nat add action=masquerade chain=srcnat comment="VIASAT - MASQ LOCAL MGMT SUBNETS" dst-address-list=!NAT_EXEMPT src-address-list=LOCAL_MGMT_MASQ;
};
/ip firewall nat add action=masquerade chain=srcnat comment="VIASAT - MASQ LOCAL USER SUBNETS" src-address-list=USER_MASQ_ACCESS;
/ip firewall nat add action=dst-nat comment="VIASAT - UDP BYPASS MIKROTIK DNS FOR ALL HOTSPOT USERS" chain=pre-hotspot disabled=yes dst-port=53 protocol=udp to-ports=53;

:set MSG "FIREWALL NAT CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CREATE FIREWALL MANGLE
:foreach Loc in=$LocNames do={
	/ip firewall mangle add action=change-ttl chain=forward disabled=no new-ttl=set:1 out-interface="$Loc_HS_BRIDGE" passthrough=yes comment="VIASAT - DISABLE ROUTERS ON $Loc HOTSPOT BRIDGE";
};

:set MSG "FIREWALL MANGLE CREATION HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# SETTING UP WEB PROXY FOR VIASATWIFI.COM TO WIFI1.VIASAT.COM
/ip proxy set enabled=yes max-cache-size=none parent-proxy=0.0.0.0 port=48678 src-address=0.0.0.0;
/ip proxy access add action=deny comment="VIASAT - REDIRECT WWW.VIASATWIFI.COM TO WIFI1.VIASAT.COM" dst-host="www.viasatwifi.com" redirect-to="wifi1.viasat.com";
/ip proxy access add action=deny comment="VIASAT - REDIRECT VIASATWIFI.COM TO WIFI1.VIASAT.COM" dst-host="viasatwifi.com" redirect-to="wifi1.viasat.com";
:set MSG "ADD IN WEB PROXY FOR VIASATWIFI.COM TO WIFI1.VIASAT.COM.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# IMPORT LOGIN PAGES
#:if ([:len [/file find where name="flash" type=disk]] > 0) do={
#	/tool fetch address=208.180.0.153 user=VWSStaging password=C0nfigur@tion_R0ut3R dst-path="/flash/hotspot/login.html/" mode=ftp src-path="/HotSpotLoginPages/login.html";
#	:delay 2s;
#	/tool fetch address=208.180.0.153 user=VWSStaging password=C0nfigur@tion_R0ut3R dst-path="/flash/hotspot/alogin.html/" mode=ftp src-path="/HotSpotLoginPages/alogin.html";
#	:delay 2s;
#	/tool fetch address=208.180.0.153 user=VWSStaging password=C0nfigur@tion_R0ut3R dst-path="/flash/hotspot/flogin.html/" mode=ftp src-path="/HotSpotLoginPages/flogin.html";
#	:delay 2s;
#} else={
#	/tool fetch address=208.180.0.153 user=VWSStaging password=C0nfigur@tion_R0ut3R dst-path="/hotspot/login.html/" mode=ftp src-path="/HotSpotLoginPages/login.html";
#	:delay 2s;
#	/tool fetch address=208.180.0.153 user=VWSStaging password=C0nfigur@tion_R0ut3R dst-path="/hotspot/alogin.html/" mode=ftp src-path="/HotSpotLoginPages/alogin.html";
#	:delay 2s;
#	/tool fetch address=208.180.0.153 user=VWSStaging password=C0nfigur@tion_R0ut3R dst-path="/hotspot/flogin.html/" mode=ftp src-path="/HotSpotLoginPages/flogin.html";
#	:delay 2s;
#};

:set MSG "IMPORTATION OF LOGIN PAGES HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# SET NEIGHBOR DISCOVERY
:foreach NeighborPort in=[/ip neighbor discovery find where name!="MGMT_BRIDGE"] do={
	/ip neighbor discovery set $NeighborPort discover=no;
};

:set MSG "SETTING NEIGHBOR DISCOVERY HAS BEEN COMPLETED.";
:log info "info hwid=$MSGHWID,msg=$MSG";
:put $MSG;

# CONFIG CLEANUP
/system script run VWSautoexport;
:foreach FileClean in=[/file find where name~"MikroTik_Licensee-Agnostic_Base-CTL-Config"] do={
	/file remove $FileClean;
};
};
