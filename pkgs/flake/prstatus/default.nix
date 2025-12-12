{ name, writeShellApplication, curl, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ curl ];
  text = ''
    curl https://nixpkgs.molybdenum.software/api/v2/landings/"$1"
  '';
}
