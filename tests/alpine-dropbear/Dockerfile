FROM alpine
RUN apk add dropbear sudo

# Setup dropbear with a known private RSA key
RUN mkdir /etc/dropbear
#RUN dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
COPY dropbear_rsa_host_key /etc/dropbear/dropbear_rsa_host_key

# Setup root account to accept login from a know private key
RUN mkdir /root/.ssh
COPY test_brainswap.pub /root/.ssh/authorized_keys

# Setup a sudo-capable user account which accepts login from a known private key
RUN adduser -D user
RUN mkdir /home/user/.ssh
COPY test_brainswap.pub /home/user/.ssh/authorized_keys
RUN echo "user ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

# Default command is to start dropbear in foreground
CMD [ "/usr/sbin/dropbear", "-F" ]
EXPOSE 22
