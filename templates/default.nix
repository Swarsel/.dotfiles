{ lib, ... }:
let
  templateNames = [
    "python"
    "rust"
    "go"
    "cpp"
    "latex"
    "default"
  ];
in
lib.swarselsystems.mkTemplates templateNames
