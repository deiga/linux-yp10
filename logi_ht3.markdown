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

Skriptin automatisointi bash-skriptiksi onnistui hyvin. Openvpn --up -skriptiksi en onnistunut sitä saamaan laitettua.


### Notes ###

**Salasana:** 76fdf7f

#### verkkoharkka.sh ####

>\#!/bin/sh

>while [ `ifconfig | grep -c eth0` -lt 1 ]; do
>        /sbin/ifconfig eth0 up;
>done

>/etc/init.d/openvpn restart

>while [ `ifconfig | grep -c tun0` -lt 1 ]; do
>        sleep 1;
>done

>tcpdump icmp and src host 10.8.1.1 -vvvx -c 1 -i tun0 > /tmp/tcpdump.out | ssh -p 51194 10.8.2.19;
>chmod a+r /tmp/tcpdump.out;
>sleep 10
>cat /tmp/tcpdump.out | tr -d " " | grep -m 1 beef.*dead | sed 's/.*\(dead\)\?beef\(.*\)dead\(beef\)\+/\2/' > /tmp/password.txt


---------

#### openvpn-client.conf ####

>dev tun
>remote openvpn.cs.helsinki.fi
>client
>pull
>ca /etc/openvpn/linuxyp-CA.pem
>key /etc/openvpn/verkkolyp_key.pem
>cert /etc/openvpn/verkkolyp.pem
>verb 9
>tls-client
>up /etc/openvpn/fix-route.sh
>mute 20
>script-security 2

---------

#### fix-route.sh ####

>\#!/bin/sh  
>ip route add 10.8.2.19 dev tun0  

---------
