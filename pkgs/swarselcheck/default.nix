{ writeShellApplication, kitty, element-desktop-wayland, discord, spotify-player, sway, jq }:

writeShellApplication {
  name = "swarselcheck";
  runtimeInputs = [ kitty element-desktop-wayland discord spotify-player jq ];
  text = builtins.readFile ../../scripts/swarselcheck.sh;
}
