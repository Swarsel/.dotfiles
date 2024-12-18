set -eo pipefail

target_flake="chaostheatre"
target_user="swarsel"

function help_and_exit() {
    echo
    echo "Remotely installs NixOS on a target machine using this nix-config."
    echo
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -f <target_flake>                       specify flake to deploy the nixos config of."
    echo "                                          Default: chaostheatre"
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
function yellow() {
    echo -e "\x1B[33m[*] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[33m[*] $($2) \x1B[0m"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -f)
        shift
        target_flake=$1
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
fi

local_keys=$(ssh-add -L || true)
pub_key=$(cat /home/"$target_user"/.dotfiles/secrets/keys/ssh/nbl-imba-2.pub)
read -ra pub_arr <<< "$pub_key"

cd .dotfiles
if [[ $local_keys != *"${pub_arr[1]}"* ]]; then
    yellow "The ssh key for this configuration is not available."
    green "Adjusting flake.nix so that the configuration is buildable"
    sed -i '/nix-secrets = {/,/^[[:space:]]*};/d' flake.nix
    git add flake.nix
fi
sudo nixos-generate-config --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/
git add /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
green "Installing flake $target_flake"
sudo nixos-rebuild --show-trace --flake .#"$target_flake" boot
yellow "Please keep in mind that this is only a demo of the configuration. Things might break unexpectedly."
git restore --staged /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
git restore /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
git restore --staged /home/"$target_user"/.dotfiles/flake.nix
git restore /home/"$target_user"/.dotfiles/flake.nix
