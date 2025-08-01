{
  pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/25.05.tar.gz") { },
}:

let
  inherit (pkgs) mkShellNoCC;
in
mkShellNoCC {
  nativeBuildInputs = with pkgs; [
    bash
    coreutils
    findutils
    mmdbinspect
  ];

  shellHook = ''
    find .hooks \
      -maxdepth 1 \
      -type f \
      -name '*.sh' \
      -exec bash -c 'ln -sf "$PWD/$1" ".git/hooks/$(basename "$1" .sh)"' _ {} \;
  '';
}
