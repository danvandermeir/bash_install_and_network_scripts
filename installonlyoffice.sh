#!/bin/bash
IFS=$'\n'
if [[ $EUID -ne 0 ]]; then
	printf 'Not root! Rerunning with sudo!\n'
	exec sudo /bin/bash "$0" "$@"
	exit 0
fi
if apt list --installed 2>/dev/null|grep -qi onlyoffice-documentserver; then
    echo 'OnlyOffice appears to have already been installed. It should be easy to update with "apt update; apt upgrade". Alternatively, this script generally runs very quickly, consider creating a fresh container with the recommended 4 cores, 2GB memory, 4GB swap/pagefile to install OnlyOffice.'
    exit 1
fi
IP=$(ip a show dev `ip r|grep default|rev|cut -d' ' -f2|rev`|grep -w inet|cut -d'/' -f1|rev|cut -d' ' -f1|rev)
if ! grep -Rqi "$IP" /etc/network/; then
    echo 'No static IP defined! Set this first!'
    exit 1
fi
CIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
apt update
apt -y upgrade
apt -y dist-upgrade
apt -y install tree nmap sudo tmux screen lsof redis-server rabbitmq-server gnupg2 wget curl postgresql nginx nginx-extras openssl sed x11-common xfonts-encodings libfontenc1 fonts-dejavu-extra cabextract xfonts-utils libcurl4 libxml2 fonts-dejavu fonts-liberation  ttf-mscorefonts-installer fonts-crosextra-carlito fonts-takao-gothic fonts-opensymbol
systemctl start rabbitmq-server
systemctl start redis-server
systemctl start postgresql
printf 'Server 2 letter country code for self signed cert: '
read -s userCC
echo ' '
printf 'Server hostname/public IP for self signed cert: '
read -s hpip
echo ' '
printf "system user rabbitmq password: "
read -rs rabbitmqsysusepass
echo ' '
echo -e "$rabbitmqsysusepass\n$rabbitmqsysusepass"|passwd rabbitmq &>/dev/null
printf 'rabbitmq onlyoffice user password: '
read -rs rabbitmqonlyofficepass
echo ' '
printf "system user postgres password: "
read -rs postgressysusepass
echo ' '
echo -e "$postgressysusepass\n$postgressysusepass"|passwd postgres &>/dev/null
printf 'postgresql onlyoffice user password: '
read -rs postgresqlonlyofficepass
echo ' '
rabbitmqctl add_user guest guest
rabbitmqctl change_password guest guest
rabbitmqctl set_user_tags guest administrator
rabbitmqctl set_permissions -p / guest ".*" ".*" ".*"
rabbitmqctl add_user onlyoffice ${rabbitmqonlyofficepass}
rabbitmqctl set_user_tags onlyoffice administrator
rabbitmqctl set_permissions -p / onlyoffice ".*" ".*" ".*"
sudo -i -u postgres psql -c "CREATE DATABASE onlyoffice;"
sudo -i -u postgres psql -c "CREATE USER onlyoffice WITH password '${postgresqlonlyofficepass}';"
sudo -i -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;"
sudo -i -u postgres psql -c "ALTER DATABASE onlyoffice OWNER TO onlyoffice;"
sed -i 's|local   all             all                                     peer|local   all             all                                     scram-sha-256|g' /etc/postgresql/15/main/pg_hba.conf
service postgresql restart
mkdir /var/www/onlyoffice
chown -R www-data:ds /var/www/onlyoffice
chmod -R 775 /var/www/onlyoffice
    #echo onlyoffice-documentserver onlyoffice/db-host string $url | sudo debconf-set-selections
echo onlyoffice-documentserver onlyoffice/db-user string onlyoffice | sudo debconf-set-selections
echo onlyoffice-documentserver onlyoffice/db-pwd password $postgresqlonlyofficepass | sudo debconf-set-selections
echo onlyoffice-documentserver onlyoffice/db-name string onlyoffice | sudo debconf-set-selections
    #echo onlyoffice-documentserver onlyoffice/rabbitmq-host string $url | sudo debconf-set-selections
echo onlyoffice-documentserver onlyoffice/rabbitmq-user string onlyoffice | sudo debconf-set-selections
echo onlyoffice-documentserver onlyoffice/rabbitmq-pwd password $rabbitmqonlyofficepass | sudo debconf-set-selections
echo onlyoffice-documentserver onlyoffice/jwt-enabled boolean true | sudo debconf-set-selections
mkdir -p -m 700 ~/.gnupg
curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --import
chmod 644 /tmp/onlyoffice.gpg
chown root:root /tmp/onlyoffice.gpg
mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg
echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main"  > /etc/apt/sources.list.d/onlyoffice.list
apt update
apt -y install onlyoffice-documentserver
chown -R www-data:ds /var/www/onlyoffice
chmod -R 775 /var/www/onlyoffice
rabbitmq-plugins enable rabbitmq_management
printf '*:*:onlyoffice:onlyoffice:'"$postgresqlonlyofficepass">/var/lib/postgresql/.pgpass
chown postgres /var/lib/postgresql/.pgpass
chmod 600 /var/lib/postgresql/.pgpass
sudo  -i -u postgres psql -U onlyoffice -d onlyoffice -f /var/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
rm /var/lib/postgresql/.pgpass
rabbitmqctl delete_user guest
systemctl start ds-example
systemctl enable ds-example
cat << EOF > nginx-selfsigned.conf
[req]
default_bits       = 2048
default_keyfile    = nginx-selfsigned.key
distinguished_name = req_distinguished_name
prompt = no
req_extensions     = req_ext
x509_extensions    = v3_ca

[req_distinguished_name]
countryName                 = ${userCC}
stateOrProvinceName         = .
localityName               = .
organizationName           = .
commonName                 = ${hpip}

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names

[alt_names]
DNS.1   = ${hpip}
DNS.2   = localhost
IP.1   = ${CIP}
IP.2   = ${IP}
IP.3   = 127.0.0.1
EOF
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -config nginx-selfsigned.conf
rm -f nginx-selfsigned.conf
mv /etc/onlyoffice/documentserver/nginx/ds.conf /etc/onlyoffice/documentserver/nginx/ds.conf.old
cp /etc/onlyoffice/documentserver/nginx/ds-ssl.conf.tmpl /etc/onlyoffice/documentserver/nginx/ds.conf
sed -i 's|{{SSL_CERTIFICATE_PATH}}|/etc/ssl/certs/nginx-selfsigned.crt|g' /etc/onlyoffice/documentserver/nginx/ds.conf
sed -i 's|{{SSL_KEY_PATH}}|/etc/ssl/private/nginx-selfsigned.key|g' /etc/onlyoffice/documentserver/nginx/ds.conf
sed -i 's|"rejectUnauthorized": true|"rejectUnauthorized": false|g' /etc/onlyoffice/documentserver/default.json
service nginx restart
bash /usr/bin/documentserver-update-securelink.sh
bash /usr/bin/documentserver-jwt-status.sh
echo 'TAKE NOTE OF ABOVE SECRET KEY! If you do not you will need to run documentserver-jwt-status.sh to find it again!'
echo -e "\n\nFollow these steps to verify install:"
echo "1) Visit https://$IP/example/ and https://$hpip/example/"
echo '2) Verify you can create, add content to, close, open, view modified content, and remove/delete said file'
echo -e "3) Enter above URL and JWT secret into your connector application (NextCloud?)\n\n"
echo 'We will now reboot after you press enter, verify OnlyOffice operates after reboot!'
read -rs reboot
systemctl stop ds-example
systemctl disable ds-example
reboot
exit
