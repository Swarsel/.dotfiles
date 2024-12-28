{ lib, ... }:
{
  mkIfElseList = p: yes: no: lib.mkMerge [
    (lib.mkIf p yes)
    (lib.mkIf (!p) no)
  ];
  mkIfElse = p: yes: no: if p then yes else no;
}
