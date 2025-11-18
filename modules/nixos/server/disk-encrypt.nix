{ self, pkgs, lib, config, globals, minimal, ... }:
let
  localIp = globals.networks.home.hosts.${config.node.name}.ipv4;
  subnetMask = globals.networks.home.subnetMask4;
  gatewayIp = globals.hosts.${config.node.name}.defaultGateway4;

  hostKeyPath = "/etc/secrets/initrd/ssh_host_ed25519_key";
in
{
  options.swarselmodules.server.diskEncryption = lib.mkEnableOption "enable disk encryption config";
  options.swarselsystems.networkKernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
  config = lib.mkIf (config.swarselmodules.server.diskEncryption && config.swarselsystems.isCrypted) {

    system.activationScripts.ensureInitrdHostkey = lib.mkIf (config.swarselprofiles.server || minimal) {
      text = ''
        [[ -e ${hostKeyPath} ]] || ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f ${hostKeyPath}
      '';
      deps = [ "users" ];
    };

    environment.persistence."/persist" = lib.mkIf (config.swarselsystems.isImpermanence && (config.swarselprofiles.server || minimal)) {
      files = [ hostKeyPath ];
    };

    boot = lib.mkIf (config.swarselprofiles.server || minimal) {
      kernelParams = lib.mkIf (!config.swarselsystems.isLaptop) [
        "ip=${localIp}::${gatewayIp}:${subnetMask}:${config.networking.hostName}::none"
      ];
      initrd = {
        availableKernelModules = config.swarselsystems.networkKernelModules;
        network = {
          enable = true;
          udhcpc.enable = lib.mkIf config.swarselsystems.isLaptop true;
          flushBeforeStage2 = true;
          ssh = {
            enable = true;
            port = 2222; # avoid hostkey changed nag
            authorizedKeyFiles = [
              (self + /secrets/keys/ssh/yubikey.pub)
              (self + /secrets/keys/ssh/magicant.pub)
            ];
            hostKeys = [ hostKeyPath ];
          };
          # postCommands = ''
          #   echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
          # '';
        };
        systemd = {
          initrdBin = with pkgs; [
            cryptsetup
          ];
          services = {
            unlock-luks = {
              wantedBy = [ "initrd.target" ];
              after = [ "network.target" ];
              before = [ "systemd-cryptsetup@cryptroot.service" ];
              path = [ "/bin" ];

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };

              script = ''
                echo "systemctl default" >> /root/.profile
              '';
            };
          };
        };
      };
    };
  };

}
