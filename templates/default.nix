{ lib, ... }:
let
  templateNames = [
    "python"
    "rust"
    "go"
  ];
in
lib.swarselsystems.mkTemplates templateNames
