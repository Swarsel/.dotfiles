{ name, writeShellApplication, fzf, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ fzf ];
  text = ''
    cd "$(git worktree list | fzf | awk '{print $1}')"
  '';
}
