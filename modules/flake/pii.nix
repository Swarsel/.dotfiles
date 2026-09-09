{ self, lib, ... }:
{
  flake.pii =
    let
      sanitize =
        v:
        let
          t = builtins.tryEval v;
        in
        if !t.success then
          "<eval error>"
        else if builtins.isFunction t.value then
          "<function>"
        else if builtins.isAttrs t.value then
          builtins.mapAttrs (_: sanitize) t.value
        else if builtins.isList t.value then
          map sanitize t.value
        else
          t.value;

      load =
        path:
        let
          v = builtins.extraBuiltins.sopsImportEncrypted path;
        in
        sanitize (
          if builtins.isFunction v then
            v (builtins.mapAttrs (_: _: throw "arg") (builtins.functionArgs v))
          else
            v
        );

      root = ../..;

      attrPath =
        path:
        lib.splitString "/" (
          lib.removeSuffix ".nix.enc" (lib.removePrefix "${toString root}/" (toString path))
        );

      hostSecrets = lib.mapAttrs (_: cfg: sanitize cfg.config.repo.secrets) (
        self.nixosConfigurations // self.darwinConfigurations
      );
    in
    {
      evaluated = {
        globals = sanitize (builtins.head (builtins.attrValues self.globals));
        common = (builtins.head (builtins.attrValues hostSecrets)).common or null;
        hosts = lib.mapAttrs (_: lib.flip builtins.removeAttrs [ "common" ]) hostSecrets;
      };
      files = lib.foldl' lib.recursiveUpdate { } (
        map (path: lib.setAttrByPath (attrPath path) (load path)) (
          lib.filter (path: lib.hasSuffix ".nix.enc" (toString path)) (lib.filesystem.listFilesRecursive root)
        )
      );
    };
}
