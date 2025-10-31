{ name, writeShellApplication, git, gnugrep, findutils, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ git gnugrep findutils ];
  text = ''

    function help_and_exit() {
        echo
        echo "Remotely installs SwarselSystem on a target machine including secret deployment."
        echo
        echo "USAGE: $0 [-f/-t} <from> <to>"
        echo
        echo "ARGS:"
        echo "  -f | --filenames                        Replace in filenames."
        echo "  -d | --directory                        Replace text in files within this directory."
        echo "  -r | --repo                             Replace text in files in the entire git repo."
        echo "  -h | --help                             Print this help."
        exit 0
    }

    target_files=false
    target_repo=false
    target_dirs=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --filenames)
            shift
            target_files=true
            ;;
        -r | --repo)
            shift
            target_repo=rue
            ;;
        -d | --directory)
            shift
            target_dirs=rue
            ;;
        -h | --help) help_and_exit ;;
        *)
            echo "Invalid option detected."
            help_and_exit
            ;;
        esac
        shift
    done


    if [[ $target_files == "true" ]]; then
      for file in $(git ls-files | grep "$1" | sed -e "s/\($1[^/]*\).*/\1/" | uniq); do
        git mv "$file" "''${file//$1/$2}"
      done
    fi

    if [[ $target_repo == "true" ]]; then
      git grep -l "$1" | xargs sed -i "s/$1/$2/g"
    fi

    if [[ $target_dirs == "true" ]]; then
      grep -rl "$1" . | xargs sed -i "s/$1/$2/g"
    fi
      '';
}
