package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v3"
	"github.com/joho/godotenv"

	"github.com/socialdev/image/config"
	"github.com/socialdev/image/routes"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("no .env file found, using system env")
	}

	if err := config.InitMinio(); err != nil {
		log.Fatalf("init minio: %v", err)
	}
	if err := config.ConnectDatabase(); err != nil {
		log.Fatalf("connect db: %v", err)
	}

	app := fiber.New(fiber.Config{
		BodyLimit: 30 * 1024 * 1024,
	})

	routes.Register(app)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}
	log.Printf("image service listening on :%s", port)
	log.Fatal(app.Listen(":" + port))
}
