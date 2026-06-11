package config

import (
	"fmt"
	"log"
	"os"

	"login-service/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname='%s' sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect database:", err)
	}
	DB = db

	if err := db.AutoMigrate(&models.User{}); err != nil {
		log.Printf("auto-migrate users warning: %v", err)
	}
	if err := db.AutoMigrate(&models.School{}); err != nil {
		log.Printf("auto-migrate schools warning: %v", err)
	}

	log.Println("Database connected (PostgreSQL)")
}
