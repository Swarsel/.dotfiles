{ config, lib, pkgs, inputs, ... }:

{

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

services.xserver = {
  xkb.layout = "us";
  xkb.variant = "altgr-intl";
};

nix.settings.experimental-features = ["nix-command" "flakes"];

# use ozone for wayland - chromium apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # wordlist for look
  environment.wordlist.enable = true;
  # gstreamer plugins for nautilus (used for file metadata)
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

time.hardwareClockInLocalTime = true;

# dont style GRUB with stylix
stylix.targets.grub.enable = false; # the styling makes grub more ugly

security.polkit.enable = true;

nix.gc = {
  automatic = true;
  randomizedDelaySec = "14m";
  dates = "weekly";
  options = "--delete-older-than 10d";
};

nix.optimise = {
  automatic = true;
  dates = [ "weekly" ];
};

# systemd
  systemd.extraConfig = ''
  DefaultTimeoutStartSec=60s
  DefaultTimeoutStopSec=15s
'';

hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};

sound.enable = true;
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
  # yubioath-flutter
  # yubikey-manager
  # yubikey-manager-qt
  yubico-piv-tool
  # pinentry

  # theme related
  gnome.adwaita-icon-theme

  # kde-connect
  xdg-desktop-portal

  # bluetooth
  bluez

  # lsp-related -------------------------------
  # nix
  # latex
  texlab
  ghostscript_headless
  # wireguard
  wireguard-tools
  # rust
  rust-analyzer
  clippy
  rustfmt
  # go
  go
  gopls
  # zig
  zig
  zls
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

  (stdenv.mkDerivation {
    name = "oama";

    src = pkgs.fetchurl {
      name = "oama";
      url = "https://github.com/pdobsan/oama/releases/download/0.13.1/oama-0.13.1-Linux-x86_64-static.tgz";
      sha256 = "sha256-OTdCObVfnMPhgZxVtZqehgUXtKT1iyqozdkPIV+i3Gc=";
    };

    phases = [
      "unpackPhase"
    ];

    unpackPhase = ''
    mkdir -p $out/bin
    tar xvf $src -C $out/
    mv $out/oama-0.13.1-Linux-x86_64-static/oama $out/bin/
    '';

  })

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

# enable scanners over network
hardware.sane = {
  enable = true;
  extraBackends = [ pkgs.sane-airscan ];
};

# enable discovery and usage of network devices (esp. printers)
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.gutenprint
    pkgs.gutenprintBin
  ];
  services.printing.browsedConf = ''
BrowseDNSSDSubTypes _cups,_print
BrowseLocalProtocols all
BrowseRemoteProtocols all
CreateIPPPrinterQueues All

BrowseProtocols all
    '';
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

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
