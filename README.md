
# Vault PoC

## the scheme:

1. create vault role
2. create vault policy
3. put secret to be retrieved later by app, in this case is `config.yaml` (eg. from terraform) to `dummy_config_yaml/reseller1/region99` on vault
4. get secret-id for app-role-id (`dummy_app`), so the program that need to read `config.yaml` can retrieve it, put it on `/tmp/secret`
5. run the program, it would read secret id from `/tmp/secret`, and retrieve `config.yaml` from vault

## How to use

```
docker compose up --build 

./copy_config2vault_secret2tmp.sh
go run main.go
```