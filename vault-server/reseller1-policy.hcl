
# This section grants access for the app
path "secret/data/dummy_config_yaml/reseller1/*" {
  capabilities = ["read"]
}

path "secret/dummy_config_yaml/reseller1/*" { # v1
  capabilities = ["read"]
}