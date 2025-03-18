FROM debian:12.10-slim

# Fetch the target information injected by Docker build
ARG TARGETOS
ARG TARGETARCH

SHELL ["/bin/bash", "-x", "-c", "-o", "pipefail"]

# https://releases.hashicorp.com/nomad/
ARG NOMAD_VERSION
RUN test -n "$NOMAD_VERSION" || (echo "NOMAD_VERSION argument must be set" && false)

RUN groupadd nomad \
  && useradd --system --gid nomad nomad \
  && mkdir --parents /nomad/data \
  && mkdir --parents /etc/nomad \
  && chown --recursive nomad:nomad /nomad /etc/nomad

# Allow to fetch artifacts from TLS endpoint during the builds and by Nomad after.
# Install timezone data so we can run Nomad periodic jobs containing timezone information
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    ca-certificates \
    dumb-init \
    libcap2 \
    tzdata \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*

ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip \
    nomad_${NOMAD_VERSION}_${TARGETOS}_${TARGETARCH}.zip
ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS \
    nomad_${NOMAD_VERSION}_SHA256SUMS
ADD https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
    nomad_${NOMAD_VERSION}_SHA256SUMS.sig

RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    gnupg \
    unzip \
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
