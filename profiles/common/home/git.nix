{ ... }:
{
  programs.git = {
    enable = true;
    aliases = {
      a = "add";
      c = "commit";
      cl = "clone";
      co = "checkout";
      b = "branch";
      i = "init";
      m = "merge";
      s = "status";
      r = "restore";
      p = "pull";
      pp = "push";
    };
    signing = {
      key = "0x76FD3810215AE097";
      signByDefault = true;
    };
    userEmail = "leon.schwarzaeugl@gmail.com";
    userName = "Swarsel";
    difftastic.enable = true;
    lfs.enable = true;
    includes = [
      {
        contents = {
          github = {
            user = "Swarsel";
          };
          commit = {
            template = "~/.gitmessage";
          };
        };
      }
    ];
  };
}
