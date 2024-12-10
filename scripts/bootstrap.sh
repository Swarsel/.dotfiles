# highly inspired by https://github.com/EmergentMind/nix-config/blob/dev/scripts/bootstrap-nixos.sh
set -eo pipefail

target_hostname=""
target_destination=""
target_user="swarsel"
ssh_port="22"
temp=$(mktemp -d)

function help_and_exit() {
    echo
    echo "Remotely installs NixOS on a target machine using this nix-config."
    echo
    echo "USAGE: $0 -n <target_hostname> -d <target_destination> [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on."
    echo "  -d <target_destination>                 specify ip or url to the target host."
    echo "                                          target during install process."
    echo
    echo "OPTIONS:"
    echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
    echo "                                          Default='${target_user}'."
    echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=${ssh_port}."
    echo "  --impermanence                          Use this flag if the target machine has impermanence enabled. WARNING: Assumes /persist path."
    echo "  --debug                                 Enable debug mode."
    echo "  -h | --help                             Print this help."
    exit 0
}

function cleanup() {
    rm -rf "$temp"
}
trap cleanup exit

function red() {
    echo -e "\x1B[31m[!] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[31m[!] $($2) \x1B[0m"
    fi
}
function green() {
    echo -e "\x1B[32m[+] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[32m[+] $($2) \x1B[0m"
    fi
}
function yellow() {
    echo -e "\x1B[33m[*] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[33m[*] $($2) \x1B[0m"
    fi
}

function yes_or_no() {
    echo -en "\x1B[32m[+] $* [y/n] (default: y): \x1B[0m"
    while true; do
        read -rp "" yn
        yn=${yn:-y}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -n)
        shift
        target_hostname=$1
        ;;
    -d)
        shift
        target_destination=$1
        ;;
    -u)
        shift
        target_user=$1
        ;;
    --port)
        shift
        ssh_port=$1
        ;;
    --temp-override)
        shift
        temp=$1
        ;;
    --debug)
        set -x
        ;;
    -h | --help) help_and_exit ;;
    *)
        echo "Invalid option detected."
        help_and_exit
        ;;
    esac
    shift
done

ssh_cmd="ssh -oport=${ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t $target_user@$target_destination"
# ssh_root_cmd=$(echo "$ssh_cmd" | sed "s|${target_user}@|root@|") # uses @ in the sed switch to avoid it triggering on the $ssh_key value
ssh_root_cmd=${ssh_cmd/${target_user}@/root@}

scp_cmd="scp -oport=${ssh_port} -o StrictHostKeyChecking=no"

git_root=$(git rev-parse --show-toplevel)

green "Wiping known_hosts of $target_destination"
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts

green "Generating hardware-config.nix for $target_hostname and adding it to the nix-config."
$ssh_root_cmd "nixos-generate-config --no-filesystems --root /mnt"
mkdir profiles/"$target_hostname"
$scp_cmd root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "${git_root}"/profiles/"$target_hostname"/hardware-configuration.nix
