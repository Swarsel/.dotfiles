{ inputs, ... }:
{
  flake.modules = {
    homeManager.pii-agent =
      {
        config,
        lib,
        options,
        nixosConfig ? null,
        ...
      }:
      {
        imports = [ inputs.piix.homeModules.default ];
        swarselsystems.enabledHomeModules = [ "pii-agent" ];
        services.pii-agent = {
          enable = true;
          sshKey = lib.mkIf (nixosConfig == null && options ? sops) (
            lib.mkDefault (lib.head config.sops.age.sshKeyPaths)
          );
        };
      };
    nixos.pii-agent =
      { config, lib, ... }:
      {
        imports = [ inputs.piix.nixosModules.default ];
        services.pii-agent = {
          enable = true;
          sshKey = lib.mkDefault (lib.head config.sops.age.sshKeyPaths);
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          config.services.pii-agent.linkDir
        ];
      };
  };
}
