{
  description = "Example repository secrets used for building the public demo configuration.";

  outputs = _: {
    globals = ./globals.nix;
    isDemo = true;
    pii = ./pii.nix;
  };
}
