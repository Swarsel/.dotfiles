{ self, lib, config, globals, ... }:
let
  localIp = globals.networks.home.hosts.${config.node.name}.ipv4;
  subnetMask = globals.networks.home.subnetMask4;
  gatewayIp = globals.hosts.${config.node.name}.defaultGateway4;
in
{
  options.swarselmodules.server.diskEncryption = lib.mkEnableOption "enable disk encryption config";
  config = lib.mkIf (config.swarselmodules.server.diskEncryption && config.swarselsystems.isCrypted) {

    boot.kernelParams = lib.mkIf (!config.swarselsystems.isLaptop) [ "ip=${localIp}::${gatewayIp}:${subnetMask}:${config.networking.hostName}::none" ];
    boot.initrd = {
      availableKernelModules = [ "r8169" ];
      network = {
        enable = true;
        udhcpc.enable = lib.mkIf config.swarselsystems.isLaptop true;
        flushBeforeStage2 = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeyFiles = [
            (self + /secrets/keys/ssh/yubikey.pub)
            (self + /secrets/keys/ssh/magicant.pub)
          ];
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        };
        postCommands = ''
          echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
        '';
      };
    };

  };
}
