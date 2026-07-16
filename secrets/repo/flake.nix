{
  description = "Repository secrets for SwarselSystems. Override this input with ./hosts/utility/hotel/secrets to build without access to the encrypted files.";

  outputs = _: {
    globals = ./globals.nix.enc;
    pii = ./pii.nix.enc;
  };
}
