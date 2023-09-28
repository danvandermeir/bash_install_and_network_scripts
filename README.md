# bash_install_and_network_scripts
A colletction of Bash scripts.

Installing OnlyOffice is extremely difficult without Docker with very little real help publically available that I could find, so I opted to write a script to do it. Soon I will write something similar for paperless-ngx.

While there are some error checks in the script it is mainly meant as a guide for install, so troubleshooting will be up to you when something breaks. Contibuters welcome.

This was tested on a Debian 12.0-1 PVE 8.0.4 unpriveledged, nested, unfirewalled container with 4 cores, 2GB RAM, 4GB swap/pagefile per the recomendations. I used the standard 8GB disk size with ~2GB consumed.
