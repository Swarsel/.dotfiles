{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = "e -w";
    SWARSEL_LO_RES = config.swarselsystems.lowResolution;
    SWARSEL_HI_RES = config.swarselsystems.highResolution;
  };
}
