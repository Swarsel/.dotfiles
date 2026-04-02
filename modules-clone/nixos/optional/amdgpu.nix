_:
{
  config = {
    hardware = {
      amdgpu = {
        opencl.enable = true;
        initrd.enable = true;
        # amdvlk = {
        #   enable = true;
        #   support32Bit.enable = true;
        # };
      };
    };
  };
}
