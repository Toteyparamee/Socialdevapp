package handlers

import (
	"time"

	"activity-service/config"
	"activity-service/models"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

func ListActivities(c fiber.Ctx) error {
	var items []models.Activity
	if err := config.DB.Order("start_at asc").Find(&items).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(items)
}

func GetActivity(c fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	var a models.Activity
	if err := config.DB.First(&a, "id = ?", id).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "not found"})
	}
	return c.JSON(a)
}

func CreateActivity(c fiber.Ctx) error {
	var a models.Activity
	if err := c.Bind().JSON(&a); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	if uid, ok := c.Locals("user_id").(string); ok {
		a.TeacherID = uid
	}
	if err := config.DB.Create(&a).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	// TODO: publish event activity.created
	return c.Status(201).JSON(a)
}

func Register(c fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	uid, _ := c.Locals("user_id").(string)
	r := models.Registration{ActivityID: id, StudentID: uid}
	if err := config.DB.Create(&r).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	// TODO: publish event activity.joined
	return c.Status(201).JSON(r)
}

func Submit(c fiber.Ctx) error {
	regID, err := uuid.Parse(c.Params("regId"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	var s models.Submission
	if err := c.Bind().JSON(&s); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	s.RegistrationID = regID
	if err := config.DB.Create(&s).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	config.DB.Model(&models.Registration{}).Where("id = ?", regID).Update("status", "submitted")
	return c.Status(201).JSON(s)
}

func Review(c fiber.Ctx) error {
	subID, err := uuid.Parse(c.Params("subId"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	var body struct {
		Status   string `json:"status"`
		Score    int    `json:"score"`
		Feedback string `json:"feedback"`
	}
	if err := c.Bind().JSON(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	uid, _ := c.Locals("user_id").(string)
	now := time.Now()
	if err := config.DB.Model(&models.Submission{}).Where("id = ?", subID).Updates(map[string]interface{}{
		"status":      body.Status,
		"score":       body.Score,
		"feedback":    body.Feedback,
		"reviewed_by": uid,
		"reviewed_at": now,
	}).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	// TODO: publish event submission.reviewed → Notification + Chat
	return c.JSON(fiber.Map{"ok": true})
}
