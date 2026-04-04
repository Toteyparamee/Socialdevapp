package handlers

import (
	"login-service/config"
	"login-service/models"

	"github.com/gofiber/fiber/v3"
)

// GetProfile - ดึงข้อมูลโปรไฟล์ user ปัจจุบัน (ต้อง login)
func GetProfile(c fiber.Ctx) error {
	userID := c.Locals("user_id")

	var user models.User
	if result := config.DB.First(&user, userID); result.Error != nil {
		return c.Status(404).JSON(fiber.Map{"error": "User not found"})
	}

	return c.JSON(fiber.Map{"user": user})
}

// UpdateProfile - อัพเดทข้อมูลโปรไฟล์
func UpdateProfile(c fiber.Ctx) error {
	userID := c.Locals("user_id")

	var req struct {
		Username string `json:"username"`
		Role     string `json:"role"`
	}
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	var user models.User
	if result := config.DB.First(&user, userID); result.Error != nil {
		return c.Status(404).JSON(fiber.Map{"error": "User not found"})
	}

	updates := map[string]interface{}{}
	if req.Username != "" {
		updates["username"] = req.Username
	}
	if req.Role != "" {
		updates["role"] = req.Role
	}

	if len(updates) > 0 {
		config.DB.Model(&user).Updates(updates)
	}

	config.DB.First(&user, userID)
	return c.JSON(fiber.Map{"user": user})
}
