FROM alpine
RUN apk add dropbear
RUN mkdir /etc/dropbear
RUN dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
#COPY dropbear_rsa_host_key /etc/dropbear/dropbear_rsa_host_key
RUN mkdir /root/.ssh
COPY test_brainswap.pub /root/.ssh/authorized_keys
RUN adduser -D user
RUN mkdir /home/user/.ssh
COPY test_brainswap.pub /home/user/.ssh/authorized_keys
CMD [ "/usr/sbin/dropbear", "-F" ]
EXPOSE 22
