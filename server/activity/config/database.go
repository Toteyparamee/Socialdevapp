package config

import (
	"fmt"
	"log"
	"os"

	"activity-service/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"), os.Getenv("DB_PORT"))
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect db: %v", err)
	}
	DB = db

	if err := db.AutoMigrate(&models.Activity{}, &models.Registration{}, &models.Submission{}); err != nil {
		log.Printf("auto-migrate warning: %v", err)
	}

	log.Println("activity db connected")
}
