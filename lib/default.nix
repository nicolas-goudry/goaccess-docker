{
  nix2container,
  pkgs,
  xpkgs,
}:

let
  inherit (pkgs) lib;

  distros = import ./distros.nix;
in
rec {
  # Generate a set of image variants for each supported distro.
  #
  # This function iterates over all supported distros (plus "distroless") and creates three image variants for each:
  #   - <distro>:          base image, no geolocation
  #   - <distro>-geoip:    image with geolocation support enabled
  #   - <distro>-geolite2: image with GeoLite2 database (implies geolocation)
  #
  # The result is an attribute set mapping variant names to their respective images built with mkImage.
  #
  # Returns:
  #   - Attribute set: { <variant>: <image>, ... }
  mkAllImages =
    lib.foldl'
      (
        acc: distro:
        let
          # For "distroless", baseImage is empty; otherwise, use the distro name
          baseImage = lib.optionalString (distro != "distroless") distro;
        in
        acc
        // {
          # Variant: base image without geolocation
          ${distro} = mkImage { inherit baseImage; };

          # Variant: image with geolocation support
          "${distro}-geoip" = mkImage {
            inherit baseImage;

            withGeolocation = true;
          };

          # Variant: image with GeoLite2 database (implies geolocation)
          "${distro}-geolite2" = mkImage {
            inherit baseImage;

            withGeolite2 = true;
          };
        }
      )
      # Initial accumulator: empty attribute set
      { }
      # List of all distros plus "distroless"
      ((lib.attrNames distros) ++ [ "distroless" ]);

  # Creates a containerized GoAccess image with configurable base image and geolocation support, using nix2container.
  mkImage =
    {
      # Optional base container image to build upon (empty string means no base image)
      baseImage ? "",
      # Whether to include GeoLite2 database for geolocation features
      withGeolite2 ? false,
      # Whether to enable geolocation support in GoAccess
      withGeolocation ? withGeolite2,
    }:
    let
      inherit (pkgs)
        buildEnv
        goaccess
        ;
      inherit (xpkgs) geolite2;

      # Error message thrown when an invalid base image is specified
      throwDistro = throw "Invalid image provided!\n\nAllowed images:\n- ${lib.concatStringsSep "\n- " (lib.attrNames distros)}";

      # Override GoAccess derivation attribute according to parameters
      goaccessDrv = goaccess.override { withGeolocation = withGeolocation || withGeolite2; };

      # Override GoAccess derivation call to patch configuration file to use GeoLite2 database path if enabled
      goaccessBuild = goaccessDrv.overrideAttrs (
        lib.optionalAttrs withGeolite2 {
          postPatch = lib.optionalString withGeolite2 ''
            substituteInPlace config/goaccess.conf \
              --replace-fail "#geoip-database /usr/local/share/GeoIP/GeoLiteCity.dat" "geoip-database /share/GeoIP/GeoLite2-City.mmdb"
          '';
        }
      );

    in
    nix2container.buildImage {
      name = "goaccess";

      # Generate tag based on version and enabled features
      tag = lib.concatStrings [
        goaccess.version
        (lib.optionalString withGeolite2 "-geolite2-${lib.replaceStrings [ "." ] [ "-" ] geolite2.version}")
        (lib.optionalString (!withGeolite2 && withGeolocation) "-geoip")
        (lib.optionalString (baseImage != "") "-${baseImage}")
      ];

      # Set the base image to build from (empty string means scratch/no base)
      fromImage =
        if (baseImage != "") then
          nix2container.pullImage (distros.${baseImage} or throwDistro)
        else
          baseImage;

      # Build the root filesystem environment
      copyToRoot = buildEnv {
        name = "root";

        # Packages to include in the container
        paths =
          [ goaccessBuild ]
          # Include GeoLite2 database if requested
          ++ lib.optional withGeolite2 geolite2;

        # Directories to symlink into the container root
        pathsToLink = [
          "/bin"
          "/etc"
          "/share"
        ];
      };

      # Default command to run when container starts
      config.Entrypoint = [ "goaccess" ];
    };
}
