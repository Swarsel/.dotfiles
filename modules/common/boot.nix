{
  flake.modules.nixos.boot = { lib, pkgs, globals, ... }:
    {
      config = {
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
  ;
}
