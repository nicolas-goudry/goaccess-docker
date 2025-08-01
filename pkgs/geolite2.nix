{
  stdenv,
  lib,
  fetchFromGitHub,
  writeShellApplication,
  common-updater-scripts,
  curl,
  jq,
  mmdbinspect,
}:

let
  owner = "P3TERX";
  repo = "GeoLite.mmdb";
in
stdenv.mkDerivation {
  name = "geolite2";
  version = "2025.08.01";

  src = fetchFromGitHub {
    inherit owner repo;

    rev = "download";
    hash = "sha256-P+MCkV9GrFGA4ReMNq7hQs/1BNET2zx/1NgXf2uZErw=";
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
      mmdbinspect -db $db 8.8.8.8 >/dev/null
    done

    runHook postCheck
  '';

  passthru.updateScript = writeShellApplication {
    name = "geolite2-update";

    runtimeInputs = [
      common-updater-scripts
      curl
      jq
    ];

    text = ''
      latest=$(curl https://api.github.com/repos/${owner}/${repo}/releases/latest | jq -r '.name')
      update-source-version geolite2 "$latest" --ignore-same-version
    '';
  };

  meta = {
    description = "MaxMind's GeoIP2 GeoLite2 Country, City, and ASN databases";
    homepage = "https://dev.maxmind.com/geoip/geolite2-free-geolocation-data/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ nicolas-goudry ];
  };
}
