{
  flake.modules.nixos.amdgpu = {
    config = {
      hardware = {
        amdgpu = {
          initrd.enable = true;
          opencl.enable = true;
          # amdvlk = {
          #   enable = true;
          #   support32Bit.enable = true;
          # };
        };
      };
    };
  };
}
