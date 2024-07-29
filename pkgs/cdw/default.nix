{ writeShellApplication, fzf }:

writeShellApplication {
  name = "cdw";
  runtimeInputs = [ fzf ];
  text = ''
    cd "$(git worktree list | fzf | awk '{print $1}')"
  '';
}
