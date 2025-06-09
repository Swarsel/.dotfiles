set -eo pipefail

target_config="chaostheatre"
target_hostname="chaostheatre"
target_user="swarsel"
persist_dir=""
target_disk="/dev/vda"
disk_encryption=0

function help_and_exit() {
    echo
    echo "Locally installs SwarselSystem on this machine."
    echo
    echo "USAGE: $0 -n <target_config> -d <target_disk> [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  -n <target_config>                      specify the nixos config to deploy."
    echo "                                          Default: chaostheatre"
    echo "  -d <target_disk>                        specify disk to install on."
    echo "                                          Default: /dev/vda"
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
    -d)
        shift
        target_disk=$1
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

green "~SwarselSystems~ local installer"

cd /home/"$target_user"

sudo rm -rf /root/.cache/nix
sudo rm -rf .cache/nix
sudo rm -rf .dotfiles

green "Cloning repository from GitHub"
git clone https://github.com/Swarsel/.dotfiles.git

local_keys=$(ssh-add -L || true)
pub_key=$(cat /home/"$target_user"/.dotfiles/secrets/keys/ssh/yubikey.pub)
read -ra pub_arr <<< "$pub_key"

cd .dotfiles
if [[ $local_keys != *"${pub_arr[1]}"* ]]; then
    yellow "The ssh key for this configuration is not available."
    green "Adjusting flake.nix so that the configuration is buildable ..."
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
    cat > hosts/nixos/chaostheatre/options.nix << EOF
        { self, lib, ... }:
        {
          options = {
            swarselsystems = {
              modules = {
                home-managerExtra = lib.mkEnableOption "dummy option for chaostheatre";
              };
            };
          };
        }
EOF
    cat > hosts/nixos/chaostheatre/options-home.nix << EOF
        { self, lib, ... }:
        {
        options = {
          swarselsystems = {
            modules = {
              yubikey = lib.mkEnableOption "dummy option for chaostheatre";
              env = lib.mkEnableOption "dummy option for chaostheatre";
              git = lib.mkEnableOption "dummy option for chaostheatre";
              mail = lib.mkEnableOption "dummy option for chaostheatre";
              gammastep = lib.mkEnableOption "dummy option for chaostheatre";
            };
          };
        };
        }
EOF
    nix flake update vbc-nix
    git add .
else
    green "Valid SSH key found! Continuing with installation"
fi

green "Reading system information for $target_config ..."
DISK="$(nix eval --raw ~/.dotfiles#nixosConfigurations."$target_hostname".config.swarselsystems.rootDisk)"
green "Root Disk in config: $DISK - Root Disk passed in cli: $target_disk"

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

green "Setting up disk ..."
if [[ $target_config == "chaostheatre" ]]; then
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/v1.10.0 -- --mode destroy,format,mount --flake .#"$target_config" --yes-wipe-all-disks --arg diskDevice "$target_disk"
else
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#"$target_config" --yes-wipe-all-disks
fi
sudo mkdir -p /mnt/"$persist_dir"/home/"$target_user"/
sudo cp -r /home/"$target_user"/.dotfiles /mnt/"$persist_dir"/home/"$target_user"/
sudo chown -R 1000:100 /mnt/"$persist_dir"/home/"$target_user"

green "Generating hardware configuration ..."
sudo nixos-generate-config --root /mnt --no-filesystems --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/

green "Injecting initialSetup ..."
sudo sed -i '/  boot.extraModulePackages /a \  swarselsystems.initialSetup = true;' /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/hardware-configuration.nix

git add /home/"$target_user"/.dotfiles/hosts/nixos/"$target_config"/hardware-configuration.nix
sudo mkdir -p /root/.local/share/nix/
printf '{\"extra-substituters\":{\"https://nix-community.cachix.org\":true,\"https://nix-community.cachix.org https://cache.ngi0.nixos.org/\":true},\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true,\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=\":true}}' | sudo tee /root/.local/share/nix/trusted-settings.json > /dev/null
green "Installing flake $target_config"
sudo nixos-install --flake .#"$target_config"
green "Installation finished! Reboot to see changes"
