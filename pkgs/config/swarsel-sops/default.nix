{ name, sops, homeConfig, writeShellApplication, ... }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ sops ];
  text = ''
    sops updatekeys ${homeConfig.swarselsystems.flakePath}/secrets/repo/*
    sops updatekeys ${homeConfig.swarselsystems.flakePath}/secrets/nginx/*
    sops updatekeys ${homeConfig.swarselsystems.flakePath}/secrets/work/*
    sops updatekeys ${homeConfig.swarselsystems.flakePath}/hosts/*/*/*/secrets/*/secrets.yaml
  '';
}
