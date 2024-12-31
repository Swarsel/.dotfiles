{ lib, ... }:
let
  templateNames = [
    "python"
    "rust"
  ];
in
lib.swarselsystems.mkTemplates templateNames
