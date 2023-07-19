package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"time"

	vault "github.com/hashicorp/vault/api"
	"github.com/hashicorp/vault/api/auth/approle"
)

const AppRoleID = `dummy_app`

func main() {
	conf, err := TryUseVault(`http://127.0.0.1:8200`, `secret/data/dummy_config_yaml/reseller1/region99`)
	if err != nil {
		log.Println(err)
		return
	}
	log.Println(conf)
}

func TryUseVault(address, configPath string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	const secretFile = `/tmp/secret`

	config := vault.DefaultConfig() // modify for more granular configuration
	config.Address = address

	client, err := vault.NewClient(config)
	if err != nil {
		return ``, fmt.Errorf(`failed to create vault client: %w`, err)
	}

	file, err := os.Open(secretFile)
	if err != nil {
		return ``, fmt.Errorf(`failed to open secret file: %w`, err)
	}
	defer file.Close()
	secretId, err := io.ReadAll(file)
	if err != nil {
		return ``, fmt.Errorf(`failed to read secret file: %w`, err)
	}

	approleSecretID := &approle.SecretID{
		FromString: string(secretId),
	}

	appRoleAuth, err := approle.NewAppRoleAuth(
		AppRoleID,
		approleSecretID,
		//approle.WithWrappingToken(), // only required if the SecretID is response-wrapped, if X-Vault-Wrap-TTL header set on copy_config2vault_secret2tmp.sh
	)
	if err != nil {
		return ``, fmt.Errorf(`failed to create approle auth: %w`, err)
	}

	authInfo, err := client.Auth().Login(ctx, appRoleAuth)
	if err != nil {
		return ``, fmt.Errorf(`failed to login to vault: %w`, err)
	}

	if authInfo == nil {
		return ``, fmt.Errorf(`failed to login to vault: authInfo is nil`)
	}

	log.Println("connecting to vault: success!")

	secret, err := client.Logical().Read(configPath)
	if err != nil {
		return ``, fmt.Errorf(`failed to read secret from vault: %w`, err)
	}
	if secret == nil {
		return ``, fmt.Errorf(`failed to read secret from vault: secret is nil`)
	}
	if len(secret.Data) == 0 {
		return ``, fmt.Errorf(`failed to read secret from vault: secret.Data is empty`)
	}
	data := secret.Data[`data`]
	if data == nil {
		return ``, fmt.Errorf(`failed to read secret from vault: secret.Data.data is nil`)
	}
	m, ok := data.(map[string]interface{})
	if !ok {
		return ``, fmt.Errorf(`failed to read secret from vault: secret.Data.data is not a map[string]interface{}`)
	}
	raw, ok := m[`raw`]
	if !ok {
		return ``, fmt.Errorf(`failed to read secret from vault: secret.Data.data.raw is nil`)
	}
	rawStr, ok := raw.(string)
	if !ok {
		return ``, fmt.Errorf(`failed to read secret from vault: secret.Data.data.raw is not a string`)
	}

	// set viper from string
	return rawStr, nil
}
