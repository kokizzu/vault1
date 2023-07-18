
# Grant 'update' permission on the 'auth/approle/role/<role_name>/secret-id' path for generating a secret id
path "auth/approle/role/dummy_role/secret-id" {
  capabilities = ["update"]
}

path "secret/data/dummy_config_yaml/*" {
  capabilities = ["create","update","read","patch","delete"]
}

path "secret/dummy_config_yaml/*" { # v1
  capabilities = ["create","update","read","patch","delete"]
}

path "secret/metadata/dummy_config_yaml/*" {
  capabilities = ["list"]
}