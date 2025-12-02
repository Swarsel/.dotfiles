{ self, pkgs, lib, config, globals, minimal, ... }:
let
  localIp = globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4;
  subnetMask = globals.networks.${config.swarselsystems.server.netConfigName}.subnetMask4;
  gatewayIp = globals.hosts.${config.node.name}.defaultGateway4;

  hostKeyPathBase = "/etc/secrets/initrd/ssh_host_ed25519_key";
  hostKeyPath =
    if config.swarselsystems.isImpermanence then
      "/persist/${hostKeyPathBase}"
    else
      "${hostKeyPathBase}";
in
{
  options.swarselmodules.server.diskEncryption = lib.mkEnableOption "enable disk encryption config";
  options.swarselsystems.networkKernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
  config = lib.mkIf (config.swarselmodules.server.diskEncryption && config.swarselsystems.isCrypted) {


    system.activationScripts."createPersistentStorageDirs" = lib.mkIf config.swarselsystems.isImpermanence {
      deps = [ "ensureInitrdHostkey" ];
    };
    system.activationScripts.ensureInitrdHostkey = lib.mkIf (config.swarselprofiles.server || minimal) {
      text = ''
        [[ -e ${hostKeyPath} ]] || ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f ${hostKeyPath}
      '';
      deps = [
        "etc"
      ];
    };

    environment.persistence."/persist" = lib.mkIf (config.swarselsystems.isImpermanence && (config.swarselprofiles.server || minimal)) {
      files = [ hostKeyPathBase ];
    };

    boot = lib.mkIf (!config.swarselsystems.isClient) {
      kernelParams = lib.mkIf (!config.swarselsystems.isCloud) [
        "ip=${localIp}::${gatewayIp}:${subnetMask}:${config.networking.hostName}::none"
      ];
      initrd = {
        availableKernelModules = config.swarselsystems.networkKernelModules;
        network = {
          enable = true;
          flushBeforeStage2 = true;
          ssh = {
            enable = true;
            port = 2222; # avoid hostkey changed nag
            authorizedKeys = [
              ''command="/bin/systemctl default" ${builtins.readFile "${self}/secrets/public/ssh/yubikey.pub"}''
              ''command="/bin/systemctl default" ${builtins.readFile "${self}/secrets/public/ssh/magicant.pub"}''
            ];
            hostKeys = [ hostKeyPathBase ];
          };
          # postCommands = ''
          #   echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
          # '';
        };
        systemd = {
          initrdBin = with pkgs; [
            cryptsetup
          ];
          # NOTE: the below does put the text into /root/.profile, but the command will not be run
          # services = {
          #   unlock-luks = {
          #     wantedBy = [ "initrd.target" ];
          #     after = [ "network.target" ];
          #     before = [ "systemd-cryptsetup@cryptroot.service" ];
          #     path = [ "/bin" ];

          #     serviceConfig = {
          #       Type = "oneshot";
          #       RemainAfterExit = true;
          #     };

          #     script = ''
          #       echo "systemctl default" >> /root/.profile
          #     '';
          #   };
          # };
        };
      };
    };
  };

}
