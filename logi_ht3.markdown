# Harjoitustyö 3: Verkkoinfrastruktuuri #

## Tehtävänanto ##

Harjoitustyön tehtävänä on muodostaa OpenVPN-asiakastunneli laitoksen verkossa olevaan OpenVPN-päätepisteeseen openvpn.cs.helsinki.fi. Päätepisteen takana on tarjolla erillinen palvelin osoitteessa 10.8.2.19, johon on tarkoitus avata TCP-yhteys porttiin 51194. Yhteyden muodostuessa onnistuneesti 10.8.2.19 antaa tulosteessaan lisäohjeita. Lisäohjeita noudattamalla saat haltuusi salasanan, joka palautetaan työn mukana.

OpenVPN-yhteys suojataan kotikutoisella varmenteella ja omalla salausavaimella. Varmennepyyntö lähetetään Janin www-palveluun, joka allekirjoittaa saamansa pyynnön kotikutoisella juurivarmenteella (CA). Palvelu on tarjolla osoitteessa [http://db.cs.helsinki.fi/~jjaakkol/linux-yp/](http://db.cs.helsinki.fi/~jjaakkol/linux-yp/ "LYP -sivu").

Onnistunut ratkaisu toteutetaan siten, että kaikki vaiheet ovat automatisoituja. Tämä tarkoittaa sitä, että työasema käynnistyessään nostaa paikallisen verkkoliitännän pystyyn ja vasta sitten yrittää muodostaa OpenVPN-tunnelin. Tunnelin muodostumisen jälkeen OpenVPN käynnistää oman skriptin, joka suorittaa muut vaiheet. Ideana on kokeilla ensin toimenpiteet käsin ja sitten automatisoida ne. Automatisoinnin lopputuloksena järjestelmä on voinut kirjoittaa salasanan esim. tiedostoon /tmp/password.txt.

Palautukseen tulee liitää mainittu salasana, OpenVPN:n konfigurointitiedosto sekä automatisointiin tarvittavat shell-skriptit. Deadline on maanantaina 17.5. klo 16:00. Palauttamisessa käytetään tuttua härveliä osoitteessa [http://db.cs.helsinki.fi/~jjaakkol/linux-return/](http://db.cs.helsinki.fi/~jjaakkol/linux-return/ "LYP -palautkset").

Arvostelussa huomioidaan

*	ratkaisun dokumentointi:
	*	ymmärtäisikö kolleega mitkä toimenpiteet olet tehnyt?
	*	konfigurointi- ja komentorivitiedostojen kommentointi
*	automaation vikasietoisuus.
*	tunnelin tietoturvallisuus
	*	tiedostoilla oikeat omistus-, luku- ja kirjoitusoikeudet

Vinkkejä

*	Työ kannattaa aloittaa selailemalla man-sivu läpi
*	Ongelmiin törmätessä ensimmäinen työkalu on /var/log/syslog tai openvpn:n ajo ei-daemonina


## Oppimispäiväkirja ##

