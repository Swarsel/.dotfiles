{
  name,
  writeShellApplication,
  git,
  ...
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [ git ];
  text = ''
    set -eo pipefail

    export NIX_CONFIG="experimental-features = nix-command flakes"

    target_config="hotel"
    target_user="swarsel"
    target_arch="$(uname -m)-linux"
    target_repo="https://github.com/Swarsel/.dotfiles.git"
    skip_hardware_config=0
    demo_flags=()

    function help_and_exit() {
      echo
      echo "Builds SwarselSystem configuration."
      echo
      echo "USAGE: $0 [OPTIONS]"
      echo
      echo "ARGS:"
      echo "  -n <target_config>                      specify nixos config to build."
      echo "                                          Default: hotel"
      echo "  -u <target_user>                        specify user to deploy for."
      echo "                                          Default: swarsel"
      echo "  -a <target_arch>                        specify target architecture."
      echo "                                          Default: $(uname -m)-linux"
      echo "  -r <target_repo>                        specify repository to clone."
      echo "                                          Default: https://github.com/Swarsel/.dotfiles.git"
      echo "  -H                                      keep the hardware configuration from the repository."
      echo "  -h | --help                             Print this help."
      exit 0
    }

    function red() {
      echo -e "\x1B[31m[!] $1 \x1B[0m"
      if [ -n "''${2-}" ]; then
        echo -e "\x1B[31m[!] $($2) \x1B[0m"
      fi
    }
    function green() {
      echo -e "\x1B[32m[+] $1 \x1B[0m"
      if [ -n "''${2-}" ]; then
        echo -e "\x1B[32m[+] $($2) \x1B[0m"
      fi
    }
    function yellow() {
      echo -e "\x1B[33m[*] $1 \x1B[0m"
      if [ -n "''${2-}" ]; then
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
      -a)
        shift
        target_arch=$1
        ;;
      -r)
        shift
        target_repo=$1
        ;;
      -H) skip_hardware_config=1 ;;
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
      green "Cloning repository from $target_repo"
      git clone "$target_repo" .dotfiles
    else
      red "A .dotfiles repository is in the way. Please (re-)move the repository and try again."
      exit 1
    fi
    cd .dotfiles

    local_keys=$(ssh-add -L || true)
    pub_key=$(cat files/public/ssh/yubikey.pub)
    read -ra pub_arr <<< "$pub_key"

    if [[ $local_keys != *"''${pub_arr[1]}"* ]]; then
      yellow "The ssh key for this configuration is not available."
      green "Overriding private inputs so that the configuration is buildable ..."
      demo_flags=(--override-input vbc-nix "path:$PWD/files/stub" --override-input repoSecrets "path:$PWD/files/demo" --no-write-lock-file)
    else
      green "Valid SSH key found! Continuing with installation"
    fi

    if [[ $skip_hardware_config -eq 1 ]]; then
      yellow "Keeping hardware configuration from the repository"
    else
      sudo nixos-generate-config --dir /home/"$target_user"/.dotfiles/hosts/nixos/"$target_arch"/"$target_config"/
      git add hosts/nixos/"$target_arch"/"$target_config"/hardware-configuration.nix
    fi

    green "Building flake $target_config"
    store_path=$(nix build "''${demo_flags[@]}" --no-link --print-out-paths .#nixosConfigurations."$target_config".config.system.build.toplevel)

    green "Activating configuration $target_config on next boot"
    sudo nix-env --profile /nix/var/nix/profiles/system --set "$store_path"
    sudo "$store_path"/bin/switch-to-configuration boot
    yellow "Please keep in mind that this is only a demo of the configuration. Things might break unexpectedly."
  '';
}
