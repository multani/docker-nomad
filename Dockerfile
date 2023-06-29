FROM alpine:3.18.0

SHELL ["/bin/ash", "-x", "-c", "-o", "pipefail"]

# Based on https://github.com/djenriquez/nomad
LABEL maintainer="Jonathan Ballet <jon@multani.info>"

RUN addgroup nomad \
 && adduser -S -G nomad nomad \
 && mkdir -p /nomad/data \
 && mkdir -p /etc/nomad \
 && chown -R nomad:nomad /nomad /etc/nomad

# Allow to fetch artifacts from TLS endpoint during the builds and by Nomad after.
# Install timezone data so we can run Nomad periodic jobs containing timezone information
RUN apk --update --no-cache add \
        ca-certificates \
        dumb-init \
        libcap \
        tzdata \
        su-exec \
  && update-ca-certificates

# https://github.com/sgerrand/alpine-pkg-glibc/releases
ARG GLIBC_VERSION=2.34-r0

ADD https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
ADD https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    glibc.apk
RUN apk add --no-cache --force-overwrite \
        glibc.apk \
 && rm glibc.apk

# https://releases.hashicorp.com/nomad/
ARG NOMAD_VERSION=1.4.10

ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip \
    nomad_${NOMAD_VERSION}_linux_amd64.zip
ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS \
    nomad_${NOMAD_VERSION}_SHA256SUMS
ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
    nomad_${NOMAD_VERSION}_SHA256SUMS.sig
RUN apk add --no-cache --virtual .nomad-deps gnupg \
  && GNUPGHOME="$(mktemp -d)" \
  && export GNUPGHOME \
  && gpg --keyserver pgp.mit.edu --keyserver keys.openpgp.org --keyserver keyserver.ubuntu.com --recv-keys "C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F" \
  && gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS \
  && grep nomad_${NOMAD_VERSION}_linux_amd64.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c \
  && unzip -d /bin nomad_${NOMAD_VERSION}_linux_amd64.zip \
  && chmod +x /bin/nomad \
  && rm -rf "$GNUPGHOME" nomad_${NOMAD_VERSION}_linux_amd64.zip nomad_${NOMAD_VERSION}_SHA256SUMS nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
  && apk del .nomad-deps

EXPOSE 4646 4647 4648 4648/udp

COPY start.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/start.sh"]
