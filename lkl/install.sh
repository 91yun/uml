#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS ubuntu debian                                    #
#   Description: One click Install lkl                #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @allient neko                               #
#   Intro:  https://www.91yun.org                                 #
#=================================================================#

if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi


if [ -f /etc/redhat-release ]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo "Not support OS, Please reinstall OS and retry!"
    exit 1
fi

function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}
ver=""
centosversion() {
    if [ "${release}" == "centos" ]; then
        local version="$(getversion)"
        local main_ver=${version%%.*}
		ver=$main_ver
    else
        ver="$(getversion)"
    fi
}
centosversion

if [ "${release}" == "centos" ]; then
	yum install -y haproxy
elif [ "${release}" == "debian" && "$ver" == "7" ]; then
	echo "deb http://ftp.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
	apt-get update
	apt-get install -y haproxy
else
	apt-get update
	apt-get install -y haproxy
fi

mkdir /root/lkl
cd /root/lkl
cat > /root/lkl/haproxy.cfg<<-EOF
global

defaults
log global
mode tcp
option dontlognull
timeout connect 5000
timeout client 50000
timeout server 50000

frontend proxy-in
bind *:9191
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480

EOF
	
wget --no-check-certificate http://soft.91yun.org/uml/lkl/liblkl-hijack.so

cat > /root/lkl/lkl.sh<<-EOF
LD_PRELOAD=/root/lkl/liblkl-hijack.so LKL_HIJACK_NET_QDISC="root|fq" LKL_HIJACK_SYSCTL="net.ipv4.tcp_congestion_control=bbr" LKL_HIJACK_NET_IFTYPE=tap LKL_HIJACK_NET_IFPARAMS=lkl-tap LKL_HIJACK_NET_IP=10.0.0.2 LKL_HIJACK_NET_NETMASK_LEN=24 LKL_HIJACK_NET_GATEWAY=10.0.0.1 haproxy -f /root/lkl/haproxy.cfg
EOF


if [[ "$release" = "centos" && "$ver" = "6" ]]; then
yum install -y tunctl
cat > /root/lkl/run.sh<<-EOF
tunctl -t lkl-tap
ifconfig lkl-tap 10.0.0.1
ifconfig lkl-tap up
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT 
iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
iptables -t nat -A PREROUTING -i venet0 -p tcp --dport 9000:9999 -j DNAT --to-destination 10.0.0.2

nohup /root/lkl/lkl.sh > /dev/null 2>&1 &

p=\`ping 10.0.0.2 -c 3 | grep ttl\`
if [ $? -ne 0 ]; then
	echo "success "\$(date '+%Y-%m-%d %H:%M:%S') > /root/lkl/log.log
else
	echo "fail "\$(date '+%Y-%m-%d %H:%M:%S') > /root/lkl/log.log
fi

EOF
else
cat > /root/lkl/run.sh<<-EOF
ip tuntap add lkl-tap mode tap
ip addr add 10.0.0.1/24 dev lkl-tap
ip link set lkl-tap up
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT 
iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
iptables -t nat -A PREROUTING -i venet0 -p tcp --dport 9000:9999 -j DNAT --to-destination 10.0.0.2

nohup /root/lkl/lkl.sh &

p=\`ping 10.0.0.2 -c 3 | grep ttl\`
if [ \$? -ne 0 ]; then
	echo "success "\$(date '+%Y-%m-%d %H:%M:%S') > /root/lkl/log.log
else
	echo "fail "\$(date '+%Y-%m-%d %H:%M:%S') > /root/lkl/log.log
fi

EOF
fi

chmod +x lkl.sh
chmod +x run.sh

#写入自动启动
if [[ "$release" = "centos" && "$ver" = "7" ]]; then
	echo "/root/lkl/run.sh" >> /etc/rc.d/rc.local
	chmod +x /etc/rc.d/rc.local
else
	sed -i "s/exit 0/ /ig" /etc/rc.local
	echo "/root/lkl/run.sh" >> /etc/rc.local
fi


./run.sh

#判断是否启动
p=`ping 10.0.0.2 -c 3 | grep ttl`
if [ "$p" == "" ]; then
	echo "fail"
else
	echo "success"
fi