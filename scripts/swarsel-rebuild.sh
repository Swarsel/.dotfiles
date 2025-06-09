set -eo pipefail

target_config="chaostheatre"
target_user="swarsel"

function help_and_exit() {
    echo
    echo "Builds SwarselSystem configuration."
    echo
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -n <target_config>                       specify nixos config to build."
    echo "                                          Default: chaostheatre"
    echo "  -u <target_user>                        specify user to deploy for."
    echo "                                          Default: swarsel"
    echo "  -h | --help                             Print this help."
    exit 0
}

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

cd /home/"$target_user"

if [ ! -d /home/"$target_user"/.dotfiles ]; then
    green "Cloning repository from GitHub"
    git clone https://github.com/Swarsel/.dotfiles.git
else
    red "A .dotfiles repository is in the way. Please (re-)move the repository and try again."
    exit 1
fi

local_keys=$(ssh-add -L || true)
pub_key=$(cat /home/"$target_user"/.dotfiles/secrets/keys/ssh/yubikey.pub)
read -ra pub_arr <<< "$pub_key"

cd .dotfiles
if [[ $local_keys != *"${pub_arr[1]}"* ]]; then
    yellow "The ssh key for this configuration is not available."
    green "Adjusting flake.nix so that the configuration is buildable"
    sed -i '/nix-secrets = {/,/^[[:space:]]*};/d' flake.nix
    sed -i '/vbc-nix = {/,/^[[:space:]]*};/d' flake.nix
    sed -i '/[[:space:]]*\/\/ (inputs.vbc-nix.overlays.default final prev)/d' overlays/default.nix
    rm modules/home/common/env.nix
    rm modules/home/common/gammastep.nix
    rm modules/home/common/git.nix
    rm modules/home/common/mail.nix
    rm modules/home/common/yubikey.nix
    rm modules/nixos/server/restic.nix
    rm modules/nixos/common/home-manager-extra.nix
    rm hosts/nixos/sync/default.nix
    rm -rf modules/nixos/server
    rm -rf modules/home/server
    nix flake update vbc-nix
    git add .
else
    green "Valid SSH key found! Continuing with installation"
fi
sudo nixos-generate-config --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/
git add /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/hardware-configuration.nix

green "Installing flake $target_config"
sudo nixos-rebuild --show-trace --flake .#"$target_config" boot
yellow "Please keep in mind that this is only a demo of the configuration. Things might break unexpectedly."
