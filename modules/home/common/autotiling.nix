_:
let
  moduleName = "autotiling";
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "autotiling" ];
    services.${moduleName} = {
      enable = true;
      systemdTarget = "sway-session.target";
    };
  };

}
