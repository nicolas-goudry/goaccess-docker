{
  lib,
  xlib,
  writeShellApplication,
  coreutils,
  jq,
  skopeo-nix2container,
  trivy,
}:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  allImages = xlib.mkAllImages;
  allImagesImages = lib.mapAttrs (_: value: value.image) allImages;
in
writeShellApplication {
  inherit name;

  text = builtins.readFile ./script.sh;

  runtimeInputs =
    [
      coreutils
      jq
      skopeo-nix2container
      trivy
    ]
    # Add all built images to runtime environment
    ++ (lib.map (img: img.value) (lib.attrsToList allImagesImages));

  runtimeEnv =
    let
      fixImgNameForEnv = name: lib.replaceStrings [ "-" ] [ "_" ] name;

      # Attribute set of all images derivation paths and tags
      # Will add the following environment variables:
      # - `<imagename>_drv`: image store path
      # - `<imagename>_tag`: image tag
      imagesDrvs = lib.foldlAttrs (
        acc: name: value:
        let
          nameInEnv = fixImgNameForEnv name;
        in
        acc
        // {
          "${nameInEnv}_drv" = value.image;
          "${nameInEnv}_tag" = value.tag;
        }
      ) { } allImages;
    in
    {
      # List of all images to scan
      images = lib.map fixImgNameForEnv (lib.attrNames allImages);
    }
    // imagesDrvs;
}
