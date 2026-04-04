package main

import (
	"log"
	"os"

	"login-service/config"
	"login-service/models"
	"login-service/routes"

	"github.com/gofiber/fiber/v3"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system env")
	}

	// Connect database
	config.ConnectDatabase()

	// Auto migrate
	if err := models.MigrateDB(config.DB); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName: "Login Service",
	})

	// CORS
	app.Use(func(c fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
		c.Set("Access-Control-Allow-Headers", "Content-Type,Authorization")
		if c.Method() == "OPTIONS" {
			return c.SendStatus(204)
		}
		return c.Next()
	})

	// Setup routes
	routes.Setup(app)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on :%s", port)
	log.Fatal(app.Listen(":" + port))
}
