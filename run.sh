#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6,7, Debian, Ubuntu                  #
#   Description: One click Install UML for bbr+ssr                #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @allient <https://twitter.com/breakwa11>              #
#   Intro:  https://www.91yun.org/archives/2079                   #
#=================================================================#

tunctl -t tap1
ifconfig tap1 10.0.0.1
ifconfig tap1 up

iptables -P FORWARD ACCEPT 
iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
iptables -I FORWARD -i tap1 -j ACCEPT
iptables -I FORWARD -o tap1 -j ACCEPT

nohup ./vmlinux ubda=./alpine-x64 eth0=tuntap,tap1 mem=64m & disown	