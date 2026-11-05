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
          bcache.enable = false;
          initrd.systemd = {
            users.root.shell = "${pkgs.bashInteractive}/bin/bash";
            emergencyAccess =
              if globals.root.emergencyHashedPassword == null then
                false
              else
                globals.root.emergencyHashedPassword;
            extraBin = {
              cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";
              ip = "${pkgs.iproute2}/bin/ip";
              ping = "${pkgs.iputils}/bin/ping";
            };
            storePaths = [ "${pkgs.bashInteractive}/bin/bash" ];
          };
          kernelParams = [ "log_buf_len=16M" ];
          loader.timeout = lib.mkDefault 2;
          swraid.enable = false;
          tmp.useTmpfs = true;
        };

        console.earlySetup = true;

      };
    };
}
