# { lib, pkgs, ... }:

{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  programs.prettier = {
    enable = true;

    excludes = [
      "theme/*"
    ];
  };

  programs.shellcheck = {
    enable = true;

    excludes = [ ".envrc" ];
  };
}
