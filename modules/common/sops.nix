{
  flake-file.inputs.sops.url = "github:Mic92/sops-nix";

  flake.modules = {
    nixos.sops = { self, inputs, config, ... }:
      {
        imports = [ inputs.sops.nixosModules.sops ];

        sops = {
          age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}/etc/ssh/ssh_host_ed25519_key" ];
          defaultSopsFile = self + "/secrets/repo/common.yaml";
          validateSopsFiles = false;
        };
      };

    homeManager.sops = { self, inputs, lib, config, nixosConfig ? null, ... }:
      {
        imports = [ inputs.sops.homeManagerModules.sops ];

        swarselsystems.enabledHomeModules = [ "sops" ];

        sops = lib.mkIf (nixosConfig == null) {
          age.sshKeyPaths = [ "${if config.swarselsystems.isImpermanence then "/persist" else ""}${config.swarselsystems.homeDir}/.ssh/sops" ];
          defaultSopsFile = self + "/secrets/repo/common.yaml";
          validateSopsFiles = false;

          secrets = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsSecrets;
          templates = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsTemplates;
        };
      };
  };
}
