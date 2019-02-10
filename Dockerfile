FROM alpine:3.9

RUN apk update && \
    apk add certbot && \
    apk cache clean

RUN mkdir /etc/letsencrypt

COPY secret-patch-template.json /
COPY entrypoint.sh /

CMD ["/entrypoint.sh"]
