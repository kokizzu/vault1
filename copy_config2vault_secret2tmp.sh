
TERRAFORM_TOKEN=`cat docker-compose.yml | grep TERRAFORM_TOKEN | cut -d':' -f2 | xargs echo -n`
VAULT_ADDRESS="127.0.0.1:8200"

# retrieve secret for appsecret so dummy app can load the /tmp/secret
curl \
   --request POST \
   --header "X-Vault-Token: ${TERRAFORM_TOKEN}" \
      "${VAULT_ADDRESS}/v1/auth/approle/role/dummy_role/secret-id" > /tmp/debug

# if using wrapping token, it the secret id file can only be used once
#   --header "X-Vault-Wrap-TTL: 32d" \
#cat /tmp/debug | jq -r '.wrap_info.token' > /tmp/secret

cat /tmp/debug | jq -r '.data.secret_id' > /tmp/secret

# check appsecret exists
cat /tmp/debug
cat /tmp/secret

VAULT_DOCKER=`docker ps| grep vault | cut -d' ' -f 1`

echo 'put secret'
cat config.yaml | docker exec -i $VAULT_DOCKER vault -v kv put -address=http://127.0.0.1:8200 -mount=secret dummy_config_yaml/reseller1/region99 raw=-

echo 'check secret length'
docker exec -i $VAULT_DOCKER vault -v kv get -address=http://127.0.0.1:8200 -mount=secret dummy_config_yaml/reseller1/region99 | wc -l