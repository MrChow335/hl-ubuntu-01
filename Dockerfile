FROM ubuntu:20.04

ARG S6_OVERLAY_VERSION=v2.2.0.3
ARG S6_OVERLAY_ARCH=amd64
ARG PLEX_BUILD=linux-x86_64
ARG PLEX_DISTRO=debian
ARG DEBIAN_FRONTEND="noninteractive"
ARG INTEL_NEO_VERSION=20.48.18558
ARG INTEL_IGC_VERSION=1.0.5699
ARG INTEL_GMMLIB_VERSION=20.3.2
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

ENTRYPOINT ["/init"]

USER root

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get install -y \
      tzdata \
      curl \
      xmlstarlet \
      uuid-runtime \
      unrar \
    && \
    \
# Fetch and extract S6 overlay
    curl -J -L -o /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz -C / --exclude='./bin' && \
    tar xzf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz -C /usr ./bin && \
    \
# Add user
    useradd -U -d /config -s /bin/false plex && \
    usermod -G users plex && \
    \
# Setup directories
    mkdir -p \
      /config \
      /transcode \
      /data \
    && \
    \
# Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

EXPOSE 32400/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

ARG TAG=beta
ARG URL=

#COPY resources/plex/root/ /
COPY resources/root/ /

RUN chmod +755 /installBinary.sh /healthcheck.sh /plex_service.sh /plex-common.sh
# Save version and install
RUN /installBinary.sh

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1
