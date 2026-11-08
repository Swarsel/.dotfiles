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
    usage() {
        cat <<USAGE
    Usage: git setup-remotes [DIR...]

    Points the remotes of each repository DIR (default: .) at
      origin    the GitHub repository of github.user (a fork of it if origin is someone else's)
      upstream  the parent repository, if origin is a fork
      forge     forge.url/<name>.git, added as the remote named forge.remote
    USAGE
    }

    die() {
        echo "error: $*" >&2
        exit 1
    }

    github_slug() {
        local url=''${1%/}
        url=''${url%.git}
        if [[ $url =~ ^(git@github\.com:|ssh://git@github\.com/|https://github\.com/)([^/]+/[^/]+)$ ]]; then
            echo "''${BASH_REMATCH[2]}"
        fi
    }

    repo_key() {
        local key
        key=$(github_slug "$1")
        key=''${key:-$1}
        echo "''${key,,}"
    }

    is_own() {
        local owner=''${1%%/*}
        [[ ''${owner,,} == "''${github_user,,}" ]]
    }

    repo_info() {
        local info
        info=$(gh api "repos/$1" --jq '[.full_name, .name, (.parent.full_name // "")] | @tsv' 2>/dev/null) || return 1
        echo "$info"
    }

    remote() {
        echo "$dir: git remote $*"
        git -C "$dir" remote "$@"
    }

    ensure_remote() {
        local current
        if ! current=$(git -C "$dir" remote get-url "$1" 2>/dev/null); then
            remote add "$1" "$2"
        elif [[ $(repo_key "$current") != "$(repo_key "$2")" ]]; then
            remote set-url "$1" "$2"
        fi
    }

    setup() {
        local dir=$1 origin slug info full_name name parent upstream
        if ! origin=$(git -C "$dir" remote get-url origin 2>/dev/null); then
            echo "$dir: no origin remote, skipping"
            return
        fi
        slug=$(github_slug "$origin")
        if [[ -z $slug && ''${origin,,} == "''${forge_url,,}"/* ]]; then
            slug=''${origin%/}
            slug=''${slug%.git}
            slug=$github_user/''${slug##*/}
        fi
        if [[ -z $slug ]]; then
            echo "$dir: origin is neither on GitHub nor on $forge_url, skipping"
            return
        fi
        if ! info=$(repo_info "$slug"); then
            if [[ -z $(github_slug "$origin") ]] || ! is_own "$slug"; then
                echo "$dir: $slug is not on GitHub, skipping"
                return
            fi
            info=$(printf '%s\t%s\t' "$slug" "''${slug##*/}")
        fi
        IFS=$'\t' read -r full_name name parent <<<"$info"
        if ! is_own "$full_name"; then
            upstream=$full_name
            info=$(repo_info "$github_user/$name") || info=""
            IFS=$'\t' read -r full_name name parent <<<"$info"
            if [[ ''${parent,,} != "''${upstream,,}" ]]; then
                echo "$dir: $github_user has no fork of $upstream, skipping"
                return
            fi
            if ! git -C "$dir" remote get-url upstream >/dev/null 2>&1; then
                remote rename origin upstream
            fi
        fi
        ensure_remote origin "git@github.com:$full_name.git"
        if [[ -n $parent ]]; then
            ensure_remote upstream "https://github.com/$parent.git"
        fi
        ensure_remote "$forge_remote" "$forge_url/$name.git"
    }

    case "''${1:-}" in
    -h | --help)
        usage
        exit 0
        ;;
    esac

    github_user=$(git config github.user) || die "github.user is not set in git config"
    forge_remote=$(git config forge.remote) || die "forge.remote is not set in git config"
    forge_url=$(git config forge.url) || die "forge.url is not set in git config"

    if [[ $# -eq 0 ]]; then
        set -- .
    fi
    for dir in "$@"; do
        setup "$dir"
    done
  '';
}
