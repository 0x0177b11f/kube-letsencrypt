FROM alpine:3.9

RUN apk update && \
    apk add --no-cache certbot tini

ENTRYPOINT ["/sbin/tini", "--"]

RUN mkdir /etc/letsencrypt

COPY secret-patch-template.json /
COPY entrypoint.sh /

CMD ["/entrypoint.sh"]
