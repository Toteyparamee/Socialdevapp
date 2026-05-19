package routes

import (
	"chat-service/handlers"
	"chat-service/middleware"

	"github.com/gofiber/fiber/v3"
)

func Setup(app *fiber.App) {
	app.Get("/health", func(c fiber.Ctx) error { return c.JSON(fiber.Map{"status": "ok"}) })

	// WebSocket — handled via fasthttp directly
	app.Get("/ws", func(c fiber.Ctx) error {
		handlers.HandleWebSocketFastHTTP(c.Context())
		return nil
	})

	// REST API (kept for fetching history etc.)
	api := app.Group("/api/chat", middleware.JWTProtect)
	api.Get("/rooms", handlers.ListMyRooms)
	api.Post("/messages", handlers.SendMessage)
	api.Get("/rooms/:roomId/messages", handlers.ListMessages)
}
