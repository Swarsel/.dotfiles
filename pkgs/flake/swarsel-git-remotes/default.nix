{
  name,
  gh,
  git,
  writeShellApplication,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    gh
    git
  ];
  text = ''
    user=$(git config github.user)
    forge_remote=$(git config forge.remote)
    forge_url=$(git config forge.url)

    slug_of() {
        local url=''${1%/}
        url=''${url%.git}
        if [[ $url =~ ^(git@github\.com:|ssh://git@github\.com/|https://github\.com/)([^/]+/[^/]+)$ ]]; then
            echo "''${BASH_REMATCH[2]}"
        elif [[ ''${url,,} == "''${forge_url,,}"/* ]]; then
            echo "$user/''${url##*/}"
        fi
    }

    is_own() {
        local owner=''${1%%/*}
        [[ ''${owner,,} == "''${user,,}" ]]
    }

    lookup() {
        gh api "repos/$1" --jq '[.full_name, .name, (.parent.full_name // "")] | @tsv' 2>/dev/null
    }

    remote() {
        echo "$dir: git remote $*"
        git -C "$dir" remote "$@"
    }

    set_remote() {
        local current
        if ! current=$(git -C "$dir" remote get-url "$1" 2>/dev/null); then
            remote add "$1" "$2"
        elif [[ $current != "$2" ]]; then
            remote set-url "$1" "$2"
        fi
    }

    setup() {
        local dir=$1 origin slug info full_name name parent upstream
        if ! origin=$(git -C "$dir" remote get-url origin 2>/dev/null); then
            echo "$dir: no origin remote, skipping"
            return
        fi
        slug=$(slug_of "$origin")
        if [[ -z $slug ]]; then
            echo "$dir: origin is neither on GitHub nor on $forge_url, skipping"
            return
        fi
        if ! info=$(lookup "$slug"); then
            if [[ $origin != *github.com[:/]* ]] || ! is_own "$slug"; then
                echo "$dir: $slug is not on GitHub, skipping"
                return
            fi
            info=$(printf '%s\t%s\t' "$slug" "''${slug##*/}")
        fi
        IFS=$'\t' read -r full_name name parent <<<"$info"

        if ! is_own "$full_name"; then
            upstream=$full_name
            IFS=$'\t' read -r full_name name parent <<<"$(lookup "$user/$name")"
            if [[ ''${parent,,} != "''${upstream,,}" ]]; then
                echo "$dir: $user has no fork of $upstream, skipping"
                return
            fi
            if ! git -C "$dir" remote get-url upstream >/dev/null 2>&1; then
                remote rename origin upstream
            fi
        fi

        set_remote origin "git@github.com:$full_name.git"
        if [[ -n $parent ]]; then
            set_remote upstream "https://github.com/$parent.git"
        fi
        set_remote "$forge_remote" "$forge_url/$name.git"
    }

    for dir in "''${@:-.}"; do
        setup "$dir"
    done
  '';
}
