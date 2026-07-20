{
  flake.modules.nixos.microvm-guest-shares =
    {
      config,
      lib,
      microVMParent,
      nodes,
      ...
    }:
    {
      config.microvm.shares = [
        {
          mountPoint = "/persist";
          proto = "virtiofs";
          source = "${
            lib.optionalString nodes.${microVMParent}.config.swarselsystems.isImpermanence "/persist"
          }/microvms/${config.networking.hostName}";
          tag = "persist";
        }
      ];
    }

  ;
}
