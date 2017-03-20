#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6                                    #
#   Description: One click Install UML for bbr+ssr                #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @allient neko @Jacky Bao                              #
#   Intro:  https://www.91yun.org                                 #
#=================================================================#




yum install -y tunctl uml-utilities screen


wget http://soft.91yun.org/uml/91yun/uml-centos-64.tar.gz
tar zfvx uml-centos-64.tar.gz
cd uml-centos-64
cur_dir=`pwd`
cat > run.sh<<-EOF
#!/bin/sh
export HOME=/root
start(){
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
	screen -dmS uml ${cur_dir}/vmlinux ubda=${cur_dir}/CentOS64_fs eth0=tuntap,tap1 mem=256m
	ps aux | grep vmlinux
}

stop(){
    kill \$( ps aux | grep vmlinux )
	ifconfig tap1 down
}

status(){

	screen -r \$(screen -list | grep uml | awk 'NR==1{print \$1}')
	
}
action=\$1
#[ -z \$1 ] && action=status
case "\$action" in
'start')
    start
    ;;
'stop')
    stop
    ;;
'status')
    status
    ;;
'restart')
    stop
    start
    ;;
*)
    echo "Usage: \$0 { start | stop | restart | status }"
    ;;
esac
exit
EOF

#创建和uml的共享目录
mkdir -p /root/umlshare

chmod +x run.sh
bash run.sh start

echo "/bin/bash ${cur_dir}/run.sh start" >> /etc/rc.d/rc.local
sed -i "s/exit 0/ /ig" /etc/rc.local

chmod +x /etc/rc.d/rc.local
umlstatus=$(ps aux | grep vmlinux)
if [ "$umlstatus" == "" ]; then
	echo "some thing error!"
else
	echo "uml install success!"
fi