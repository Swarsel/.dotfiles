{ lib, config, outputs, inputs, ... }:
{

  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
          "cgroups"
          "pipe-operators"
        ];
        trusted-users = [ "@wheel" "${config.swarselsystems.mainUser}" ];
        connect-timeout = 5;
        bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
        bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)\[\e[1m\]λ\[\e[0m\] [0m";
        fallback = true;
        min-free = 128000000;
        max-free = 1000000000;
        flake-registry = "";
        auto-optimise-store = true;
        warn-dirty = false;
        max-jobs = 1;
        use-cgroups = lib.mkIf config.swarselsystems.isLinux true;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };


  system.stateVersion = lib.mkDefault "23.05";

}
