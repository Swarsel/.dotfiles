set -eo pipefail

target_config="chaostheatre"
target_hostname="chaostheatre"
target_user="swarsel"
persist_dir=""
disk_encryption=0

function help_and_exit() {
    echo
    echo "Locally installs SwarselSystem on this machine."
    echo
    echo "USAGE: $0 -n <target_config> [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -n <target_config>                      specify the nixos config to deploy."
    echo "                                          Default: chaostheatre"
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
        target_hostname=$1
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

green "~SwarselSystems~ remote installer"

cd /home/"$target_user"

sudo rm -rf /root/.cache/nix
sudo rm -rf .cache/nix
sudo rm -rf .dotfiles

green "Cloning repository from GitHub"
git clone https://github.com/Swarsel/.dotfiles.git

green "Reading system information for $target_config ..."
DISK="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.rootDisk)"
green "Root Disk: $DISK"

CRYPTED="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isCrypted)"
if [[ $CRYPTED == "true" ]]; then
    green "Encryption: ✓"
    disk_encryption=1
else
    red "Encryption: X"
    disk_encryption=0
fi

IMPERMANENCE="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isImpermanence)"
if [[ $IMPERMANENCE == "true" ]]; then
    green "Impermanence: ✓"
    persist_dir="/persist"
else
    red "Impermanence: X"
    persist_dir=""
fi

SWAP="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isSwap)"
if [[ $SWAP == "true" ]]; then
    green "Swap: ✓"
else
    red "Swap: X"
fi

SECUREBOOT="$(nix eval ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.isSecureBoot)"
if [[ $SECUREBOOT == "true" ]]; then
    green "Secure Boot: ✓"
else
    red "Secure Boot: X"
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
else
    green "Valid SSH key found! Continuing with installation"
fi

if [ "$disk_encryption" -eq 1 ]; then
    while true; do
        green "Set disk encryption passphrase:"
        read -rs luks_passphrase
        green "Please confirm passphrase:"
        read -rs luks_passphrase_confirm
        if [[ $luks_passphrase == "$luks_passphrase_confirm" ]]; then
            echo "$luks_passphrase" > /tmp/disko-password
            break
        else
            red "Passwords do not match"
        fi
    done
fi

green "Setting up disk"
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#"$target_config" --yes-wipe-all-disks
sudo mkdir -p /mnt/"$persist_dir"/home/"$target_user"/
sudo cp -r /home/"$target_user"/.dotfiles /mnt/"$persist_dir"/home/"$target_user"/
sudo chown -R 1000:100 /mnt/"$persist_dir"/home/"$target_user"

green "Generating hardware configuration"
sudo nixos-generate-config --root /mnt --no-filesystems --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/

green "Injecting initialSetup"
sudo sed -i '/  boot.extraModulePackages /a \  swarselsystems.initialSetup = true;' /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/hardware-configuration.nix

git add /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/hardware-configuration.nix
sudo mkdir -p /root/.local/share/nix/
printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | sudo tee /root/.local/share/nix/trusted-settings.json > /dev/null
green "Installing flake $target_config"
sudo nixos-install --flake .#"$target_config"
green "Installation finished! Reboot to see changes"
