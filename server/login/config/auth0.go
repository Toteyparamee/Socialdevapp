package config

import "os"

type Auth0Config struct {
	Domain   string
	ClientID string
}

func LoadAuth0Config() Auth0Config {
	return Auth0Config{
		Domain:   os.Getenv("AUTH0_DOMAIN"),
		ClientID: os.Getenv("AUTH0_CLIENT_ID"),
	}
}
