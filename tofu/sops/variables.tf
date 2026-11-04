variable "pgp_key" {
  description = "PGP key fingerprint for the main user"
  type        = string
}

variable "buildbot_age_key" {
  description = "Age key for buildbot"
  type        = string
}

variable "host_configs" {
  description = "Host configurations with type, arch, and optional guest list; age keys are read from files/public/age/hosts/<name>.pub"
  type = map(object({
    type         = string
    arch         = string
    age_key_name = optional(string)
    path         = optional(string)
    guests       = optional(list(string), [])
    repo_access  = optional(bool, true)
  }))
}

variable "extra_rules" {
  description = "Additional creation rules for eval-time encrypted files outside the host directories (e.g. secrets/work)"
  type = list(object({
    path_regex = string
    age_keys   = list(string)
  }))
  default = []
}
