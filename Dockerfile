FROM ubuntu:20.04

RUN apt-get update -y       \
    && apt-get upgrade -y   \
    && apt-get install -y   \
    freeradius              \
    freeradius-ldap         \
    ldap-utils              \
    && mkdir /data

RUN chown 1000:1000 /data

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]