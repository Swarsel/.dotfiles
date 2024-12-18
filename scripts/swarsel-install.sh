set -eo pipefail

target_flake="chaostheatre"
target_user="swarsel"
fs_type="ext4"
disk="/dev/vda"

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
    echo "  -t <fs_type>                            specify file system type to deploy for."
    echo "                                          Default: ext4"
    echo "  -d <disk>                               specify disk to install on."
    echo "                                          Default: /dev/vda"
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
    -t)
        shift
        fs_type=$1
        ;;
    -d)
        shift
        disk=$1
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
sudo mkfs."$fs_type" "$disk"
sudo mount "$disk" /mnt
sudo nixos-generate-config --root /mnt --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/
git add /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
sudo mkdir -p /root/.local/share/nix/
printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' > /root/.local/share/nix/trusted-settings.json
green "Installing flake $target_flake"
sudo nixos-install --flake .#"$target_flake"
yellow "Please keep in mind that this is only a demo of the configuration. Things might break unexpectedly."
git restore --staged /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
git restore /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
git restore --staged /home/"$target_user"/.dotfiles/flake.nix
git restore /home/"$target_user"/.dotfiles/flake.nix
