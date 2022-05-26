FROM alpine:3.16

# install packages
RUN apk upgrade --no-cache \
        && apk add --no-cache \
        postfix postfix-pgsql postfix-mysql postfix-pcre postfix-policyd-spf-perl \
        s6 setpriv

# add the custom configurations
COPY rootfs/ /

# spooled mails should not be lost
VOLUME /var/spool/postfix

# 25: smtp
# 587: submission
EXPOSE 25/tcp 587/tcp

CMD [ "/entrypoint.sh" ]

