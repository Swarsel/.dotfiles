{
  description = "Minimal installer flake - not to be used manually";

  inputs.swarsel.url = "github:Swarsel/.dotfiles";

  outputs = { swarsel, ... }: { nixosConfigurations = swarsel.nixosConfigurationsMinimal; };
}
