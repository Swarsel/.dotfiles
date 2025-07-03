# Adapted from https://github.com/bennofs/nix-index/blob/master/command-not-found.sh
command_not_found_handle() {
    if [ -n "${MC_SID-}" ] || ! [ -t 1 ]; then
        >&2 echo "$1: command not found"
        return 127
    fi

    echo -n "searching nix-index..."
    ATTRS=$(@nix-locate@ --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$1")

    case $(echo -n "$ATTRS" | grep -c "^") in
    0)
        >&2 echo -ne "$(@tput@ el1)\r"
        >&2 echo "$1: command not found"
        ;;
    *)
        >&2 echo -ne "$(@tput@ el1)\r"
        >&2 echo "The program ‘$(@tput@ setaf 4)$1$(@tput@ sgr0)’ is currently not installed."
        >&2 echo "It is provided by the following derivation(s):"
        while read -r ATTR; do
            ATTR=${ATTR%.out}
            >&2 echo "  $(@tput@ setaf 12)nixpkgs#$(@tput@ setaf 4)$ATTR$(@tput@ sgr0)"
        done <<< "$ATTRS"
        ;;
    esac

    return 127
}

command_not_found_handler() {
    command_not_found_handle "$@"
    return $?
}
