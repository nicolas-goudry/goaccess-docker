{
  description = "Collection of GoAccess Docker images built with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.05";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
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
          inherit (pkgs) lib;

          builder =
            args:
            import ./default.nix (
              {
                inherit pkgs;
                inherit geolite2;
              }
              // args
            );
          distros = import ./helpers/distros.nix;
          geolite2 = pkgs.callPackage ./pkgs/geolite2.nix { };
        in
        (lib.foldl'
          (
            acc: val:
            let
              distro = if val == "distroless" then null else val;
            in
            acc
            // {
              ${val} = builder { inherit distro; };
              "${val}-geoip" = builder {
                inherit distro;

                withGeolocation = true;
              };
              "${val}-geolite2" = builder {
                inherit distro;

                withGeolite2 = true;
              };
            }
          )
          {
            default = builder { };
          }
          ((lib.attrNames distros) ++ [ "distroless" ])
        )
        // {
          inherit geolite2;
        }
      );
    };
}
