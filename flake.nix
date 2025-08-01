{
  description = "Collection of GoAccess Docker images built with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.05";

    nix2container = {
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
      nix2container,
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
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "geolite2"
                ];
            }
          )
        );
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      # nix flake check
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      # nix fmt
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      # Development environment with tools available in PATH
      devShells = eachSystem (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });

      packages = eachSystem (
        pkgs:
        let
          xpkgs = pkgs.lib.packagesFromDirectoryRecursive {
            inherit (pkgs) callPackage;

            directory = ./pkgs;
          };
        in
        import ./default.nix {
          inherit pkgs xpkgs;
          inherit (nix2container.packages.${pkgs.system}) nix2container;
        }
      );
    };
}
