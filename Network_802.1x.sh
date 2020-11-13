#!/bin/sh
set -x

wired_wirelss(){

config="/etc/wpa_supplicant/wpa_wiredsupplicant.conf"

cp  $config $config.backup

#NOTE :

	# if Authentication_Type = 0 means MD5
	# if Authentication_Type = 1 means TLS
	# if Authentication_Type = 2 means Tunneled TLS
	# if Authentication_Type = 3 means Protected EAP [PEAP]


Authentication_Type=`sqlite3 /data/sysconf.db "select AuthenticationType from Network8021x where AuthenticationType=3"`
echo $Authentication_Type

username=`sqlite3 /data/sysconf.db "select Username  from Network8021x where AuthenticationType=3"`
echo $username

identity=`sqlite3 /data/sysconf.db "select Identity  from Network8021x where AuthenticationType=3"`
echo $identity

temp=`sqlite3 /data/sysconf.db "select Password  from Network8021x where AuthenticationType=3"`
password=`encrypt $temp`
echo $password

usercrt=`sqlite3 /data/sysconf.db "select UserCertificate  from Network8021x where AuthenticationType=3"`
echo $usercrt

ca_crt=`sqlite3 /data/sysconf.db "select CACertificate  from Network8021x where AuthenticationType=3"`
echo $ca_crt

private_key=`sqlite3 /data/sysconf.db "select PrivateKey from Network8021x where AuthenticationType=3"`
echo $private_key

inner_authentication=`sqlite3 /data/sysconf.db "select InnerAuthentication from Network8021x where AuthenticationType=3"`
echo $inner_authentication

ask_password=`sqlite3 /data/sysconf.db "select AskPassword from Network8021x where AuthenticationType=3"`
echo $ask_password

network_type=`sqlite3 /data/sysconf.db "select NetworkType from Network8021x where AuthenticationType=3"`
echo $network_type

enable_security=`sqlite3 /data/sysconf.db "select EnableSecurity from Network8021x where AuthenticationType=3"`
echo $enable_security

PrivateKey_Password=`sqlite3 /data/sysconf.db "select PrivateKeyPassword from Network8021x where AuthenticationType=3"`
echo $PrivateKey_Password



run_wpa(){

#killall wpa_supplicant > /dev/null 2>&1

sleep 1

/sbin/wpa_supplicant -i eth0 -B -D wired -c /etc/wpa_supplicant/wpa_wiredsupplicant.conf -d -f /opt/debug

}


if [ "$Authentication_Type" == "0" ] ; then

echo "ap_scan=0
ctrl_interface=/var/run/wpa_supplicant

network={
        key_mgmt=IEEE8021X
        eap=MD5
        identity=\"$username\"
        password=\"$password\"
}"  > $config


elif [ "$Authentication_Type" == "1"  ] ; then

echo "ap_scan=0
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0

network={
        eapol_flags=0
        key_mgmt=IEEE8021X
        eap=TLS
        identity=\"$identity\"
        ca_cert=\"$ca_crt\"

}" >  $config



elif [ "$Authentication_Type" == "2" ] ; then

echo "ap_scan=0
ctrl_interface=/var/run/wpa_supplicant

network={
        key_mgmt=IEEE8021X
        eap=TTLS
        anonymous_identity=\"$identity\"
        ca_cert=\"$ca_crt\"
        phase2=\"$inner_authentication\"
        identity=\"$username\"
        password=\"$password\"
}" > $config


elif [ "$Authentication_Type" == "3" ] ; then

echo "ap_scan=0
ctrl_interface=/var/run/wpa_supplicant

network={
        key_mgmt=IEEE8021X
        eap=PEAP
        identity=\"$username\"
        password=\"$password\"
        ca_cert=\"$ca_crt\"
        eapol_flags=0
        anonymous_identity=\"$identity\"
        phase1=\"PEAPVER=0\"
        phase2=\"auth=$inner_authentication\"
        private_key_passwd=\"$PrivateKey_Password\"

}" > $config

run_wpa

fi

}

#configuring wireless netowork

grep -q wireless /proc/cmdline

       if [ "$?" -eq "0" ] ; then

                #collecting the device name of network connected
                networkdev=$(cat /proc/net/wireless | awk 'NR==3 {print;exit}' | awk '{print $1}' |  rev | cut -c 2- | rev)

                #ip address of the network connected
                ipaddr=$(ip route get 1.2.3.4 | awk '{print $7}')

                #configuring the network device

                ifconfig $networkdev $ipaddr netmask 255.255.255.0

                if [ "$?" -eq "0" ] ; then

                  echo "configured wired network with $networkdev :  $ipaddr"

                  wired_wirelss

	  	else
			echo "Wireless network is not Configured Properly..."



        fi
fi


#configuring the wired network

grep -q wired /proc/cmdline

if [ "$?" -eq "0" ] ; then

#collecting the device name of network connected
var=`cat /proc/net/dev | awk 'NR==3 {print;exit}' | awk '{print $1}'`
networkdev1=`echo ${var::-1}`

#ip address of the network connected
ipaddr1=`ip route get 1.2.3.4 | awk '{print $7}'`

#configuring the network device
ifconfig $networkdev1 $ipaddr1  netmask 255.255.255.0


if [ "$?" -eq "0" ] ; then

       echo "configured wired network with $networkdev :  $ipaddr"

          wired_wirelss

else
          echo "Wired network is not Configured Properly..."



        fi
fi


