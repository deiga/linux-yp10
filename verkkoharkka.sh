#!/bin/sh

while [ `ifconfig | grep -c eth0` -lt 1 ]; do
        /sbin/ifconfig eth0 up;
done

/etc/init.d/openvpn restart

while [ `ifconfig | grep -c tun0` -lt 1 ]; do
        sleep 1;
done

tcpdump icmp and src host 10.8.1.1 -vvvx -c 1 -i tun0 > /tmp/tcpdump.out | ssh -p 51194 10.8.2.19;
chmod a+r /tmp/tcpdump.out;
sleep 10
cat /tmp/tcpdump.out | tr -d " " | grep -m 1 beef.*dead | sed 's/.*\(dead\)\?beef\(.*\)dead\(beef\)\+/\2/' > /tmp/password.txt