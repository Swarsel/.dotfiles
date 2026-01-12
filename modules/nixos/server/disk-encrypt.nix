{ self, pkgs, lib, config, globals, minimal, ... }:
let
  localIp = globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4;
  subnetMask = globals.networks.${config.swarselsystems.server.netConfigName}.subnetMask4;
  gatewayIp = globals.hosts.${config.node.name}.defaultGateway4;

  inherit (globals.general) routerServer;
  isRouter = config.node.name == routerServer;

  hostKeyPathBase = "/etc/secrets/initrd/ssh_host_ed25519_key";
  hostKeyPath =
    if config.swarselsystems.isImpermanence then
      "/persist/${hostKeyPathBase}"
    else
      "${hostKeyPathBase}";

  # this key is only used only for ssh to stage 1 in initial provisioning (in nix store)
  generatedHostKey = pkgs.runCommand "initrd-hostkey" { } ''
    ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f $out
  '';
in
{
  options.swarselmodules.server.diskEncryption = lib.mkEnableOption "enable disk encryption config";
  options.swarselsystems.networkKernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
  config = lib.mkIf (config.swarselmodules.server.diskEncryption && config.swarselsystems.isCrypted) {


    # as soon as we hit a stable system, we will use a persisted key
    # @future me: dont mkIf this to minimal, we need to create this as soon as possible
    system.activationScripts.ensureInitrdHostkey = {
      text = ''
        [[ -e ${hostKeyPath} ]] || ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f ${hostKeyPath}
      '';
      deps = [
        "users"
        "createPersistentStorageDirs"
      ];
    };

    environment.persistence."/persist" = lib.mkIf (config.swarselsystems.isImpermanence && (config.swarselprofiles.server || minimal)) {
      files = [ hostKeyPathBase ];
    };

    boot = lib.mkIf (!config.swarselsystems.isClient) {
      # kernelParams = lib.mkIf (!config.swarselsystems.isCloud && ((config.swarselsystems.localVLANs == []) || isRouter)) [
      #   "ip=${localIp}::${gatewayIp}:${subnetMask}:${config.networking.hostName}::none"
      # ];
      initrd = {
        secrets."/tmp${hostKeyPathBase}" = if minimal then (lib.mkForce generatedHostKey) else (lib.mkForce hostKeyPath); # need to mkForce this or it behaves stateful
        availableKernelModules = config.swarselsystems.networkKernelModules;
        kernelModules = config.swarselsystems.networkKernelModules; # at least summers needs this to actually find the interfaces
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
            hostKeys = [ "/tmp${hostKeyPathBase}" ]; # use a tmp file otherwise persist mount will be unhappy
          };
        };
        systemd = {
          initrdBin = with pkgs; [
            cryptsetup
          ];
        };
      };
    };
  };

}
