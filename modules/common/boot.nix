{
  flake.modules.nixos.boot =
    {
      lib,
      pkgs,
      globals,
      ...
    }:
    {
      config = {
        boot = {
          initrd.systemd = {
            users.root.shell = "${pkgs.bashInteractive}/bin/bash";
            enable = true;
            emergencyAccess = globals.root.hashedPassword;
            extraBin = {
              cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";
              ip = "${pkgs.iproute2}/bin/ip";
              ping = "${pkgs.iputils}/bin/ping";
            };
            storePaths = [ "${pkgs.bashInteractive}/bin/bash" ];
          };
          kernelParams = [ "log_buf_len=16M" ];
          loader.timeout = lib.mkDefault 2;
          tmp.useTmpfs = true;
        };

        console.earlySetup = true;

      };
    };
}
