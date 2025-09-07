{
  description = "Collection of GoAccess Docker images built with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.05";

    n2c = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      n2c,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      eachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f rec {
            pkgs = import nixpkgs {
              inherit system;

              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "geolite2"
                ];
            };

            xpkgs = pkgs.lib.packagesFromDirectoryRecursive {
              inherit (pkgs) callPackage;

              directory = ./pkgs;
            };

            nix2container = n2c.packages.${pkgs.system};
          }
        );
      treefmtEval = eachSystem ({ pkgs, ... }: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      # nix flake check
      checks = eachSystem (
        { pkgs, ... }:
        {
          formatting = treefmtEval.${pkgs.system}.config.build.check self;
        }
      );

      # nix fmt
      formatter = eachSystem ({ pkgs, ... }: treefmtEval.${pkgs.system}.config.build.wrapper);

      # Development environment with tools available in PATH
      devShells = eachSystem (
        {
          pkgs,
          xpkgs,
          nix2container,
          ...
        }:
        {
          default = pkgs.callPackage ./shell.nix {
            inherit xpkgs nix2container;
          };
        }
      );

      packages = eachSystem (
        {
          pkgs,
          xpkgs,
          nix2container,
          ...
        }:
        (import ./default.nix {
          inherit pkgs xpkgs;
          inherit (nix2container) nix2container;
        })
        // (import ./scripts {
          inherit pkgs xpkgs nix2container;
        })
      );
    };
}
