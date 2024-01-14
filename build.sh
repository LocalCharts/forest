#!/usr/bin/env bash
set -e

export NP_GIT=$(which git)
wget -nv https://github.com/DavHau/nix-portable/releases/download/v010/nix-portable
chmod +x nix-portable

mkdir -p ~/.ssh
echo "$NIXBUILD_SSH_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

echo 'eu.nixbuild.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM' >> ~/.ssh/known_hosts

set -x

./nix-portable nix build -L --eval-store auto --store ssh-ng://eu.nixbuild.net .#default


out="$(./nix-portable nix-store --query --outputs "$(./nix-portable nix path-info --derivation .#homepage)")"
./nix-portable nix copy --no-check-sigs --from ssh-ng://eu.nixbuild.net "$out"

# The "result" symlink only valid inside the nix-portable sandbox
./nix-portable nix run nixpkgs#coreutils -- --coreutils-prog=cp -rL "$out" output

chmod -R u+w output
