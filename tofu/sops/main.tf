locals {
  repo_excluded = toset([
    for name, cfg in var.host_configs : coalesce(cfg.age_key_name, name)
    if !cfg.repo_access || !cfg.has_age_key
  ])

  all_repo_age_names = concat(
    [for name in keys(var.hosts) : name if !contains(local.repo_excluded, name)],
    [for name in keys(var.guests) : name if !contains(local.repo_excluded, name)],
    )

  repo_rules = [
    {
      path_regex = "secrets/repo/[^/]+\\.(yaml|json|env|ini)$"
      age_names  = local.all_repo_age_names
    },
    {
      path_regex = "secrets/repo/[^/]+\\.enc$"
      age_names  = concat(["buildbot"], local.all_repo_age_names)
    },
  ]

  extra_rules = [
    for rule in var.extra_rules : {
      path_regex = rule.path_regex
      age_names  = rule.age_keys
    }
  ]

  kanidm_rules = [
    for client in var.kanidm_clients : {
      path_regex = "secrets/kanidm/${client}.yaml"
      age_names  = [var.kanidm_host, client]
    }
  ]

  host_rules = flatten([
    for name, cfg in var.host_configs : [
      {
        path_regex = "hosts/${cfg.type}/${cfg.arch}/${name}/secrets/[^/]+\\.(yaml|json|env|ini)$"
        age_names  = cfg.has_age_key ? [coalesce(cfg.age_key_name, name)] : []
      },
      {
        path_regex = "hosts/${cfg.type}/${cfg.arch}/${name}/secrets/[^/]+\\.enc$"
        age_names  = cfg.has_age_key ? [coalesce(cfg.age_key_name, name), "buildbot"] : ["buildbot"]
      },
    ]
  ])

  guest_rules = flatten([
    for name, cfg in var.host_configs : [
      for guest in cfg.guests : [
        {
          path_regex = "hosts/${cfg.type}/${cfg.arch}/${name}/secrets/${guest}/[^/]+\\.(yaml|json|env|ini)$"
          age_names  = [coalesce(cfg.age_key_name, name), "${name}-${guest}"]
        },
        {
          path_regex = "hosts/${cfg.type}/${cfg.arch}/${name}/secrets/${guest}/[^/]+\\.enc$"
          age_names  = [coalesce(cfg.age_key_name, name), "${name}-${guest}", "buildbot"]
        },
      ]
    ]
  ])

  guest_parent = merge([
    for host, cfg in var.host_configs : {
      for guest in cfg.guests : "${host}-${guest}" => coalesce(cfg.age_key_name, host)
    }
  ]...)

  wireguard_rules = flatten([
    for server, net in var.wireguard_networks : [
      for client in net.clients : {
        path_regex = "secrets/wireguard/${server}-${client}.yaml$"
        age_names = distinct(compact([
          server,
          client,
          lookup(local.guest_parent, client, ""),
        ]))
      }
    ]
  ])

  all_rules = concat(
    local.repo_rules,
    local.extra_rules,
    local.kanidm_rules,
    local.host_rules,
    local.guest_rules,
    local.wireguard_rules,
    )
}
