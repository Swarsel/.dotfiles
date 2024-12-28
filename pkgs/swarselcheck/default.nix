{ self, name, writeShellApplication, kitty, element-desktop-wayland, vesktop, spotify-player, jq }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ kitty element-desktop-wayland vesktop spotify-player jq ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
