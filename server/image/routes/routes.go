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

	api := app.Group("/api/images", middleware.JWTAuth)
	api.Post("/", handlers.Upload)
	api.Get("/", handlers.List)
	api.Get("/:id", handlers.Get)
	api.Get("/:id/url", handlers.Presign)
	api.Delete("/:id", handlers.Delete)
}
