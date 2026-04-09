package main

import (
	"log"
	"os"

	"problem-service/config"
	"problem-service/routes"

	"socialdev/shared/events"

	"github.com/gofiber/fiber/v3"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system env")
	}

	config.ConnectDatabase()

	events.Init("problem-service")
	defer events.Close()

	app := fiber.New(fiber.Config{AppName: "Problem Service"})

	app.Use(func(c fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
		c.Set("Access-Control-Allow-Headers", "Content-Type,Authorization")
		if c.Method() == "OPTIONS" {
			return c.SendStatus(204)
		}
		return c.Next()
	})

	routes.Setup(app)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8083"
	}
	log.Printf("Problem service starting on :%s", port)
	log.Fatal(app.Listen(":" + port))
}
