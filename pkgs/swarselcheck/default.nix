{ writeShellApplication, kitty, element-desktop-wayland, vesktop, spotify-player, sway, jq }:

writeShellApplication {
  name = "swarselcheck";
  runtimeInputs = [ kitty element-desktop-wayland vesktop spotify-player jq ];
  text = builtins.readFile ../../scripts/swarselcheck.sh;
}
