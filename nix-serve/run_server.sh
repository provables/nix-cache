#!/bin/bash

# shellcheck disable=SC3040
set -euo pipefail 

echo "PATH=/home/nix/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/bin" \
    > /home/nix/.ssh/environment
touch /home/nix/.ssh/authorized_keys

sudo chown -R nix:nix /home/nix/.ssh
chmod 700 /home/nix/.ssh
chmod 600 /home/nix/.ssh/authorized_keys

mkdir -p /hostkeys
tar zxf /run/secrets/nix_secrets -C /hostkeys
for f in /hostkeys/*; do
    ln -sf "$f" /etc/ssh
done
ln -sf /sshd_config /etc/ssh/sshd_config

if [ ! -f /nix/nix-serve/bin/nix-serve ]; then
    echo "Installing nix-serve"
    su nix -c "\
        . /home/nix/.nix-profile/etc/profile.d/nix.sh \
        && nix build nixpkgs#nix-serve-ng -o /nix/nix-serve"
else
    echo "nix-serve is installed"
fi

/etc/init.d/ssh start
cd /home/nix
export NIX_SECRET_KEY_FILE=/run/secrets/cache-priv-key.pem
/nix/nix-serve/bin/nix-serve --verbose --host "*" --port 6000
#su nix -c "/nix/nix-serve/bin/nix-serve -l 0.0.0.0:6000"
sleep infinity