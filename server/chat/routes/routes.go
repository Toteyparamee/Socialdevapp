package routes

import (
	"chat-service/handlers"
	"chat-service/middleware"

	"github.com/gofiber/fiber/v3"
)

func Setup(app *fiber.App) {
	app.Get("/health", func(c fiber.Ctx) error { return c.JSON(fiber.Map{"status": "ok"}) })

	// WebSocket — handled via fasthttp directly, bypass Fiber routing
	app.Use(func(c fiber.Ctx) error {
		if c.Path() == "/ws" {
			handlers.HandleWebSocketFastHTTP(c.Context())
			return nil
		}
		return c.Next()
	})

	// REST API (kept for fetching history etc.)
	api := app.Group("/api/chat", middleware.JWTProtect)
	api.Get("/rooms", handlers.ListMyRooms)
	api.Post("/messages", handlers.SendMessage)
	api.Get("/rooms/:roomId/messages", handlers.ListMessages)
}
