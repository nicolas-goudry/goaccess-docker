{
  pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/25.05.tar.gz") {
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "geolite2"
      ];
  },
  nix2container ?
    (import "${fetchTarball "https://github.com/nlewo/nix2container/archive/master.tar.gz"}/default.nix"
      {
        inherit pkgs;
        inherit (pkgs) system;
      }
    ).nix2container,
  xpkgs ? pkgs.lib.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;

    directory = ./pkgs;
  },
}:

let
  xlib = import ./lib { inherit nix2container pkgs xpkgs; };
in
xlib.mkAllImages
// xpkgs
// {
  default = xlib.mkImage { };
}
