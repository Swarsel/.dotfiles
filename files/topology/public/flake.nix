{
  description = "Flake that sets topologyPrivate to false for general purpose.";

  outputs = _: { topologyPrivate = false; };
}
