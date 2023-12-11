{ config, lib, pkgs, inputs, ... }:

{

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # login keymap
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  # mount NAS drive
  # works only at home, but w/e
  fileSystems."/mnt/smb" = {
    device = "//192.168.1.3/Eternor";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=/etc/nixos/smb-secrets,uid=1000,gid=100"];
  };

  # enable flakes - urgent line!!
  nix.settings.experimental-features = ["nix-command" "flakes"];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # correct time between linux and windows
  time.hardwareClockInLocalTime = true;

  # dont style GRUB with stylix
  stylix.targets.grub.enable = false; # the styling makes grub more ugly

  # cura fix
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  #   wlr.enable = true;
  #   config = {
  #     common = {
  #       default = [
  #         "*"
  #       ];
  #     };
  #   };
  # };
  # wayland-related
  security.polkit.enable = true;
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # audio
  sound.enable = true;
  # nixpkgs.config.pulseaudio = true;
  hardware.pulseaudio= {
    enable = true;
    package = pkgs.pulseaudioFull;
  };
  hardware.enableAllFirmware = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Vienna";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

environment.systemPackages = with pkgs; [
  # yubikey packages
  gnupg
  yubikey-personalization
  yubikey-personalization-gui
  yubico-pam
  yubioath-flutter
  yubikey-manager
  yubikey-manager-qt
  yubico-piv-tool
  pinentry

  # theme related
  gnome.adwaita-icon-theme

  # kde-connect
  xdg-desktop-portal

  # bluetooth
  bluez

  # lsp-related -------------------------------
  # nix
  rnix-lsp
  # latex
  texlab
  ghostscript_headless
  # rust
  rust-analyzer
  clippy
  rustfmt
  # cpp
  clang-tools
  # + cuda
  cudatoolkit
  #lsp-bridge / python
  gcc
  gdb
  (python3.withPackages(ps: with ps; [ jupyter ipython pyqt5 epc orjson sexpdata six setuptools paramiko numpy pandas scipy matplotlib requests debugpy flake8 gnureadline python-lsp-server]))
  # (python3.withPackages(ps: with ps; [ jupyter ipython pyqt5 numpy pandas scipy matplotlib requests debugpy flake8 gnureadline python-lsp-server]))
  # --------------------------------------------
];

programs.dconf.enable = true;
programs.evince.enable = true;
programs.kdeconnect.enable = true;


# zsh section, do not delete ------
programs.zsh.enable = true;
users.defaultUserShell = pkgs.zsh;
environment.shells = with pkgs; [ zsh ];
environment.pathsToLink = [ "/share/zsh" ];
# ---------------------------------

services.blueman.enable = true;

# enable discovery and usage of network devices (esp. printers)
services.printing.enable = true;
services.avahi = {
  enable = true;
  nssmdns = true;
  openFirewall = true;
};

# nautilus file manager
services.gvfs.enable = true;

# Make CAPS work as a dual function ESC/CTRL key
services.interception-tools = {
  enable = true;
  udevmonConfig = let
    dualFunctionKeysConfig = builtins.toFile "dual-function-keys.yaml" ''
      TIMING:
        TAP_MILLISEC: 200
        DOUBLE_TAP_MILLISEC: 0

      MAPPINGS:
        - KEY: KEY_CAPSLOCK
          TAP: KEY_ESC
          HOLD: KEY_LEFTCTRL
    '';
  in ''
    - JOB: |
        ${pkgs.interception-tools}/bin/intercept -g $DEVNODE \
          | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dualFunctionKeysConfig} \
          | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE
      DEVICE:
        EVENTS:
          EV_KEY: [KEY_CAPSLOCK]
  '';
};

programs.ssh.startAgent = false;

services.pcscd.enable = true;

# environment.systemPackages = with pkgs; [
# --- IN SYSTEM PACKAGES SECTION ---
# ];

services.udev.packages = with pkgs; [
  yubikey-personalization
];

services.greetd = {
  enable = true;
  settings = {
    initial_session.command = "sway";
    # initial_session.user ="swarsel";
    default_session.command = ''
                ${pkgs.greetd.tuigreet}/bin/tuigreet \
                  --time \
                  --asterisks \
                  --user-menu \
                  --cmd sway
              '';
  };
};

environment.etc."greetd/environments".text = ''
              sway
            '';

}
