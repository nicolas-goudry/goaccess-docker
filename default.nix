{
  pkgs ? import (fetchTarball "https://github.com/nixos/nixpkgs/archive/25.05.tar.gz") { },
  geolite2 ? pkgs.callPackage ./pkgs/geolite2.nix { },
  distro ? null,
  withGeolocation ? withGeolite2,
  withGeolite2 ? false,
  ...
}@args:

let
  inherit (pkgs) lib dockerTools goaccess;

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
    if builtins.isNull distro then null else dockerTools.pullImage (distros.${distro} or throwDistro);
in
dockerTools.buildLayeredImage {
  inherit fromImage;

  name = "goaccess";
  tag = lib.concatStrings [
    goaccess.version
    tagSuffix
    (if builtins.isNull distro then "" else "-${distro}")
  ];

  contents = [
    (goaccess.overrideAttrs {
      inherit withGeolocation;

      postPatch = lib.optionalString withGeolite2 ''
        substituteInPlace config/goaccess.conf \
          --replace-fail "#geoip-database /usr/local/share/GeoIP/GeoLiteCity.dat" "geoip-database ${geolite2}/share/GeoIP/GeoLite2-City.mmdb"
      '';
    })
  ] ++ lib.optional withGeolite2 geolite2;

  config.Cmd = [ "goaccess" ];
}
