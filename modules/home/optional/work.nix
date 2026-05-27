{ self, ... }:
{
  imports = [
    "${self}/modules/home/optional/work-mail.nix"
    "${self}/modules/home/optional/work-dev.nix"
    "${self}/modules/home/optional/work-desktop.nix"
  ];

  config.swarselsystems.enabledHomeModules = [ "optional-work" ];
}
