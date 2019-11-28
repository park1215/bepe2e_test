# Written By: Greg Bolton
# Last Updated On: 1/21/2019
# Version: 2.1.3
# Summary: This script will be used as a netinstall on MikroTiks that will be used at WDA locations.
# Documentation File:
{
# VARIABLES
#================================================
#DO NOT CHANGE ANYTHING ON THIS LINE OR BELOW!
#================================================
:local BoardType [/system routerboard get model];
:local WANDevice true;
:local HWID [/interface ethernet get 0 mac-address];
:local Level [/system license get nlevel];
:local WLANMode;


# SET SYSTEM IDENTITY
/system identity set name=$HWID;
# CREATE LOGGING ACTIONS AND LOGGING
/system logging action add target=remote bsd-syslog=no name=VIASATSYSLOGV1 remote=63.79.12.172 remote-port=514 src-address=0.0.0.0 syslog-facility=daemon syslog-severity=auto;
/system logging add action=VIASATSYSLOGV1 disabled=no prefix="" topics=script,info;
# CREATE BRIDGES
:if ($WANDevice = false) do={
	/interface bridge add name=MGMT_BRIDGE auto-mac=no admin-mac=$HWID arp=enabled protocol-mode=none disabled=no comment="MANAGEMENT BRIDGE";
};
# SET BASE WLAN
:if ([/system package get [find where name=wireless] disabled] = no) do={
	:if ($Level = 3) do={
		:set WLANMode "bridge";
	} else={
		:set WLANMode "ap-bridge";
	};
	:foreach WLAN in=[/interface wireless find where band~"5"] do={
		/interface wireless set $WLAN band=5ghz-onlyn channel-width=20/40mhz-Ce rx-chains=0,1 tx-chains=0,1 disabled=no frequency="auto" nv2-preshared-key=ST4y0FFmyBr!dge nv2-security=enabled mode="$WLANMode" ssid="WDA_WIRELESS_BACKHAUL" wds-default-bridge=MGMT_BRIDGE wireless-protocol=nv2 wmm-support=enabled tx-power-mode=all-rates-fixed tx-power="18" hide-ssid=no;
	};
	:if ([:len [/interface wireless find where band~"2"]] > 0) do={
		/interface wireless set [/interface wireless find where band~"2"] disabled=yes;
	};
};
# CREATE PHONE HOME VPN
:if ($WANDevice = true) do={
	/interface l2tp-client add add-default-route=no allow=mschap2 connect-to="miranda.bcs-dev.viasat.io" name=VWS_VPN password="KGgvdjFNI84gdje" profile=default-encryption user="$HWID" keepalive-timeout=60 comment="PHONE HOME VPN - DEV" disabled=no;
};
# BRIDGE PORTS ASSIGNMENTS
:if ($WANDevice = false) do={
	:foreach Int in=[/interface ethernet find] do={
		/interface bridge port add interface=[/interface ethernet get $Int name] bridge="MGMT_BRIDGE";
	};
	:if ([/system package get [find where name=wireless] disabled] = no) do={
		:foreach Int in=[/interface wireless find] do={
			/interface bridge port add interface=[/interface wireless get $Int name] bridge="MGMT_BRIDGE";
		};
	};
};

# Dis-associating ether5 from MGMT_BRIDGE for BEPE2E
#/interface bridge port remove numbers=4

#BEPE2E Modification TO add MGMT on ether5
#/ip address add address=10.86.155.57 netmask=255.255.255.0 interface=ether5;

# CREATE DHCP CLIENT
:if ($WANDevice = true) do={
	/ip dhcp-client add interface=ether1 add-default-route=yes default-route-distance=1 use-peer-dns=no use-peer-ntp=no disabled=no comment="PHONE HOME DHCP CLIENT";
} else={
	/ip dhcp-client add interface="MGMT_BRIDGE" add-default-route=yes default-route-distance=1 use-peer-dns=yes use-peer-ntp=no disabled=no comment="PHONE HOME DHCP CLIENT";
};
# CREATE ROUTES
:if ($WANDevice = true) do={
	/ip route add comment="PHONE HOME VPN ROUTE" disabled=no distance=1 dst-address=10.59.8.45 gateway=10.62.192.1 check-gateway=ping;
	/ip route add comment="PHONE HOME VPN ROUTE" disabled=no distance=1 dst-address=10.59.2.73 gateway=10.62.192.1 check-gateway=ping;
    /ip route add comment="N2 MGMT NETWORK GW ROUTE" dst-address=10.86.155.0/24 gateway=10.86.155.1
    /ip route add comment="SURFBEAM VPN Access ROUTE" dst-address=172.30.168.0/24 gateway=10.86.155.1
    /ip route add comment="BEPE2E AWS VPC ROUTE" dst-address=10.43.164.0/24 gateway=10.86.155.1
};
# SET LOCAL LOGIN + BEP VWSAdmin user
/user add comment="PHONE HOME LOGIN USER" group=full name="PHONEHOME" password="S9cwxQc421cB";
:delay 1s;
:foreach UserRemove in=[/user find where name!="PHONEHOME"] do={
	/user remove $UserRemove;
};

# CREATE SCHEDULERS
/system scheduler add comment="PHONE HOME SCHEDULER" interval=2m name=CHECKIN on-event="CHECKIN" start-time=startup;
:if ([/system package get [find where name=wireless] disabled] = no) do={
	:if ([:len [/interface wireless find where ssid="WDA_WIRELESS_BACKHAUL"]] > 0) do={
		/system scheduler add comment="PHONE HOME WIRELESS BACKHAUL AUTO ROTATE SCHEDULER" interval=2m name=VIASAT_WIRELESS_FIX on-event="VIASAT_WIRELESS_FIX" start-time=startup;
	};
};
# CREATE SCRIPTS
/system script add comment="PHONE HOME SCRIPT" name=CHECKIN source="# This script is designed to send information to TRACKOS, letting CURE know that this device is ready to be configured.  Once CURE configuration is completed, this script can be removed.\r\n{\r\n:local MSGHWID [/system identity get name];\r\n:local MSG;\r\n:local CurrentROS1 [/system resource get version];\r\n:local CurrentFirmware [/system routerboard get current-firmware];\r\n:local UpgradeFirmware [/system routerboard get upgrade-firmware];\r\n:local AccessAddress;\r\n:if (\$CurrentROS1 ~ \" \") do={\r\n\t:set CurrentROS1 [:pick \$CurrentROS1 0 [:find \$CurrentROS1 \" \"]];\r\n};\r\n:if ([:len [/interface find where name=\"VWS_VPN\"]] > 0) do={\r\n\t:set AccessAddress [/ip address get [find where interface=\"VWS_VPN\"] address];\r\n} else={\r\n\t:set AccessAddress [/ip address get [find where interface=\"MGMT_BRIDGE\"] address];\r\n};\r\n:set AccessAddress [:pick \$AccessAddress 0 [:find \$AccessAddress \"/\"]];\r\n:set MSG \"PHONE_HOME-MAC_ADDRESS=\$MSGHWID,CURRENT_ROS=\$CurrentROS1,CURRENT_FIRMWARE=\$CurrentFirmware,UPGRADE_FIRMWARE=\$UpgradeFirmware,ACCESS_ADDRESS=\$AccessAddress\"\r\n:log info \"info hwid=\$MSGHWID,msg=\$MSG\";\r\n};";
:if ([/system package get [find where name=wireless] disabled] = no) do={
	:if ([:len [/interface wireless find where ssid="WDA_WIRELESS_BACKHAUL"]] > 0) do={
		/system script add comment="PHONE HOME SCRIPT" name=VIASAT_WIRELESS_FIX source="# This script is designed to let two bridges automatically figure out which one is the root and\_which one is the remote.  Once this has been fully essablished this script can be removed.\r\n{\r\n:local MoveToRemote false;\r\n:local GatewayAddress;\r\n:local CTLMAC;\r\n:local UplinkPort;\r\n:local Level [/system license get nlevel];\r\n:local WLANMode;\r\n:if (\$Level = 3) do={\r\n\t:set WLANMode \"bridge\";\r\n} else={\r\n\t:set WLANMode \"ap-bridge\";\r\n};\r\n:if ([/ip dhcp-client get [find where interface=MGMT_BRIDGE] status] ~ \"searching\") do={\r\n\t:foreach WLAN in=[/interface wireless find where ssid=\"WDA_WIRELESS_BACKHAUL\" mode=\"\$WLANMode\"] do={\r\n\t\t/interface wireless set \$WLAN mode=station-bridge;\r\n\t\t:set MoveToRemote true;\r\n\t};\r\n\t:if (\$MoveToRemote = false) do={\r\n\t\t:foreach WLAN in=[/interface wireless find where ssid=\"WDA_WIRELESS_BACKHAUL\" mode=\"station-bridge\"] do={\r\n\t\t\t/interface wireless set \$WLAN mode=\"\$WLANMode\";\r\n\t\t};\r\n\t};\r\n} else={\r\n\t:set GatewayAddress [/ip dhcp-client get [find where interface=MGMT_BRIDGE] gateway];\r\n\t:set CTLMAC [/ip arp get [find where address=\"\$GatewayAddress\"] mac-address];\r\n\t:set UplinkPort [/interface bridge host get [find where mac-address=\"\$CTLMAC\"] on-interface];\r\n\t:if (\$UplinkPort ~ \"ether\") do={\r\n\t\t:foreach WLAN in=[/interface wireless find where ssid=\"WDA_WIRELESS_BACKHAUL\" mode=\"station-bridge\"] do={\r\n\t\t\t/interface wireless set \$WLAN mode=\"\$WLANMode\";\r\n\t\t};\r\n\t} else={\r\n\t\t:foreach WLAN in=[/interface wireless find where ssid=\"WDA_WIRELESS_BACKHAUL\" mode=\"\$WLANMode\"] do={\r\n\t\t\t/interface wireless set \$WLAN mode=station-bridge;\r\n\t\t};\r\n\t};\r\n};\r\n};";
	};
};
# SETUP SNMP
/snmp community set [find default=yes] authentication-password="59B*CRqBX7rs" encryption-password="tV*80^JaTPxH" name="VWSsnmpV3" security=authorized;
/snmp set enabled=yes trap-version=3;
# CREATE FIREWALL FILTERS
:if ($WANDevice = true) do={
	/ip firewall filter add action=accept chain=input connection-state=established,related comment="PHONE HOME ACCEPT INPUT PACKETS WITH RELATED OR ESTABLISHED CONNECTION STATE" disabled=no;
	/ip firewall filter add action=accept chain=input comment="PHONE HOME VPN ACCESS" in-interface=VWS_VPN;
	/ip dns set allow-remote-requests=yes servers="8.8.8.8,8.8.4.4";
};
# SET NTP SERVER
/system ntp client set enabled=yes server-dns-names=TIME.NNU.COM;

};
