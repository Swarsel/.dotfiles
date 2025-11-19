{ name, writeShellApplication, fzf, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ fzf ];
  text = ''
    git checkout "$(git branch --list | grep -v "^\*" | fzf | awk '{print $1}')"
  '';
}
