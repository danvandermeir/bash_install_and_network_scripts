#!/bin/bash
#Array of domain names to update, to create wildcard DDNS for unused subdomains use '*.name.tld' and 'name.tld' for domain
dmnms+=('' '' '')
#Corresponding username per DDNS entry
usrnm+=('' '' '')
#Corresponding password per DDNS entry
pswrd+=('' '' '')
#Necessary functions and code
err() {
	[ -n "$1" ] && printf -- "$1\n" 1>&2 && return 0
	return 1
}
errout() {
	err "$1"
	exit 1
}
appexist() {
	[ -z "$1" ] && errout 'No application name provided to appexist function!'
	command -v "$1" > /dev/null || errout "Script requires $1 application! Exiting!"
	return 0
}
isip() {
	[ -z "$1" ] || [[ ! $1 =~ ^[0-9/.]+$ ]] && err "Invalid IP address ($1)!" && return 1
	local a1 a2 a3 a4 v
	a4="$1"
	a1=${a4//.}
	[ $((${#a4} - ${#a1})) -ne 3 ] && err "Invalid IP address ($1)!" && return 1
	for y in {1..4}; do
		declare a$y="${a4%%.*}"
		v="a$y"
		[ -z "${!v}" ] || [ ${!v} -gt 255 ] && err "Invalid IP address ($1)!" && return 1
		a4="${a4#*.}"
	done
	return 0
}
appexist curl
appexist dig
CIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
isip "$CIP" || errout "Could not determine current IP ($CIP)!"
for dmnm in "${!dmnms[@]}"; do
	HIP="$(dig +short ${dmnms[$dmnm]} @resolver1.opendns.com)"
	isip "$HIP" || errout "Could not determine domain (${dmnms[$dmnm]}) IP ($HIP)!"
	[ "$CIP" = "$HIP" ] && continue 1
	dmnmreply=$(curl -s "https://${usrnm[$dmnm]}:${pswrd[$dmnm]}@domains.google.com/nic/update?hostname=${dmnms[$dmnm]}&myip=${CIP}" 2>&1)
	case $dmnmreply in
		"nodmnm"|"badauth"|"notfqdn"|"badagent") err "Bad request! Check Google DNS script information for ${dmnms[$dmnm]}!";;
		"conflict A"|"conflict AAAA") err "Resource record conflict! Check Google Domains account for ${dmnms[$dmnm]}!";;
		"abuse") err "Google has prevented DNS updates for ${dmnms[$dmnm]} due to abuse!";;
		"911") errout 'Google Domains service is experiencing issues!';;
	esac
done
