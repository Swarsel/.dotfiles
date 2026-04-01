{ self, inputs, ... }:
let
  inherit (self.outputs) lib;
in
{
  imports = [ inputs.den.flakeModule ];

  den = {
    schema.user.classes = lib.mkDefault [ "homeManager" ];
    default.homeManager.home.stateVersion = "23.05";
  };
}
