{ ... }:
{
  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    extraOptions = [
      "-l"
      "--group-directories-first"
    ];
  };
}
