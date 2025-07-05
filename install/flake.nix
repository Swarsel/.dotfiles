{
  description = "Minimal installer flake - not to be used manually";

  inputs.swarsel.url = "./..";

  outputs = { swarsel, ... }: { nixosConfigurations = swarsel.nixosConfigurationsMinimal; };
}
