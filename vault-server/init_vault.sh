#!/bin/sh

set -e

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_FORMAT='json'

# Spawn a new process for the development Vault server and wait for it to come online
# ref: https://www.vaultproject.io/docs/concepts/dev-server
vault server -dev -dev-listen-address="0.0.0.0:8200" &
sleep 1s

# authenticate container's local Vault CLI
# ref: https://www.vaultproject.io/docs/commands/login
vault login -no-print "${VAULT_DEV_ROOT_TOKEN_ID}"

# add policy
# ref: https://www.vaultproject.io/docs/concepts/policies
vault policy write terraform-policy /vault/config/terraform-policy.hcl
vault policy write reseller1-policy /vault/config/reseller1-policy.hcl

# enable AppRole auth method
# ref: https://www.vaultproject.io/docs/auth/approle
vault auth enable approle

# configure AppRole
# ref: https://www.vaultproject.io/api/auth/approle#parameters
vault write auth/approle/role/dummy_role \
    token_policies=reseller1-policy \
    token_num_uses=9000 \
    secret_id_ttl="32d" \
    token_ttl="32d" \
    token_max_ttl="32d"

# overwrite our role id
vault write auth/approle/role/dummy_role/role-id role_id="${APPROLE_ROLE_ID}"

# for terraform
# ref: https://www.vaultproject.io/docs/commands/token/create
vault token create \
    -id="${TERRAFORM_TOKEN}" \
    -policy=terraform-policy \
    -ttl="32d"

# keep container alive
tail -f /dev/null & trap 'kill %1' TERM ; wait