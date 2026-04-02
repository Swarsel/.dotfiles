{ lib, pkgs, config, globals, ... }:
{
  options.swarselmodules.boot = lib.mkEnableOption "boot config";
  config = lib.mkIf config.swarselmodules.boot {
    boot = {
      initrd.systemd = {
        enable = true;
        emergencyAccess = globals.root.hashedPassword;
        users.root.shell = "${pkgs.bashInteractive}/bin/bash";
        storePaths = [ "${pkgs.bashInteractive}/bin/bash" ];
        extraBin = {
          ip = "${pkgs.iproute2}/bin/ip";
          ping = "${pkgs.iputils}/bin/ping";
          cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";
        };
      };
      kernelParams = [ "log_buf_len=16M" ];
      tmp.useTmpfs = true;
      loader.timeout = lib.mkDefault 2;
    };

    console.earlySetup = true;

  };
}
