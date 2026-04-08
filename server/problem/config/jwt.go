package config

import "os"

func JWTSecret() string {
	s := os.Getenv("JWT_SECRET")
	if s == "" {
		return "default-secret-change-me"
	}
	return s
}
