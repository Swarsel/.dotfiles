{
  description = "Repository secrets for SwarselSystems. Override this input with ./files/demo to build without access to the encrypted files.";

  outputs = _: {
    pii = ./pii.nix.enc;
    globals = ./globals.nix.enc;
  };
}
