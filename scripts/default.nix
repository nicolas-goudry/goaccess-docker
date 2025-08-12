{
  pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/25.05.tar.gz") {
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "geolite2"
      ];
  },
  nix2container ? (
    import "${fetchTarball "https://github.com/nlewo/nix2container/archive/master.tar.gz"}/default.nix"
      {
        inherit pkgs;
        inherit (pkgs) system;
      }
  ),
  xpkgs ? pkgs.lib.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;

    directory = ../pkgs;
  },
}:

let
  xlib = import ../lib {
    inherit pkgs xpkgs;
    inherit (nix2container) nix2container;
  };
  lib = pkgs.lib;
  currentDir = ./.;
  packages = lib.filterAttrs (
    name: type:
    (type == "directory" && name != "_template") || (lib.hasSuffix ".nix" name && name != "default.nix")
  ) (builtins.readDir currentDir);
in
lib.mapAttrs (
  name: type:
  pkgs.callPackage (currentDir + "/${name}") {
    inherit xlib;
    inherit (nix2container) skopeo-nix2container;
  }
) packages
