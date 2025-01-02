FROM alpine:3.21.0

USER root

RUN apk --no-cache add tzdata
RUN echo "Asia/Seoul" >  /etc/timezone
RUN cp -f /usr/share/zoneinfo/Asia/Seoul /etc/localtime

RUN apk add bash
RUN apk add sudo
RUN apk add openssh
RUN apk add sshpass
RUN apk add procps-ng
RUN apk add iproute2

RUN ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

COPY tunnel-manager.sh /tunnel-manager.sh
RUN chmod 755 /tunnel-manager.sh

RUN mkdir -p /etc/tunnel-manager
COPY vms.conf /etc/tunnel-manager/vms.conf
COPY service-port-mapping.conf /etc/tunnel-manager/service-port-mapping.conf

CMD ["/tunnel-manager.sh"]
