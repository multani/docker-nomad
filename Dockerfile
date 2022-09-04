FROM --platform=$BUILDPLATFORM debian:bullseye-slim

# Fetch the target information injected by Docker build
ARG TARGETOS
ARG TARGETARCH

SHELL ["/bin/bash", "-x", "-c", "-o", "pipefail"]

# Based on https://github.com/djenriquez/nomad
LABEL maintainer="Jonathan Ballet <jon@multani.info>"

RUN groupadd nomad \
 && useradd --gid nomad nomad \
 && mkdir -p /nomad/data \
 && mkdir -p /etc/nomad \
 && chown -R nomad:nomad /nomad /etc/nomad

# Allow to fetch artifacts from TLS endpoint during the builds and by Nomad after.
RUN apt-get update --yes \
    && apt-get install --no-install-recommends --yes \
        ca-certificates=20210119 \
        dumb-init=1.2.5-1 \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# https://releases.hashicorp.com/nomad/
ARG NOMAD_VERSION=1.3.5

ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip \
    nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip
ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS \
    nomad_${NOMAD_VERSION}_SHA256SUMS
ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
    nomad_${NOMAD_VERSION}_SHA256SUMS.sig
RUN apt-get update \
&& apt-get install --no-install-recommends --yes \
    gnupg=2.2.27-2+deb11u2 \
    unzip=6.0-26+deb11u1 \
  && GNUPGHOME="$(mktemp -d)" \
  && export GNUPGHOME \
  && gpg --keyserver pgp.mit.edu --keyserver keys.openpgp.org --keyserver keyserver.ubuntu.com --recv-keys "C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F" \
  && gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS \
  && grep nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c \
  && unzip -d /bin nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip \
  && chmod +x /bin/nomad \
  && rm -rf "$GNUPGHOME" nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip nomad_${NOMAD_VERSION}_SHA256SUMS nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
  && apt-get autoremove --purge --yes \
    gnupg \
    unzip \
  && rm -rf /var/lib/apt/lists/*

RUN nomad version

EXPOSE 4646 4647 4648 4648/udp

COPY start.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/start.sh"]
