# Harjoitustyö 3: Verkkoinfrastruktuuri #

## Tehtävänanto ##

Harjoitustyön tehtävänä on muodostaa OpenVPN-asiakastunneli laitoksen verkossa olevaan OpenVPN-päätepisteeseen openvpn.cs.helsinki.fi.  
Päätepisteen takana on tarjolla erillinen palvelin osoitteessa 10.8.2.19, johon on tarkoitus avata TCP-yhteys porttiin 51194.  
Yhteyden muodostuessa onnistuneesti 10.8.2.19 antaa tulosteessaan lisäohjeita. Lisäohjeita noudattamalla saat haltuusi salasanan, joka palautetaan työn mukana.

OpenVPN-yhteys suojataan kotikutoisella varmenteella ja omalla salausavaimella. Varmennepyyntö lähetetään Janin www-palveluun,  
joka allekirjoittaa saamansa pyynnön kotikutoisella juurivarmenteella (CA). Palvelu on tarjolla osoitteessa [http://db.cs.helsinki.fi/~jjaakkol/linux-yp/](http://db.cs.helsinki.fi/~jjaakkol/linux-yp/ "LYP -sivu").

Onnistunut ratkaisu toteutetaan siten, että kaikki vaiheet ovat automatisoituja. Tämä tarkoittaa sitä,  
että työasema käynnistyessään nostaa paikallisen verkkoliitännän pystyyn ja vasta sitten yrittää muodostaa OpenVPN-tunnelin.  
Tunnelin muodostumisen jälkeen OpenVPN käynnistää oman skriptin, joka suorittaa muut vaiheet.  
Ideana on kokeilla ensin toimenpiteet käsin ja sitten automatisoida ne. Automatisoinnin lopputuloksena järjestelmä on voinut kirjoittaa salasanan esim. tiedostoon /tmp/password.txt.

Palautukseen tulee liitää mainittu salasana, OpenVPN:n konfigurointitiedosto sekä automatisointiin tarvittavat shell-skriptit.   Deadline on maanantaina 17.5. klo 16:00. Palauttamisessa käytetään tuttua härveliä osoitteessa [http://db.cs.helsinki.fi/~jjaakkol/linux-return/](http://db.cs.helsinki.fi/~jjaakkol/linux-return/ "LYP -palautukset").

Arvostelussa huomioidaan

* ratkaisun dokumentointi:
	* ymmärtäisikö kolleega mitkä toimenpiteet olet tehnyt?
	* konfigurointi- ja komentorivitiedostojen kommentointi
* automaation vikasietoisuus.
* tunnelin tietoturvallisuus
	* tiedostoilla oikeat omistus-, luku- ja kirjoitusoikeudet

Vinkkejä

* Työ kannattaa aloittaa selailemalla man-sivu läpi
* Ongelmiin törmätessä ensimmäinen työkalu on /var/log/syslog tai openvpn:n ajo ei-daemonina


## Oppimispäiväkirja ##


Harjoitustyön aloittaminen tuntuu vaikealta. Kun luennoille ei päässyt mukaan,
niin "luentokalvojen" ymmärtäminen vaikeaa ja työlästä.

Luentokalvojen sijaan aloitin lukemalla OpenVPN:än man sivuja. Kasasin sieltä komennon millä saan vpn yhteyden päälle.

Sitten loin uuden sertifikaatin avaimineen:

* `openssl req -nodes -new -keyout mycert.key -out mycert.csr`

Allekirjoitutin avaimen verkkopalvelussa.
Sitten testasin toimiiko keräämäni komento:

* `sudo openvpn --remote openvpn.cs.helsinki.fi --tls-client --ca /home/deiga/linuxyp-CA.pem --cert /home/deiga/verkkolyp.pem --key /home/deiga/verkkolyp_key.pem --verb 9 --dev tun --client`

Tuossa on lopullinen komento, jouduin muutaman kerran testaamaan komentoa ja korjaamaan ohjelman antamat virheet.

Jatkoa varten luen luentojen materiaalit läpi. Materiaaleista on tosi vaikeaa saada mitään irti.

Lisätty route seuraavalla komennolla:

* `ip route add 10.8.2.19 via 10.8.1.34`

Nyt saa myös pingiin vastauksen palvelimelta!

Seuraavaksi päätin siirtää kaikki optiot omaan konfiguraatiotiedostoon ja saada pelittämään sillä.  
Aluksi ei meinannut millään toimia, kunnes huomasin että fix-routes.sh -skriptin ajaminen ei toiminut ollenkaan.  
Selvisi, että tun0 interfacen IP-osoite muuttuu joka yhteydellä. Selvittämään siis mikä ratkaisis ongelman, ja löytyihän se sieltä:

* `ip route add 10.8.2.19 dev tun0`

Seuraavkasi otetaan sitten palvelimelle yhteys TCP porttiin 51194

* `ssh -p 51194 -v 10.8.2.19`

Sitten aloinkin ihmettelemään miten saisi tiedot mitkä palvelin lähetti. Aloin katsella Wiresharkilla paketteja ja sieltähän ne löytyivätkin.  
Seuraavaksi luin tcpdump:n man-sivut läpi, jotta saisi komentorivityökalun toimimaan.  
Pitkän trial-and-error -kokeilun jälkeen alkoi tcpdump tuottamaan sen näköistä dataa, että sillä tekisikin jo jotain.

* sudo tcpdump icmp -w tcpdump.out -c 4 -i tun0

Seuraavaksi aloinkin miettimään, miten salasanan saisi paketista ulos. Ensimmäisenä tule grep mieleen, mutta se ei tyydyttänyt tarpeitani,  
ja sain avuliasta neuvoa käyttämään sed:iä. Lopputulos on kutakuinkin tämä:

* sudo tcpdump -xr tcpdump.out | grep -m 1 beef.*dead | sed 's/.*dead\sbeef\s\(.*\)dead\sbeef/\1/'

Tuossa siis käytän grep:iä siihen että se valitsee yhden ainoan sopivan rivin, josta sed:llä sitten parsitaan itse salasana.

Nyt kun kaikki komennot toimivat, niin olikin aika rupea automatisointia miettimään.  
Laitettiin kaikki komennot skriptiin peräkkäin ja katsotaan mitä tapahtuu.  
Noh, eihän se toiminut, ei löytänyt tcpdump interface:a ollenkaan. Eli skripti on nopeampi kuin vpn-yhteys.

* Lisäsin `sleep 10` ja heti alkoi pelittämään.

Tämä korjasikin kaikki ongelmat ja skripti pyöri nätisti loppuun. Yllätyksekseni /tmp/password.txt olikin tyhjä.  
sed palauttaa tyhjää ja samoin grep, mikä hajosi. Dataa katseltuani huomasin, että se oli huomattavasti erillaista, kuin aikasempi data.  
Korjasin regexpini ja kaikki toimi taas:

* `sed 's/.*dead\sbeef\s\(.*\)dead\sbeef/\1/' > /tmp/password.txt`

Skriptin automatisointi bash-skriptiksi onnistui hyvin(verkkoharkka.sh).  
Openvpn up-skriptinä se ei onnistunut. Jostain syystä tcpdump ei aina toiminut oikein, eikä se "koskaan" päässyt salasanan parsimis-vaiheeseen.  
Kun lisäsi käskyt suoraan rc.local:iin, ei sekään toiminut halutulla tavalla, mutta kun lisäsi skriptin kutsun rc.localiin, niin tuntuu toimivan.

Lopulliset skriptit ja käskyt löytyvät tämän tiedoston lopusta.

### Notes ###

**Automaation vikasietoisuus:**

*	Automaatio lopettaa toiminnan, jos jostain syystä ssh yhteys epäonnistuu
*	Automaatio ei pysty parsimaan salasanaa, jos tcpdump ei saa yhtään pakettia kiinni, skripti ei myöskään etene tässä tapauksessa.

**Tunnelin tietoturvallisuus:**

*	Tiedostooikeudet:
	*	/usr/bin/verkkoharkka.sh 			0755
	*	/etc/openvpn/*.pem 					0700
	*	/etc/openvpn/fix-route.sh			0755
	*	/etc/openvpn/openvpn-client.conf	0644
	*	/tmp/password.txt					0600


**Salasana:** 76fdf7f

#### verkkoharkka.sh ####

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

---------

#### openvpn-client.conf ####

	dev tun								# Asetetaan openvpn käyttämän tun-interfacea
	remote openvpn.cs.helsinki.fi		# Palvelimen osoite
	client								# Määritellään openvpn toimimaan client modessa, komentoon sisältyy komento pull
	ca /etc/openvpn/linuxyp-CA.pem		# Sertifikaatti varmenteen polku
	key /etc/openvpn/verkkolyp_key.pem	# Sertifikaation avaimen polku
	cert /etc/openvpn/verkkolyp.pem		# Allekirjoitettu sertifikaatti
	verb 4								# Verboosi output, virheidentarkistusta varte 
	tls-client							# Määritellään olevamme TLS-clientti yhteydessä
	up /etc/openvpn/fix-route.sh		# Skripti mikä ajetaan, kun TCP/UDP -yhteys on luotu
	script-security 2					# Komento antaa oikeudet ajaa ulkopuolisia skriptejä  

---------

#### fix-route.sh ####

	#!/bin/sh  
	ip route add 10.8.2.19 dev tun0  	# Lisätään route osoitteeseen 10.8.2.19 laitteen tun0 kautta  


---------


#### rc.local ####

	#!/bin/sh -e
	#
	# rc.local
	#
	# This script is executed at the end of each multiuser runlevel.
	# Make sure that the script will "exit 0" on success or any other
	# value on error.
	#
	# In order to enable or disable this script just change the execution
	# bits.
	#
	# By default this script does nothing.
	/usr/bin/verkkoharkka.sh
	exit 0
