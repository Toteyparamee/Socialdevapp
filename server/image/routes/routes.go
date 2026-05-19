package routes

import (
	"github.com/gofiber/fiber/v3"

	"github.com/socialdev/image/handlers"
	"github.com/socialdev/image/middleware"
)

func Register(app *fiber.App) {
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	// Public — serve image data directly (no auth required)
	app.Get("/api/images/:id/data", handlers.Serve)

	// Protected routes
	app.Post("/api/images", middleware.JWTAuth, handlers.Upload)
	app.Get("/api/images", middleware.JWTAuth, handlers.List)
	app.Get("/api/images/:id", middleware.JWTAuth, handlers.Get)
	app.Delete("/api/images/:id", middleware.JWTAuth, handlers.Delete)
}
