{ name, sops, homeConfig, writeShellApplication, ... }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ sops ];
  text = ''
    sops updatekeys ${homeConfig.homeDirectory}/secrets/repo/*
    sops updatekeys ${homeConfig.homeDirectory}/secrets/nginx/*
    sops updatekeys ${homeConfig.homeDirectory}/secrets/work/*
    sops updatekeys ${homeConfig.homeDirectory}/hosts/*/*/*/secrets/*/secrets.yaml
  '';
}
