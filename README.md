# bash_install_and_network_scripts
A colletction of Bash scripts.

Mostly very simple dynamic domain name based with a few useful other tools.

# installonlyoffice.sh
OnlyOffice is extremely difficult to get running without a Docker solution, I prefer to know how my systems are configured with simpler tools such as Aptitude, and prefer to save the (very minor) overhead from running another virtualized environment. There was very little real help publically available that I could find, so I opted to write a script to do it. Soon I will write something similar for paperless-ngx. This is not a commitment to help fix the world's technical issues.

Before spinning up a new container/VM/host figure out the passwords you'll need. This should absolutely be handled securely. I'll modify this script if there are any concerns on that front, but so far this is handled well in my opinion. Next, decide on a usable static IP, and unless you use your connector application exclusively locally or over VPN connect a DNS name, set up routing, and/or connect any reverse proxy you'll be using.. E.G. Accessing this server should be handled the same way you access your connector application, such as the OnlyOffice App on NextCloud. So, something like cloud.t.l.d and office.t.l.d could be used.

You'll be asked for/will need:
routing/VPN/DNS/reverse proxy set up
a static IP
root system user pass
two letter country code and host/domain name to generate a 10 year self signed cert
rabbitmq system user pass
rabbitmq onlyoffice user pass
postgres system user pass
postgresql onlyoffice user pass

While there are some error checks and the script should very quickly and easily perform all tasks mostly unattended it is mainly meant as a guide for install. As such troubleshooting will be up to you when something breaks. Contibuters welcome.

This was tested on a Debian 12.0-1 PVE 8.0.4 unpriveledged, nested, unfirewalled container with 4 cores, 2GB RAM, 4GB swap/pagefile per the recomendations. I used the standard 8GB disk size with ~2GB consumed. That being said, I see no immediate reason why any other Debian 12 install would have issues.
