{ lib, ... }:
let
  templateNames = [
    "python"
    "rust"
    "go"
    "cpp"
  ];
in
lib.swarselsystems.mkTemplates templateNames
