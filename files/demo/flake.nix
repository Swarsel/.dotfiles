{
  description = "Example repository secrets used for building the public demo configuration.";

  outputs = _: {
    isDemo = true;
    pii = ./pii.nix;
    globals = ./globals.nix;
  };
}
