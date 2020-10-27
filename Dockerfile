FROM alpine:latest

RUN apk add                 \
    --no-cache              \
    --update                \
    freeradius              \
    freeradius-ldap         \
    && mkdir /data          \
    && chown 1000:1000 /data

COPY entrypoint.sh /entrypoint.sh

EXPOSE 18120

ENTRYPOINT ["/entrypoint.sh"]