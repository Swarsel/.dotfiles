{ name, writeShellApplication, fzf, findutils, home-manager, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ fzf findutils home-manager ];
  text = ''
    genpath=$(home-manager generations | head -1 | awk '{print $7}')
    dirs=$(find "$genpath/specialisation" -type l 2>/dev/null; [ -d "$genpath" ] && echo "$genpath")
    "$(echo "$dirs" | fzf --prompt="Choose home-manager specialisation to activate")"/activate
  '';
}
