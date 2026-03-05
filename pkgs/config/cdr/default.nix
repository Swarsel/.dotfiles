{ name, homeConfig, writeShellApplication, fzf, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ fzf ];
  text = ''
    cdr_had_errexit=0
    cdr_had_nounset=0
    cdr_had_pipefail=0

    case $- in
      *e*) cdr_had_errexit=1 ;;
    esac

    case $- in
      *u*) cdr_had_nounset=1 ;;
    esac

    if set -o 2>/dev/null | grep -q '^pipefail[[:space:]]*on'; then
      cdr_had_pipefail=1
    fi

    set +e
    set +u
    set +o pipefail 2>/dev/null || true

    DOCUMENT_DIR_WORK=${homeConfig.systemd.user.sessionVariables.DOCUMENT_DIR_WORK or ""}
    DOCUMENT_DIR_PRIV=${homeConfig.systemd.user.sessionVariables.DOCUMENT_DIR_PRIV}
    FLAKE=${homeConfig.home.sessionVariables.FLAKE}

    cdr_target="$( (find "$DOCUMENT_DIR_WORK" "$DOCUMENT_DIR_PRIV" -maxdepth 1 && echo "$FLAKE") | fzf )"

    if [ -n "$cdr_target" ]; then
      cd "$cdr_target" || true
    fi

    if [ "$cdr_had_errexit" -eq 1 ]; then set -e; else set +e; fi
    if [ "$cdr_had_nounset" -eq 1 ]; then set -u; else set +u; fi
    if [ "$cdr_had_pipefail" -eq 1 ]; then set -o pipefail; else set +o pipefail 2>/dev/null || true; fi
  '';
}
