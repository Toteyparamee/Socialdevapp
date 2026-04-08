package routes

import (
	"activity-service/handlers"
	"activity-service/middleware"

	"github.com/gofiber/fiber/v3"
)

func Setup(app *fiber.App) {
	app.Get("/health", func(c fiber.Ctx) error { return c.JSON(fiber.Map{"status": "ok"}) })

	api := app.Group("/api/activities")
	api.Get("/", handlers.ListActivities)
	api.Get("/:id", handlers.GetActivity)

	api.Use(middleware.JWTProtect)
	api.Post("/", handlers.CreateActivity)
	api.Post("/:id/register", handlers.Register)
	api.Post("/registrations/:regId/submit", handlers.Submit)
	api.Put("/submissions/:subId/review", handlers.Review)
}
