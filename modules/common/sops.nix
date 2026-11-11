{
  inputs,
  config,
  lib,
  ...
}:
{
  flake-file.inputs = {
    sops = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };

    sops-rekey = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        sops-nix.follows = "sops";
      };
      url = "github:Swarsel/sops-rekey";
    };
  };

  flake.modules = {
    generic.sops-rekey =
      {
        self,
        inputs,
        config,
        lib,
        ...
      }:
      {
        imports = [ inputs.sops-rekey.nixosModules.default ];
        sops = {
          defaultSopsFile = self + /secrets/root.yaml;
          rekey = {
            generators.laravel-key =
              { pkgs, ... }:
              ''
                printf 'base64:%s' "$(${pkgs.openssl}/bin/openssl rand -base64 32)"
              '';
            hostPubkey =
              let
                pubFile = self + "/files/public/age/hosts/${config.node.name}.pub";
              in
              lib.mkIf (builtins.pathExists pubFile) pubFile;
            keyPrefix = "hosts/${config.node.name}/";
            rekeyAllSecrets = true;
            storageDir = self + "/secrets/rekeyed";
          };
        };
      };
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
        imports = [
          inputs.sops.homeManagerModules.sops
          self.modules.generic.sops-rekey
        ];
        swarselsystems.enabledHomeModules = [ "sops" ];
        sops = lib.mkIf (nixosConfig == null) {
          age.sshKeyPaths = [
            "${lib.optionalString config.swarselsystems.isImpermanence "/persist"}${config.swarselsystems.homeDir}/.ssh/sops"
          ];
          secrets = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsSecrets;
          templates = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsTemplates;
        };
      };
    nixos.sops =
      {
        self,
        inputs,
        config,
        lib,
        ...
      }:
      {
        imports = [
          inputs.sops.nixosModules.sops
          self.modules.generic.sops-rekey
        ];

        sops.age.sshKeyPaths = [
          "${lib.optionalString config.swarselsystems.isImpermanence "/persist"}/etc/ssh/ssh_host_ed25519_key"
        ];
      };
  };

  imports = [ inputs.sops-rekey.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      checks.sops-rekey =
        pkgs.runCommand "sops-rekey-check" { nativeBuildInputs = [ config.packages.sops-rekey ]; }
          ''
            cd ${inputs.self}
            sops-rekey check
            touch $out
          '';
    };

  sops-rekey = {
    masterRecipients.pgp = [ "4BE7925262289B476DBBC17B76FD3810215AE097" ];
    nodes =
      config.flake.nixosConfigurations
      // config.flake.guestConfigurations
      // lib.mapAttrs (
        _: home: home.extendModules { modules = [ { assertions = lib.mkForce [ ]; } ]; }
      ) config.flake.homeConfigurations;
  };
}
