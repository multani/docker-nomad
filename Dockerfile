FROM alpine:3.12

SHELL ["/bin/sh", "-x", "-c"]

# Based on https://github.com/djenriquez/nomad
LABEL maintainer="Jonathan Ballet <jon@multani.info>"

RUN addgroup nomad && \
    adduser -S -G nomad nomad

# https://github.com/andyshinn/alpine-pkg-glibc/releases
ENV GLIBC_VERSION "2.30-r0"

# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION "1.11"

# Allow to fetch artifacts from TLS endpoint during the builds and by Nomad after.
RUN apk --update add --no-cache ca-certificates dumb-init iptables openssl \
  && update-ca-certificates

RUN apk --update add --no-cache --virtual .gosu-deps curl dpkg gnupg && \
    curl -L -o /tmp/glibc-${GLIBC_VERSION}.apk https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    apk add --allow-untrusted /tmp/glibc-${GLIBC_VERSION}.apk && \
    rm -rf /tmp/glibc-${GLIBC_VERSION}.apk /var/cache/apk/* && \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
    curl -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver pgp.mit.edu --keyserver keyserver.pgp.com --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    apk del .gosu-deps

# https://github.com/containernetworking/plugins/releases
ENV CNI_PLUGINS_VERSION "v0.8.6"

RUN apk --update add --no-cache --virtual .gosu-deps curl dpkg gnupg && \
    curl -L -O "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz" && \
    curl -L -O "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver pgp.mit.edu --keyserver keyserver.pgp.com --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 5B1053CE38EA2E0FEB956C0595BC5E3F3F1B2C87 && \
    gpg --batch --verify cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz.asc cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz && \
    mkdir -p /opt/cni/bin && \
    tar xf cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz -C /opt/cni/bin && \
    rm -rf "$GNUPGHOME" cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz* && \
    apk del .gosu-deps

# https://releases.hashicorp.com/nomad/
ENV NOMAD_VERSION 0.12.0-beta1

RUN apk --update add --no-cache --virtual .nomad-deps curl dpkg gnupg \
  && cd /tmp \
  && curl -L -o nomad_${NOMAD_VERSION}_linux_amd64.zip https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip \
  && curl -L -o nomad_${NOMAD_VERSION}_SHA256SUMS      https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS \
  && curl -L -o nomad_${NOMAD_VERSION}_SHA256SUMS.sig  https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver pgp.mit.edu --keyserver keyserver.pgp.com --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C \
  && gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS \
  && grep nomad_${NOMAD_VERSION}_linux_amd64.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c \
  && unzip -d /bin nomad_${NOMAD_VERSION}_linux_amd64.zip \
  && chmod +x /bin/nomad \
  && rm -rf "$GNUPGHOME" nomad_${NOMAD_VERSION}_linux_amd64.zip nomad_${NOMAD_VERSION}_SHA256SUMS nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
  && apk del .nomad-deps

RUN mkdir -p /nomad/data && \
    mkdir -p /etc/nomad && \
    chown -R nomad:nomad /nomad /etc/nomad

EXPOSE 4646 4647 4648 4648/udp

ADD start.sh /usr/local/bin/start.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
