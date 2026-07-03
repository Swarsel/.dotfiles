{ lib, config, ... }:
let
  fmods = config.flake.modules;
  pickH = names: builtins.attrValues (lib.getAttrs names fmods.homeManager);
in
{
  flake.modules.homeManager = {
    profile-minimal = {
      imports = pickH [
        "settings"
        "sops"
        "kitty"
        "zsh"
        "git"
      ];
    };

    profile-public-small = {
      imports = pickH [
        "anki"
        "tray-applets"
        "blueman-applet"
        "custom-packages"
        "desktop"
        "direnv"
        "element"
        "eza"
        "firefox"
        "glide"
        "fuzzel"
        "settings"
        "gnome-keyring"
        "gpg-agent"
        "kitty"
        "nix-index"
        "nix-your-shell"
        "network-manager-applet"
        "packages"
        "password-store"
        "programs"
        "spicetify"
        "starship"
        "stylix"
        "symlink"
        "yubikey-touch-detector"
        "zellij"
        "zellij-keybinds"
        "zsh"
      ];

      swarselsystems.trayApplets.obsidian.enable = false;
    };

    profile-public = {
      imports = pickH [
        "attic-client"
        "atuin"
        "hexchat"
        "kdeconnect"
        "khal"
        "nixgl"
        "obs-studio"
        "opkssh"
        "spotify-player"
        "swayosd"
        "tmux"
        "vesktop"
        "shikane"
        "syncthing-tray"
        "waybar"
      ];

      swarselsystems.trayApplets.obsidian.enable = false;
    };

    profile-personal = { lib, ... }: {
      imports = pickH [
        "emacs"
        "env"
        "git"
        "mail"
        "obsidian"
        "ssh"
      ];

      swarselsystems.trayApplets.obsidian.enable = lib.swarselsystems.mkStrong true;
    };

    profile-dgxspark = {
      imports = pickH [
        "atuin"
        "bash"
        "blueman-applet"
        "direnv"
        "eza"
        "firefox"
        "glide"
        "fuzzel"
        "settings"
        "git"
        "gpg-agent"
        "kitty"
        "nix-index"
        "nixgl"
        "nix-your-shell"
        "network-manager-applet"
        "sops"
        "starship"
        "stylix"
        "tmux"
        "zellij"
        "zellij-keybinds"
        "zsh"
      ];
    };
  };
}
