variable "pgp_key" {
  description = "PGP key fingerprint for the main user"
  type        = string
}

variable "buildbot_age_key" {
  description = "Age key for buildbot"
  type        = string
}

variable "kanidm_host" {
  description = "Name of the host/guest running kanidm (used for kanidm secret rules)"
  type        = string
  default     = "summers-kanidm"
}

variable "hosts" {
  description = "Map of host name to age key"
  type        = map(string)
}

variable "guests" {
  description = "Map of full guest name (e.g. summers-audio) to age key"
  type        = map(string)
}

variable "host_configs" {
  description = "Host configurations with type, arch, and optional guest list"
  type = map(object({
    type         = string
    arch         = string
    age_key_name = optional(string)
    guests       = optional(list(string), [])
    repo_access  = optional(bool, true)
    has_age_key  = optional(bool, true)
  }))
}

variable "kanidm_clients" {
  description = "List of guest/host names that have kanidm secret files"
  type        = list(string)
}

variable "extra_rules" {
  description = "Additional creation rules for other paths (e.g. secrets/work, secrets/nginx)"
  type = list(object({
    path_regex = string
    age_keys   = list(string)
  }))
  default = []
}

variable "wireguard_networks" {
  description = "Wireguard networks: server name -> network name + client list"
  type = map(object({
    name    = string
    clients = list(string)
  }))
  default = {}
}
