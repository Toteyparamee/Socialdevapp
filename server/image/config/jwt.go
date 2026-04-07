package config

import "os"

func GetJWTSecret() string {
	s := os.Getenv("JWT_SECRET")
	if s == "" {
		s = "default-secret-change-me"
	}
	return s
}
