set -eo pipefail

target_flake="chaostheatre"
target_user="swarsel"
fs_type="ext4"
disk=""

function help_and_exit() {
    echo
    echo "Remotely installs NixOS on a target machine using this nix-config."
    echo
    echo "USAGE: $0 -d <disk> [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -d <disk>                               specify disk to install on."
    echo "  -f <target_flake>                       specify flake to deploy the nixos config of."
    echo "                                          Default: chaostheatre"
    echo "  -u <target_user>                        specify user to deploy for."
    echo "                                          Default: swarsel"
    echo "  -t <fs_type>                            specify file system type to deploy for."
    echo "                                          Default: ext4"
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

sudo rm -rf .cache/nix
sudo rm -rf .dotfiles

green "Cloning repository from GitHub"
git clone https://github.com/Swarsel/.dotfiles.git

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

green "Creating /boot partition"
sudo parted -a optimal --script "$disk" mklabel gpt
sudo parted -a optimal --script "$disk" mkpart "boot" fat32 1MiB 1025MiB
sudo parted -a optimal --script "$disk" set 1 esp on

green "Creating / partition"
sudo parted -a optimal --script "$disk" mkpart "root" "$fs_type" 1025MiB 100%
sudo parted -a optimal --script "$disk" type 2 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709

green "Ensuring proper file systems"
sudo mkfs.fat -F32 "$disk"1
sudo mkfs."${fs_type}" -F "$disk"2

green "Generating hardware configuration"
sudo mount "$disk"2 /mnt
sudo mkdir -p /mnt/boot
sudo mount "$disk"1 /mnt/boot
sudo nixos-generate-config --root /mnt --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/

git add /home/"$target_user"/.dotfiles/hosts/nixos/"$target_flake"/hardware-configuration.nix
# sudo rm -rf /root/.nix-defexpr/channels
# sudo rm -rf /nix/var/nix/profiles/per-user/channels
sudo mkdir -p /root/.local/share/nix/
printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | sudo tee /root/.local/share/nix/trusted-settings.json > /dev/null
green "Installing flake $target_flake"
sudo nixos-install --flake .#"$target_flake"
yellow "Please keep in mind that this is only a demo of the configuration. Things might break unexpectedly."
green "Installation finished! Reboot to see changes"
