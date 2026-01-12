{ self, lib, config, inputs, microVMParent, nodes, ... }:
{
  config = {
    microvm = {
      shares = [
        {
          tag = "persist";
          source = "${lib.optionalString nodes.${microVMParent}.config.swarselsystems.isImpermanence "/persist"}/microvms/${config.networking.hostName}";
          mountPoint = "/persist";
          proto = "virtiofs";
        }
      ];
    };
  };
}
