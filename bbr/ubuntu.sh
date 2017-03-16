#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  ubuntu & debian                                    #
#   Description: One click Install UML for bbr+ssr                #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @allient neko @Jacky Bao                              #
#   Intro:  https://www.91yun.org                                 #
#=================================================================#



apt-get update
apt-get install -y tunctl uml-utilities screen


wget http://soft.91yun.org/uml/91yun/uml-ssr-64.tar.gz
tar zfvx uml-ssr-64.tar.gz
cd uml-ssr-64
cur_dir=`pwd`
cat > run.sh<<-EOF
#!/bin/sh
export HOME=/root
start(){
	ip tuntap add tap1 mode tap 
	ip addr add 10.0.0.1/24 dev tap1
	ip link set tap1 up 
	echo 1 > /proc/sys/net/ipv4/ip_forward
	iptables -P FORWARD ACCEPT 
	iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
	iptables -I FORWARD -i tap1 -j ACCEPT
	iptables -I FORWARD -o tap1 -j ACCEPT
	iptables -t nat -A PREROUTING -i venet0 -p tcp --dport 9191 -j DNAT --to-destination 10.0.0.2
	iptables -t nat -A PREROUTING -i venet0 -p udp --dport 9191 -j DNAT --to-destination 10.0.0.2
	screen -dmS uml ${cur_dir}/vmlinux ubda=${cur_dir}/alpine-x64 eth0=tuntap,tap1 mem=64m con=pts con1=fd:0,fd:1
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

echo "/bin/bash ${cur_dir}/run.sh start" >> /etc/rc.local
sed -i "s/exit 0/ /ig" /etc/rc.local

chmod +x /etc/rc.local
umlstatus=$(ps aux | grep vmlinux)
if [ "$umlstatus" == "" ]; then
	echo "some thing error!"
else
	echo "uml install success!"
fi	

