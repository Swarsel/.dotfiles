locals {
  key_dir = "${path.module}/../../files/public/age"

  nodes = {
    for f in fileset("${local.key_dir}/hosts", "*.pub") :
    trimsuffix(f, ".pub") => trimspace(file("${local.key_dir}/hosts/${f}"))
  }

  users = {
    for f in fileset("${local.key_dir}/users", "*.pub") :
    trimsuffix(f, ".pub") => trimspace(file("${local.key_dir}/users/${f}"))
  }

  host_key_names = {
    for name, cfg in var.host_configs : name => coalesce(cfg.age_key_name, name)
  }

  with_key = [for name in keys(local.nodes) : name]

  repo_host_age_names = [
    for name, cfg in var.host_configs : local.host_key_names[name]
    if cfg.repo_access && contains(local.with_key, local.host_key_names[name])
  ]

  repo_rules = [
    {
      path_regex = "secrets/repo/[^/]+\\.enc$"
      age_names  = concat(["buildbot"], local.repo_host_age_names)
    },
  ]

  extra_rules = [
    for rule in var.extra_rules : {
      path_regex = rule.path_regex
      age_names  = rule.age_keys
    }
  ]

  host_paths = {
    for name, cfg in var.host_configs : name => coalesce(cfg.path, "hosts/${cfg.type}/${cfg.arch}/${name}")
  }

  host_rules = [
    for name, cfg in var.host_configs : {
      path_regex = "${local.host_paths[name]}/secrets/[^/]+\\.enc$"
      age_names  = [local.host_key_names[name], "buildbot"]
    }
  ]

  guest_rules = flatten([
    for name, cfg in var.host_configs : [
      for guest in cfg.guests : {
        path_regex = "${local.host_paths[name]}/secrets/${guest}/[^/]+\\.enc$"
        age_names  = [local.host_key_names[name], "${name}-${guest}", "buildbot"]
      }
    ]
  ])

  master_rules = [
    {
      path_regex = "\\.(yaml|json|env|ini|enc)$"
      age_names  = []
    },
  ]

  all_rules_raw = concat(
    local.repo_rules,
    local.extra_rules,
    local.host_rules,
    local.guest_rules,
    local.master_rules,
  )

  all_rules = [
    for rule in local.all_rules_raw : {
      path_regex = rule.path_regex
      age_names  = [for n in rule.age_names : n if n == "buildbot" || contains(local.with_key, n)]
    }
  ]
}
