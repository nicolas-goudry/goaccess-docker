{ writeShellApplication, coreutils, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
in
writeShellApplication {
  inherit name;

  text = builtins.readFile ./script.sh;

  runtimeInputs = [
    coreutils
  ];
}
