#!/bin/ash

# Handle LDAP key/crt combination

if ! [[ -z `find /data/ -name "*.crt"` ]] \
&& ! [[ -z `find /data/ -name "*.key"` ]]
then
    keyFile=`find /data -name "*.key"`
    crtFile=`find /data -name "*.crt"`

    cp ${keyFile} /etc/raddb/certs/ldap-client.key
    cp ${crtFile} /etc/raddb/certs/ldap-client.crt
    
    chown root:radius /etc/raddb/certs/ldap-client.*
    chmod 640 /etc/raddb/certs/ldap-client.*
else
    echo "No key/crt added to /data. Exiting"
    exit 1
fi

# Enable LDAP module

ln -s -f /etc/raddb/mods-available/ldap /etc/raddb/mods-enabled/ldap 

# Configure the LDAP module

sed -Ei "s|.+(server = ').+'|        server = 'ldaps://ldap.google.com:636'|" /etc/raddb/mods-enabled/ldap 

sed -Ei "s/^[#].+(identity = ').+'/        identity = '${FREERADIUS_USERNAME:-exampleUser}'/" /etc/raddb/mods-enabled/ldap 

sed -Ei "s/^[#].+(password = ).+/        password = ${FREERADIUS_PASSWORD:-examplePass}/" /etc/raddb/mods-enabled/ldap 

sed -Ei "s/.+(base_dn = ').+'/        base_dn = '${FREERADIUS_BASEDN:-}'/" /etc/raddb/mods-enabled/ldap

sed -Ei "s/.+(start_tls = ).+/                start_tls = no/" /etc/raddb/mods-enabled/ldap

sed -Ei "s|.+(certificate_file = ).+|                certificate_file = /etc/raddb/certs/ldap-client.crt|" /etc/raddb/mods-enabled/ldap

sed -Ei "s|.+(private_key_file = ).+|                private_key_file = /etc/raddb/certs/ldap-client.key|" /etc/raddb/mods-enabled/ldap

sed -Ei "s/^[#].+(require_cert).+(= ').+'/                require_cert = 'allow'/" /etc/raddb/mods-enabled/ldap


postAuthLineRef=`grep -n 'post-auth' /etc/raddb/mods-enabled/ldap | awk '{print $1}'`
postAuthLineRef=${postAuthLineRef//:/}

sed -i "$((${postAuthLineRef}+1))s/.*/#/" /etc/raddb/mods-enabled/ldap 
sed -i "$((${postAuthLineRef}+2))s/.*/#/" /etc/raddb/mods-enabled/ldap 
sed -i "$((${postAuthLineRef}+3))s/.*/#/" /etc/raddb/mods-enabled/ldap 

passwordAuthLineRef=`grep -n 'pap' /etc/raddb/sites-available/default | awk '{print $1}'  | head -1`
passwordAuthLineRef=${passwordAuthLineRef//:/}

sed -i "$((${passwordAuthLineRef}+1))s/.*/         if (User-Password) {/" /etc/raddb/sites-available/default
sed -i "$((${passwordAuthLineRef}+2))s/.*/             update control {/" /etc/raddb/sites-available/default
sed -i "$((${passwordAuthLineRef}+3))s/.*/                 Auth-Type := ldap/" /etc/raddb/sites-available/default
sed -i "$((${passwordAuthLineRef}+4))s/.*/             }/" /etc/raddb/sites-available/default
sed -i "$((${passwordAuthLineRef}+5))s/.*/         }/" /etc/raddb/sites-available/default


ldapAuthLineRef=`grep -n 'ldap' /etc/raddb/sites-available/default | awk '{print $1}'  | head -3 | tail -1`
ldapAuthLineRef=${ldapAuthLineRef//:/}
sed -i "${ldapAuthLineRef}s/.*/     ldap/" /etc/raddb/sites-available/default


ldapAuthTypeLineRef=`grep -n 'ldap' /etc/raddb/sites-available/default | awk '{print $1}'  | head -7 | tail -1`
ldapAuthTypeLineRef=${ldapAuthTypeLineRef//#/}
ldapAuthTypeLineRef=${ldapAuthTypeLineRef//:/}
sed -i "${ldapAuthTypeLineRef}s/.*/             ldap/" /etc/raddb/sites-available/default

ldapPapTypeLineRef=`grep -n 'Auth-Type PAP {' /etc/raddb/sites-available/default | awk '{print $1}'`
ldapPapTypeLineRef=${ldapPapTypeLineRef//:/}
sed -i "$((${ldapPapTypeLineRef}+1))s/.*/                ldap/" /etc/raddb/sites-available/default

sed -i "s/ipaddr = 127.0.0.1/#ipaddr = 127.0.0.1/" /etc/raddb/clients.conf
sed -Ei "s/^[#].+(ipv4addr = \*)/       ipv4addr = \*/" /etc/raddb/clients.conf


# Run Freeradius
radiusd -X