#!/bin/bash

/etc/init.d/freeradius start \
&& /etc/init.d/freeradius stop


# Handle LDAP key/crt combination

if ! [[ -z `find /data/ -name "*.crt"` ]] \
&& ! [[ -z `find /data/ -name "*.key"` ]]
then
    keyFile=`find /data -name "*.key"`
    crtFile=`find /data -name "*.crt"`

    cp ${keyFile} /etc/freeradius/3.0/certs/ldap-client.key
    cp ${crtFile} /etc/freeradius/3.0/certs/ldap-client.crt
    
    chown freerad:freerad /etc/freeradius/3.0/certs/ldap-client.*
    chmod 640 /etc/freeradius/3.0/certs/ldap-client.*
else
    echo "No key/crt added to /data. Exiting"
    exit 1
fi

# Enable LDAP module

ln -s -f /etc/freeradius/3.0/mods-available/ldap /etc/freeradius/3.0/mods-enabled/ldap 

# Configure the LDAP module

sed -Ei "s|.+(server = ').+'|        server = 'ldaps://ldap.google.com:636'|" /etc/freeradius/3.0/mods-enabled/ldap 

sed -Ei "s/^[#].+(identity = ').+'/        identity = '${FREERADIUS_USERNAME:-exampleUser}'/" /etc/freeradius/3.0/mods-enabled/ldap 

sed -Ei "s/^[#].+(password = ).+/        password = ${FREERADIUS_PASSWORD:-examplePass}/" /etc/freeradius/3.0/mods-enabled/ldap 

sed -Ei "s/.+(base_dn = ').+'/        base_dn = '${FREERADIUS_BASEDN:-}'/" /etc/freeradius/3.0/mods-enabled/ldap

sed -Ei "s/.+(start_tls = ).+/                start_tls = no/" /etc/freeradius/3.0/mods-enabled/ldap

sed -Ei "s|.+(certificate_file = ).+|                certificate_file = /etc/freeradius/3.0/certs/ldap-client.crt|" /etc/freeradius/3.0/mods-enabled/ldap

sed -Ei "s|.+(private_key_file = ).+|                private_key_file = /etc/freeradius/3.0/certs/ldap-client.key|" /etc/freeradius/3.0/mods-enabled/ldap

sed -Ei "s/^[#].+(require_cert).+(= ').+'/                require_cert = 'allow'/" /etc/freeradius/3.0/mods-enabled/ldap


postAuthLineRef=`grep -n 'post-auth' /etc/freeradius/3.0/mods-enabled/ldap | awk '{print $1}'`
postAuthLineRef=${postAuthLineRef//:/}

sed -i "$((${postAuthLineRef}+1))s/.*/#/" /etc/freeradius/3.0/mods-enabled/ldap 
sed -i "$((${postAuthLineRef}+2))s/.*/#/" /etc/freeradius/3.0/mods-enabled/ldap 
sed -i "$((${postAuthLineRef}+3))s/.*/#/" /etc/freeradius/3.0/mods-enabled/ldap 

passwordAuthLineRef=`grep -n 'pap' /etc/freeradius/3.0/sites-available/default | awk '{print $1}'  | head -1`
passwordAuthLineRef=${passwordAuthLineRef//:/}

sed -i "$((${passwordAuthLineRef}+1))s/.*/         if (User-Password) {/" /etc/freeradius/3.0/sites-available/default
sed -i "$((${passwordAuthLineRef}+2))s/.*/             update control {/" /etc/freeradius/3.0/sites-available/default
sed -i "$((${passwordAuthLineRef}+3))s/.*/                 Auth-Type := ldap/" /etc/freeradius/3.0/sites-available/default
sed -i "$((${passwordAuthLineRef}+4))s/.*/             }/" /etc/freeradius/3.0/sites-available/default
sed -i "$((${passwordAuthLineRef}+5))s/.*/         }/" /etc/freeradius/3.0/sites-available/default


ldapAuthLineRef=`grep -n 'ldap' /etc/freeradius/3.0/sites-available/default | awk '{print $1}'  | head -3 | tail -1`
ldapAuthLineRef=${ldapAuthLineRef//:/}
sed -i "${ldapAuthLineRef}s/.*/     ldap/" /etc/freeradius/3.0/sites-available/default


ldapAuthTypeLineRef=`grep -n 'ldap' /etc/freeradius/3.0/sites-available/default | awk '{print $1}'  | head -7 | tail -1`
ldapAuthTypeLineRef=${ldapAuthTypeLineRef//#/}
ldapAuthTypeLineRef=${ldapAuthTypeLineRef//:/}
sed -i "${ldapAuthTypeLineRef}s/.*/             ldap/" /etc/freeradius/3.0/sites-available/default

ldapPapTypeLineRef=`grep -n 'Auth-Type PAP {' /etc/freeradius/3.0/sites-available/default | awk '{print $1}'`
ldapPapTypeLineRef=${ldapPapTypeLineRef//:/}
sed -i "$((${ldapPapTypeLineRef}+1))s/.*/                ldap/" /etc/freeradius/3.0/sites-available/default

sed -i "s/ipaddr = 127.0.0.1/#ipaddr = 127.0.0.1/" /etc/freeradius/3.0/clients.conf
sed -Ei "s/^[#].+(ipv4addr = \*)/       ipv4addr = \*/" /etc/freeradius/3.0/clients.conf


# Run Freeradius
freeradius -X