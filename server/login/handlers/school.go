package handlers

import (
	"login-service/config"
	"login-service/models"
	"strings"

	"github.com/gofiber/fiber/v3"
)

// GetSchools - ดึงรายชื่อโรงเรียนทั้งหมด
func GetSchools(c fiber.Ctx) error {
	var schools []models.School
	if err := config.DB.Order("name asc").Find(&schools).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch schools"})
	}
	return c.JSON(schools)
}

// CreateSchool - เพิ่มโรงเรียนใหม่
func CreateSchool(c fiber.Ctx) error {
	var req struct {
		Name string `json:"name"`
	}
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ชื่อโรงเรียนไม่ถูกต้อง"})
	}

	school := models.School{Name: name}
	if err := config.DB.Create(&school).Error; err != nil {
		// unique constraint violation
		return c.Status(409).JSON(fiber.Map{"error": "โรงเรียนนี้มีอยู่แล้ว"})
	}

	return c.Status(201).JSON(school)
}
