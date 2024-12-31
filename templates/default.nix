{ lib, ... }:
let
  templateNames = [
    "python"
    "rust"
    "go"
    "cpp"
    "default"
  ];
in
lib.swarselsystems.mkTemplates templateNames
