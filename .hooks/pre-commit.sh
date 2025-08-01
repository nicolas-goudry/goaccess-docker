#!/usr/bin/env bash

if command -v nix >/dev/null \
  && [ -f /etc/nix/nix.conf ] \
  && [[ "$(grep -E '^experimental-features =' /etc/nix/nix.conf | awk -F'=' '{print $2}' | xargs)" =~ flakes ]]
then
  nix flake check
else
  >&2 echo "WARNING: Nix Flakes are not enabled! Evaluation checks will not be performed."
fi
