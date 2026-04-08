package routes

import (
	"problem-service/handlers"
	"problem-service/middleware"

	"github.com/gofiber/fiber/v3"
)

func Setup(app *fiber.App) {
	app.Get("/health", func(c fiber.Ctx) error { return c.JSON(fiber.Map{"status": "ok"}) })

	api := app.Group("/api/problems")
	api.Get("/", handlers.List)
	api.Get("/:id", handlers.Get)

	api.Use(middleware.JWTProtect)
	api.Post("/", handlers.Create)
	api.Put("/:id/status", handlers.UpdateStatus)
	api.Delete("/:id", handlers.Delete)
}
