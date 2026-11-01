{ self, inputs, ... }:
let
  arch = "x86_64-linux";
  configName = "vacanthouse";
  hostDir = "${self}/hosts/utility/${configName}";

  overlays = [
    self.overlays.default
    self.overlays.stables
    self.overlays.modifications
  ];

  sandboxPkgs = import inputs.nixpkgs-sandbox {
    inherit overlays;
    config.allowUnfree = true;
    system = arch;
  };

  inherit (sandboxPkgs) lib;

  mkSpecialArgs = nodes: {
    inherit
      self
      inputs
      lib
      arch
      configName
      nodes
      ;
    inherit (self) outputs;
    inherit (self.outputs) homeLib;
    inherit (self.outputs.swarselsystemsLib) root;
    globals =
      (lib.evalModules {
        modules = [
          self.modules.generic.globals
          "${hostDir}/secrets/globals.nix"
          { globals = lib.mkMerge nodes.${configName}.config._globalsDefs; }
        ];
        prefix = [ "globals" ];
        specialArgs = {
          inherit inputs lib nodes;
          inherit (inputs.topologyPrivate) topologyPrivate;
        };
      }).config.globals;
    extraModules = [ ];
    minimal = false;
    type = "nixos";
    withHomeManager = false;
  };

  nodeModule = {
    swarselsystems.mainUser = "swarsel";
    networking.hostName = configName;
    nixpkgs = {
      inherit overlays;
      config.allowUnfree = true;
      hostPlatform = arch;
    };
    node = {
      inherit arch;
      configDir = ../../hosts/utility/vacanthouse;
      lockFromBootstrapping = true;
      name = configName;
      secretsDir = ../../hosts/utility/vacanthouse/secrets;
      type = "nixos";
    };
  };

  vacanthouse = inputs.nixpkgs-sandbox.lib.nixosSystem {
    modules = [
      hostDir
      nodeModule
    ];
    specialArgs = mkSpecialArgs { ${configName} = vacanthouse; };
  };

  testCerts =
    let
      domains = vacanthouse.config.sandbox.tlsDomains;
      baseDomain = self.outputs.swarselsystemsLib.getBaseDomain (builtins.head domains);
    in
    sandboxPkgs.runCommand "sandbox-test-certs" { nativeBuildInputs = [ sandboxPkgs.openssl ]; } ''
      mkdir -p "$out"
      openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
        -keyout "$out/ca.key" -out "$out/ca.crt" -days 3650 -subj "/CN=${configName} test CA" \
        -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" \
        -addext "nameConstraints=critical,permitted;DNS:${baseDomain}"
      openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
        -keyout "$out/wildcard.key" -out wildcard.csr -subj "/CN=*.${baseDomain}" \
        -addext "subjectAltName=${lib.concatMapStringsSep "," (d: "DNS:${d}") domains}"
      openssl x509 -req -in wildcard.csr -CA "$out/ca.crt" -CAkey "$out/ca.key" -CAcreateserial \
        -out "$out/wildcard.crt" -days 3650 -copy_extensions copy
    '';
in
{
  flake-file.inputs.nixpkgs-sandbox.url = "github:r-ryantm/nixpkgs/4800f20ae2dc52cc7422118d28d427ef412f0841";
  flake.nixosConfigurations.${configName} = vacanthouse;

  perSystem =
    { lib, system, ... }:
    lib.optionalAttrs (system == arch) {
      packages.sandbox-test = sandboxPkgs.testers.runNixOSTest (
        { nodes, ... }:
        {
          name = "sandbox-${configName}";
          node = {
            pkgsReadOnly = false;
            specialArgs = mkSpecialArgs { ${configName}.config = nodes.${configName}; };
          };
          testScript = ''
            vacanthouse.start()
            vacanthouse.wait_for_unit("multi-user.target")
            vacanthouse.wait_for_unit("kanidm.service")
            vacanthouse.wait_until_succeeds("curl -sSf https://kanidm.swarsel.internal/status", timeout=600)
            vacanthouse.succeed("curl -sSf https://kanidm.swarsel.internal/oauth2/openid/homebox/.well-known/openid-configuration")
            vacanthouse.wait_until_succeeds("curl -sSf http://127.0.0.1:3004/ready", timeout=600)
            vacanthouse.succeed("curl -sSf -o /dev/null https://oauth.swarsel.internal/oauth2/sign_in")
            vacanthouse.wait_until_succeeds("curl -sSf https://homebox.swarsel.internal/api/v1/status", timeout=600)
          '';
          nodes.${configName} = {
            imports = [
              hostDir
              nodeModule
            ];
            users.users.root.hashedPassword = lib.mkForce null;
            sandbox.tls = {
              ca = "${testCerts}/ca.crt";
              certificate = "${testCerts}/wildcard.crt";
              keyFile = "${testCerts}/wildcard.key";
            };
            virtualisation = {
              cores = 2;
              memorySize = 4096;
            };
          };
        }
      );
    };
}
