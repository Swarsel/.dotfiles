{ self, writeShellApplication, kitty, element-desktop-wayland, vesktop, spotify-player, jq }:
let
  name = "swarselcheck";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ kitty element-desktop-wayland vesktop spotify-player jq ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
