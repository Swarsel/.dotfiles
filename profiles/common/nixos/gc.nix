_:
{
  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    dates = "weekly";
    options = "--delete-older-than 10d";
  };
}
