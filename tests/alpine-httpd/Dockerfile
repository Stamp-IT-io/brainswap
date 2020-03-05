FROM alpine
RUN apk add dropbear busybox-extras

# Setup dropbear with a known private RSA key
RUN mkdir /etc/dropbear
#RUN dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
COPY dropbear_rsa_host_key /etc/dropbear/dropbear_rsa_host_key

# Setup root account to accept login from a known private key
RUN mkdir /root/.ssh
COPY test_brainswap.pub /root/.ssh/authorized_keys

# Setup mount point for httpd data
RUN mkdir /www

# Default command is to start both busybox httpd in background and dropbear in foreground
CMD [ "/bin/sh", "-c", "/usr/sbin/httpd -p 8090 -h /www ; exec /usr/sbin/dropbear -F" ]
EXPOSE 22
