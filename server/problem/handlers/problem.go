package handlers

import (
	"problem-service/config"
	"problem-service/models"

	"socialdev/shared/events"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

func List(c fiber.Ctx) error {
	var items []models.Problem
	q := config.DB
	if cat := c.Query("category"); cat != "" {
		q = q.Where("category = ?", cat)
	}
	if status := c.Query("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if err := q.Order("created_at desc").Find(&items).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(items)
}

func Get(c fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	var p models.Problem
	if err := config.DB.First(&p, "id = ?", id).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "not found"})
	}
	return c.JSON(p)
}

func Create(c fiber.Ctx) error {
	var p models.Problem
	if err := c.Bind().JSON(&p); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	if uid, ok := c.Locals("user_id").(string); ok {
		p.OwnerID = uid
	}
	if err := config.DB.Create(&p).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	events.Publish(events.TopicProblemCreated, map[string]interface{}{
		"problem_id": p.ID,
		"owner_id":   p.OwnerID,
		"category":   p.Category,
		"title":      p.Title,
	})
	return c.Status(201).JSON(p)
}

func UpdateStatus(c fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	var body struct {
		Status string `json:"status"`
	}
	if err := c.Bind().JSON(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	if err := config.DB.Model(&models.Problem{}).Where("id = ?", id).Update("status", body.Status).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	events.Publish(events.TopicProblemStatusChanged, map[string]interface{}{
		"problem_id": id,
		"status":     body.Status,
	})
	return c.JSON(fiber.Map{"ok": true})
}

func Delete(c fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	if err := config.DB.Delete(&models.Problem{}, "id = ?", id).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"ok": true})
}
