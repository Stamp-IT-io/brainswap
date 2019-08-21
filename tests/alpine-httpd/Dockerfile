FROM alpine
RUN apk add dropbear busybox-extras
RUN mkdir /etc/dropbear
RUN mkdir /www
RUN dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
#COPY dropbear_rsa_host_key /etc/dropbear/dropbear_rsa_host_key
RUN mkdir /root/.ssh
COPY test_brainswap.pub /root/.ssh/authorized_keys
CMD [ "/bin/sh", "-c", "/usr/sbin/httpd -p 8090 -h /www ; exec /usr/sbin/dropbear -F" ]
EXPOSE 22
