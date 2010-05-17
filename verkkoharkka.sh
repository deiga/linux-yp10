#!/bin/sh

# Määritellään logittaja skriptille
log() { logger -t scriptname "$@"; echo "$@"; }

log "Beginning script"
log "Trying to up eth0"
# While-looppi, joka yrittää nostaa eth0, kunnes se on pystyssä
while [ `ifconfig | grep -c eth0` -lt 1 ]; do
	/sbin/ifconfig eth0 up;
done
log "eth0 up. Restarting openvpn"
# Käynnistetään openvpn uudestaan
/etc/init.d/openvpn restart

log "Waiting for tun0 to come up"
# Odotetaan kunnes tun0-interface on ylhäällä
while [ `ifconfig | grep -c tun0` -lt 1 ]; do
	sleep 1;
done

log "Checking if connection is alive."
ping -qc 3 10.8.2.19				# Kutsutaan palvelinta ja katsotaan onko siihen yhteys
if [ $? -ne 0 ]; then
    log "No response from server. Stopping script!"
    exit
fi

#
# Käsketään tcpdumppia kuuntelemaan tun0-interfacen liikennettä, joka on icmp-protokollalla ja lähettäjän osoite on
# 10.8.1.1. Näistä paketeista tulostetaan kaikki sisältö ja suodatetaan kunnes yksi paketti on kaapattu.
# Tulostust talletetaan tiedostoon /tmp/tcpdump.out
# tcpdump putkitetaan ssh:lle, joka ottaa tcp-yhteyden palvelimen 10.8.2.19 porttiin 51194
#
log "Dumping ICMP packets from 10.8.1.1 into /tmp/tcpdump.out"
tcpdump icmp and src host 10.8.1.1 -vvvx -c 1 -i tun0 > /tmp/tcpdump.out | ssh -p 51194 10.8.2.19;

chmod a+r /tmp/tcpdump.out; 	# Annetaan kaikille lukuoikeus kyseiseen tiedostoon
sleep 10						# Odotetaan 10 sekunttia, tämä tuntui olevan välttämätöntä, sillä ohjelma välillä ei toiminut ilman.

#
# Tulostetaan dump-tiedosto, siitä poistetaan välilyönnit ja grep:llä parsitaan yksi rivi, jolla on salasanamme.
# sed:llä parsitaan tämä salasana ja talletetaan tiedostoon /tmp/password.txt
#
log "Parsing password from dump-file."
cat /tmp/tcpdump.out | tr -d " " | grep -m 1 beef.*dead | sed 's/.*\(dead\)\?beef\(.*\)dead\(beef\)\+.*/\2/' > /tmp/password.txt
chmod 0600 /tmp/password.txt
log "Script completed, no errors detected."