{ name, homeConfig, writeShellApplication, fzf, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ fzf ];
  text = ''
    DOCUMENT_DIR_WORK=${homeConfig.systemd.user.sessionVariables.DOCUMENT_DIR_WORK or ""}
    DOCUMENT_DIR_PRIV=${homeConfig.systemd.user.sessionVariables.DOCUMENT_DIR_PRIV}
    FLAKE=${homeConfig.home.sessionVariables.FLAKE}

    cd "$( (find "$DOCUMENT_DIR_WORK" "$DOCUMENT_DIR_PRIV" -maxdepth 1 && echo "$FLAKE") | fzf )"
  '';
}
