{
  args = {
    first = [
      "self"
      "name"
      "homeConfig"
      "inputs"
      "config"
      "lib"
      "pkgs"
      "options"
    ];
    last = [
      "modulesPath"
      "<defaulted>"
      "..."
    ];
  };

  attrs = {
    first = [
      "flake-file"
      "flake"
      "imports"
      "options"
      "config"
      "swarselsystems"
      "topology"
      "globals"
      "sops"
      "users"
      "services"
      "programs"
      "enable"
      "package"
    ];
    flatten = true;
    last = [
      "systemd"
      "nodes"
      "meta"
    ];
    merge = true;
  };

  inherits = {
    first = [
      "self"
      "name"
      "homeConfig"
      "inputs"
      "config"
      "lib"
      "pkgs"
      "options"
      "modulesPath"
    ];
    sort = true;
  };

  overrides = [
    {
      attrs.first = [ ];
      path = "inputs";
    }
    {
      attrs.blank-lines = 1;
      path = "flake-file.inputs";
    }
    {
      attrs.blank-lines = 1;
      path = "flake.overlays";
    }
  ];

  top-level-blank-lines = 1;
}
