package routes

import (
	"login-service/handlers"
	"login-service/middleware"

	"github.com/gofiber/fiber/v3"
)

func Setup(app *fiber.App) {
	// Health check
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	// ── Auth routes (public) ──
	auth := app.Group("/auth")
	auth.Post("/register", handlers.Register)
	auth.Post("/login", handlers.Login)
	auth.Post("/google", handlers.GoogleLogin)

	// ── User routes (protected) ──
	user := app.Group("/user", middleware.JWTAuth)
	user.Get("/profile", handlers.GetProfile)
	user.Put("/profile", handlers.UpdateProfile)
}
