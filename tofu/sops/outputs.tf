resource "local_file" "sops_yaml" {
  filename = "${path.module}/../../.sops.yaml"
  file_permission = "0644"
  content  = templatefile("${path.module}/templates/sops.yaml.tftpl", {
    pgp_key          = var.pgp_key
    buildbot_age_key = var.buildbot_age_key
    hosts            = var.hosts
    guests           = var.guests
    rules            = local.all_rules
  })
}
