#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6,7, Debian, Ubuntu                  #
#   Description: One click Install UML for bbr+ssr                #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @allient                                              #
#   Intro:  https://www.91yun.org/archives/2079                   #
#=================================================================#



# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi




if [ -f /etc/redhat-release ];then
	OS='CentOS'
elif [ ! -z "`cat /etc/issue | grep bian`" ];then
	OS='Debian'
elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
	OS='Ubuntu'
else
	echo "Not support OS, Please reinstall OS and retry!"
	exit 1
fi





if [ "$OS" == 'CentOS' ]; then
	yum install -y tunctl uml-utilities screen
else
	apt-get update -y 
	apt-get install -y uml-utilities screen
fi


wget http://soft.91yun.org/uml/91yun/uml-ssr-64.tar.gz
tar zfvx uml-ssr-64.tar.gz
cd uml-ssr-64
cur_dir=`pwd`
cat > run.sh<<-EOF
tunctl -t tap1
ifconfig tap1 10.0.0.1
ifconfig tap1 up
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -P FORWARD ACCEPT 
iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
iptables -I FORWARD -i tap1 -j ACCEPT
iptables -I FORWARD -o tap1 -j ACCEPT
iptables -t nat -A PREROUTING -i venet0 -p tcp --dport 9191 -j DNAT --to-destination 10.0.0.2
iptables -t nat -A PREROUTING -i venet0 -p udp --dport 9191 -j DNAT --to-destination 10.0.0.2

nohup ${cur_dir}/vmlinux ubda=${cur_dir}/alpine-x64 eth0=tuntap,tap1 mem=64m & disown
sleep 1
ps aux | grep "vmlinux"
if [ $? -eq 0 ]; then
	echo "all things done!"
	echo "you can use command to login uml:"
	echo "screen /dev/pts/1"
	echo "user:root password:root"
else
	echo "some things error"
fi	

EOF
chmod +x run.sh
bash run.sh

