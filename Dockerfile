FROM alpine:3.9

RUN apk update && \
    apk add --no-cache certbot tini bash curl

ENTRYPOINT ["/sbin/tini", "--"]

COPY secret-patch-template.json /
COPY entrypoint.sh /

RUN mkdir /etc/letsencrypt
RUN chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]
