package routes

import (
	"chat-service/handlers"
	"chat-service/middleware"

	"github.com/gofiber/fiber/v3"
)

func Setup(app *fiber.App) {
	app.Get("/health", func(c fiber.Ctx) error { return c.JSON(fiber.Map{"status": "ok"}) })

	api := app.Group("/api/chat", middleware.JWTProtect)
	api.Get("/rooms", handlers.ListMyRooms)
	api.Post("/messages", handlers.SendMessage) // auto-create room ถ้ายังไม่มี
	api.Get("/rooms/:roomId/messages", handlers.ListMessages)
}
