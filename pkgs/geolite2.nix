{
  stdenv,
  lib,
  fetchFromGitHub,
  mmdbinspect,
}:

stdenv.mkDerivation {
  name = "geolite2";

  src = fetchFromGitHub {
    owner = "P3TERX";
    repo = "GeoLite.mmdb";
    rev = "download";
    hash = "sha256-Cq6tilRYNPFJReHdHHqzjRfaEIajy9+5GYegAHND5OA=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = false;
  dontFixup = true;
  doInstallCheck = true;

  installCheckInputs = [
    mmdbinspect
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/GeoIP
    cp ./GeoLite2-*.mmdb $out/share/GeoIP

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preCheck

    for db in ./GeoLite2-*.mmdb; do
      mmdbinspect -db $db 8.8.8.8
    done

    runHook postCheck
  '';

  meta = {
    description = "MaxMind's GeoIP2 GeoLite2 Country, City, and ASN databases";
    homepage = "https://dev.maxmind.com/geoip/geolite2-free-geolocation-data/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ nicolas-goudry ];
  };
}
