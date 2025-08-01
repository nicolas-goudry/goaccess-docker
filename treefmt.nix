# { lib, pkgs, ... }:

{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.prettier.enable = true;

  programs.shellcheck = {
    enable = true;

    excludes = [ ".envrc" ];
  };
}
