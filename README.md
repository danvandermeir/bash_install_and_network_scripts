# bash_install_and_network_scripts
A colletction of Bash scripts.

Mostly very simple dynamic domain name based with a few useful other tools.

# netmap.sh
I drop this into /usr/local/bin with 755 permissions and add a line to any Wireguard .conf files I have so that any network overlaps I have are taken care of. Just make sure to check /etc/wireguard for any new network translations after any up/downs.

`PostUp = /usr/local/bin/netmap.sh %i`

# installonlyoffice.sh
why?

OnlyOffice is extremely difficult to get running without a Docker solution. In addition I prefer to know how my systems are configured with simpler tools such as Aptitude, and prefer to save the (very minor) overhead from running another virtualized environment. There was very little real help publically available that I could find, so I opted to write a script to perform an OnlyOffice install. Soon I will write something similar for paperless-ngx. This is not a commitment to help fix the world's technical issues.

Before spinning up a new container/VM/host figure out the passwords you'll need. This should absolutely be handled securely. I'll modify this script if there are any concerns on that front, but so far this is handled well in my opinion. Next, decide on a usable static IP. Unless you use your connector application exclusively locally or over VPN connect a DNS name, set up routing, and/or connect any reverse proxy you'll be using.. E.G. Accessing this server should be handled the same way you access your connector application, such as the OnlyOffice App on NextCloud. So, something like cloud.t.l.d and office.t.l.d could be used.

You'll be asked for/will need:
1. routing/VPN/DNS/reverse proxy set up (proper connectivity)
2. a static IP
3. root system user pass
3. two letter country code and host/domain name to generate a 10 year self signed cert
4. rabbitmq system user pass
5. rabbitmq onlyoffice user pass
8. postgres system user pass
7. postgresql onlyoffice user pass

While there are some error checks and the script should very quickly and easily perform all tasks mostly unattended it is mainly meant as a guide for install. As such troubleshooting will be up to you when something breaks. Contibuters welcome.

This was tested on a Debian 12.0-1 PVE 8.0.4 unpriveledged, nested, unfirewalled container with 4 cores, 2GB RAM, 4GB swap/pagefile per the recomendations. I used the standard 8GB disk size with ~2GB consumed. That being said, I see no immediate reason why any other Debian 12 install would have issues.
