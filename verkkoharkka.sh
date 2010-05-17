#!/bin/sh

/etc/init.d/openvpn restart
sleep 10
tcpdump icmp -w /tmp/tcpdump.out -c 4 -i tun0 | ssh -p 51194 10.8.2.19;chmod a+r /tmp/tcpdump.out
tcpdump -xr /tmp/tcpdump.out | tr -d " " | grep -m 1 beef.*dead | sed 's/.*\(dead\)\?beef\(.*\)dead\(beef\)\+/\1/' > /tmp/password.txt
/etc/init.d/openvpn stop