set -eo pipefail

target_config="hotel"
target_user="swarsel"

function help_and_exit() {
    echo
    echo "Locally installs SwarselSystem on this machine."
    echo
    echo "USAGE: $0 -d <disk> [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -d <disk>                               specify disk to install on."
    echo "  -n <target_config>                      specify the nixos config to deploy."
    echo "                                          Default: hotel"
    echo "                                          Default: hotel"
    echo "  -u <target_user>                        specify user to deploy for."
    echo "                                          Default: swarsel"
    echo "  -h | --help                             Print this help."
    exit 0
}

function green() {
    echo -e "\x1B[32m[+] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[32m[+] $($2) \x1B[0m"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -n)
        shift
        target_config=$1
        ;;
    -u)
        shift
        target_user=$1
        ;;
    -h | --help) help_and_exit ;;
    *)
        echo "Invalid option detected."
        help_and_exit
        ;;
    esac
    shift
done

function cleanup() {
    sudo rm -rf .cache/nix
    sudo rm -rf /root/.cache/nix
}
trap cleanup exit

sudo rm -rf .cache/nix
sudo rm -rf /root/.cache/nix

green "~SwarselSystems~ remote post-installer"

cd /home/"$target_user"/.dotfiles

SECUREBOOT="$(nix eval ~/.dotfiles#nixosConfigurations."$target_config".config.swarselsystems.isSecureBoot)"

if [[ $SECUREBOOT == "true" ]]; then
    green "Setting up secure boot keys"
    sudo mkdir -p /var/lib/sbctl
    sbctl create-keys || true
    sbctl enroll-keys --ignore-immutable --microsoft || true
fi

sudo nixos-rebuild --flake .#"$target_config" switch
green "Post-install finished!"
