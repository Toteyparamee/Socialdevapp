package middleware

import (
	"fmt"
	"strings"

	"activity-service/config"

	"github.com/gofiber/fiber/v3"
	"github.com/golang-jwt/jwt/v5"
)

func JWTProtect(c fiber.Ctx) error {
	auth := c.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		return c.Status(401).JSON(fiber.Map{"error": "missing token"})
	}
	tokenStr := strings.TrimPrefix(auth, "Bearer ")
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		return []byte(config.JWTSecret()), nil
	})
	if err != nil || !token.Valid {
		return c.Status(401).JSON(fiber.Map{"error": "invalid token"})
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return c.Status(401).JSON(fiber.Map{"error": "invalid claims"})
	}
	if uid, ok := claims["user_id"]; ok {
		switch v := uid.(type) {
		case string:
			c.Locals("user_id", v)
		case float64:
			c.Locals("user_id", fmt.Sprintf("%.0f", v))
		}
	}
	if role, ok := claims["role"]; ok {
		c.Locals("role", role)
	}
	return c.Next()
}
