{ writeShellApplication, kitty, element-desktop-wayland, discord, spotify-player, sway, jq }:

writeShellApplication {
  name = "swarselcheck";
  runtimeInputs = [ jq ];
  text = builtins.readFile ../../scripts/check.sh;
}
