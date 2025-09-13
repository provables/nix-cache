FROM debian:stable

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=US/Central
RUN apt-get update -y
RUN apt-get install -y openssh-server curl xz-utils sudo vim
COPY sshd_config /sshd_config
RUN adduser --disabled-password nix
RUN mkdir -p /home/nix/.ssh
RUN chown -R nix:nix /home/nix
RUN echo "nix ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nix
RUN mkdir -p /nix && chown nix:nix /nix

USER nix
RUN curl -L https://nixos.org/nix/install > /tmp/nix-install
RUN sh /tmp/nix-install --no-daemon

USER root
RUN mkdir -p /etc/nix
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf \
    && echo "build-users-group = nix" >> /etc/nix/nix.conf

COPY run_server.sh /run_server.sh
RUN chmod +x /run_server.sh
RUN apt-get install -y iproute2
CMD ["/run_server.sh"]