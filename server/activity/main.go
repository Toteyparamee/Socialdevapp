package main

import (
	"log"
	"os"

	"activity-service/config"
	"activity-service/routes"

	"github.com/gofiber/fiber/v3"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system env")
	}

	config.ConnectDatabase()

	app := fiber.New(fiber.Config{AppName: "Activity Service"})

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
		port = "8084"
	}
	log.Printf("Activity service starting on :%s", port)
	log.Fatal(app.Listen(":" + port))
}
