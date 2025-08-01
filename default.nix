{
  pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/25.05.tar.gz") { },
  nix2container ?
    (import "${fetchTarball "https://github.com/nlewo/nix2container/archive/master.tar.gz"}/default.nix"
      {
        inherit pkgs;
        inherit (pkgs) system;
      }
    ).nix2container,
  geolite2 ? pkgs.callPackage ./pkgs/geolite2.nix { },
  distro ? null,
  withGeolite2 ? false,
  withGeolocation ? withGeolite2,
  ...
}@args:

let
  inherit (pkgs)
    lib
    buildEnv
    goaccess
    ;

  throwDistro = throw "Invalid image provided!\n\nAllowed images:\n- ${lib.concatStringsSep "\n- " (lib.attrNames distros)}";
  distros = import ./helpers/distros.nix;

  tagSuffix =
    if withGeolite2 then
      "-geolite2"
    else if withGeolocation then
      "-geoip"
    else
      "";

  fromImage =
    if builtins.isNull distro then "" else nix2container.pullImage (distros.${distro} or throwDistro);
in
nix2container.buildImage {
  inherit fromImage;

  name = "goaccess";
  tag = lib.concatStrings [
    goaccess.version
    tagSuffix
    (if builtins.isNull distro then "" else "-${distro}")
  ];

  copyToRoot = buildEnv {
    name = "root";

    paths = [
      (goaccess.overrideAttrs {
        inherit withGeolocation;

        postPatch = lib.optionalString withGeolite2 ''
          substituteInPlace config/goaccess.conf \
            --replace-fail "#geoip-database /usr/local/share/GeoIP/GeoLiteCity.dat" "geoip-database /share/GeoIP/GeoLite2-City.mmdb"
        '';
      })
    ] ++ lib.optional withGeolite2 geolite2;

    pathsToLink = [
      "/bin"
      "/etc"
      "/share"
    ];
  };

  config.Entrypoint = [ "goaccess" ];
}
