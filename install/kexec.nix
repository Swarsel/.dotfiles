{ lib, pkgs, modulesPath, options, ... }:
{
  disabledModules = [
    # This module adds values to multiple lists (systemPackages, supportedFilesystems)
    # which are impossible/unpractical to remove, so we disable the entire module.
    "profiles/base.nix"
  ];

  imports = [
    # reduce closure size by removing perl
    "${modulesPath}/profiles/perlless.nix"
    # FIXME: we still are left with nixos-generate-config due to nixos-install-tools
    { system.forbiddenDependenciesRegexes = lib.mkForce [ ]; }
  ];

  config = {
    networking.hostName = "brickroad";

    system = {
      # nixos-option is mainly useful for interactive installations
      tools.nixos-option.enable = false;
      # among others, this prevents carrying a stdenv with gcc in the image
      extraDependencies = lib.mkForce [ ];
    };
    # prevents shipping nixpkgs, unnecessary if system is evaluated externally
    nix.registry = lib.mkForce { };

    # would pull in nano
    programs.nano.enable = false;

    # prevents strace
    environment = {
      defaultPackages = lib.mkForce [
        pkgs.parted
        pkgs.gptfdisk
        pkgs.e2fsprogs
      ];

      systemPackages = with pkgs; [
        cryptsetup.bin
      ];

      # Don't install the /lib/ld-linux.so.2 stub. This saves one instance of nixpkgs.
      ldso32 = null;
    };

    # included in systemd anyway
    systemd.sysusers.enable = true;

    # normal users are not allowed with sys-users
    # see https://github.com/NixOS/nixpkgs/pull/328926
    users.users.nixos = {
      isSystemUser = true;
      isNormalUser = lib.mkForce false;
      shell = "/run/current-system/sw/bin/bash";
      group = "nixos";
    };
    users.groups.nixos = { };

    security = {
      # we have still run0 from systemd and most of the time we just use root
      sudo.enable = false;
      polkit.enable = lib.mkForce false;
      # introduces x11 dependencies
      pam.services.su.forwardXAuth = lib.mkForce false;
    };

    documentation = {
      enable = false;
      man.enable = false;
      nixos.enable = false;
      info.enable = false;
      doc.enable = false;
    };

    services = {
      # no dependency on x11
      dbus.implementation = "broker";
      # we prefer root as this is also what we use in nixos-anywhere
      getty.autologinUser = lib.mkForce "root";
      # included in systemd anyway
      userborn.enable = false;
    };



    # we are missing this from base.nix
    boot.supportedFilesystems = [
      "ext4"
      "btrfs"
      "xfs"
    ];
  } // lib.optionalAttrs (options.hardware ? firmwareCompression) {
    hardware.firmwareCompression = "xz";
  };
}
