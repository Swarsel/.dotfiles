{
  flake-file.inputs.sops = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };

  flake.modules = {
    homeManager.sops =
      {
        self,
        inputs,
        config,
        lib,
        nixosConfig ? null,
        ...
      }:
      {
        imports = [ inputs.sops.homeManagerModules.sops ];
        swarselsystems.enabledHomeModules = [ "sops" ];
        sops = lib.mkIf (nixosConfig == null) {
          age.sshKeyPaths = [
            "${
              if config.swarselsystems.isImpermanence then "/persist" else ""
            }${config.swarselsystems.homeDir}/.ssh/sops"
          ];
          defaultSopsFile = self + "/secrets/repo/common.yaml";
          secrets = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsSecrets;
          templates = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsTemplates;
          validateSopsFiles = false;
        };
      };
    nixos.sops =
      {
        self,
        inputs,
        config,
        ...
      }:
      {
        imports = [ inputs.sops.nixosModules.sops ];

        sops = {
          age.sshKeyPaths = [
            "${if config.swarselsystems.isImpermanence then "/persist" else ""}/etc/ssh/ssh_host_ed25519_key"
          ];
          defaultSopsFile = self + "/secrets/repo/common.yaml";
          validateSopsFiles = false;
        };
      };
  };
}
