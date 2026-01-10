{
  description = "Flake that sets topologyPrivate to true for building topology.";

  outputs = _: { topologyPrivate = true; };
}
