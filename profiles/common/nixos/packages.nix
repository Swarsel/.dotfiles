{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # yubikey packages
    gnupg
    yubikey-personalization
    yubikey-personalization-gui
    yubico-pam
    yubioath-flutter
    yubikey-manager
    yubikey-manager-qt
    yubikey-touch-detector
    yubico-piv-tool
    cfssl
    pcsctools
    pcscliteWithPolkit.out

    # ledger packages
    ledger-live-desktop

    # pinentry
    dbus
    swaylock-effects
    syncthingtray-minimal

    # secure boot
    sbctl

    nix-index

    # keyboards
    qmk
    vial
    via

    # theme related
    adwaita-icon-theme

    # kde-connect
    xdg-desktop-portal
    xdg-desktop-portal-wlr

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
    # nix
    nixd
    # zig
    zig
    zls
    # cpp
    clang-tools
    # + cuda
    cudatoolkit
    # ansible
    ansible_2_15
    ansible-lint
    ansible-language-server
    molecule
    #lsp-bridge / python
    gcc
    gdb
    (python3.withPackages (ps: with ps; [ jupyter ipython pyqt5 epc orjson sexpdata six setuptools paramiko numpy pandas scipy matplotlib requests debugpy flake8 gnureadline python-lsp-server ]))
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
}
