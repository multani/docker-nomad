FROM alpine:3.4

MAINTAINER DJ Enriquez <dj.enriquez@infospace.com> (@djenriquez)

RUN addgroup nomad && \
    adduser -S -G nomad nomad

ENV NOMAD_VERSION 0.5.0
ENV NOMAD_SHA256 7f7b9af2b1ff3e2c6b837b6e95968415237bb304e1e82802bc42abf6f8645a43
ENV GLIBC_VERSION "2.23-r1"
ENV GOSU_VERSION 1.9

RUN set -x && \
    apk --update add --no-cache --virtual .gosu-deps dpkg curl ca-certificates gnupg libcap openssl && \
    curl -Ls https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk > /tmp/glibc-${GLIBC_VERSION}.apk && \
    apk add --allow-untrusted /tmp/glibc-${GLIBC_VERSION}.apk && \
    rm -rf /tmp/glibc-${GLIBC_VERSION}.apk /var/cache/apk/* && \
    wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 && \
    chmod +x /usr/local/bin/dumb-init && \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    apk del .gosu-deps

ENV NOMAD_VERSION 0.5.1
ENV NOMAD_SHA256 f93fc55d0c68883a28198c9fab93887f535c00193fce80b4be89cd09b6bbdb94

ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip /tmp/nomad.zip
RUN echo "${NOMAD_SHA256}  /tmp/nomad.zip" > /tmp/nomad.sha256 \
  && sha256sum -c /tmp/nomad.sha256 \
  && cd /bin \
  && unzip /tmp/nomad.zip \
  && chmod +x /bin/nomad \
  && rm /tmp/nomad.zip

RUN mkdir -p /nomad/data && \
    mkdir -p /etc/nomad && \
    chown -R nomad:nomad /nomad

EXPOSE 4646 4647 4648

ADD start.sh /usr/local/bin/start.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]