{ self, ... }:
{
  imports = [ self.modules.nixOnDroid.profile-personal ];

  home-manager.config.swarselsystems.sshHosts = [
    "belchsfactory"
    "eagleland"
    "hintbooth"
    "liliputsteps"
    "liliputstepsjump"
    "moonside"
    "stoicclub"
    "summers"
    "twothreetunnel"
    "winters"
  ];

  system.stateVersion = "23.05";

  user = {
    gid = 10418;
    uid = 10418;
  };
}
