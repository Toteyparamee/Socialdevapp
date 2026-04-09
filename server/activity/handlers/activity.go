package handlers

import (
	"log"
	"time"

	"activity-service/config"
	"activity-service/models"

	"socialdev/shared/events"

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
	log.Printf("[CreateActivity] teacher_id=%q raw_local=%v", a.TeacherID, c.Locals("user_id"))
	if err := config.DB.Create(&a).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	events.Publish(events.TopicActivityCreated, map[string]interface{}{
		"activity_id": a.ID,
		"teacher_id":  a.TeacherID,
		"title":       a.Title,
	})
	return c.Status(201).JSON(a)
}

func MyRegistrations(c fiber.Ctx) error {
	uid, _ := c.Locals("user_id").(string)
	log.Printf("[MyRegistrations] user_id=%q", uid)

	var regs []models.Registration
	if err := config.DB.
		Where("student_id = ?", uid).
		Order("created_at desc").
		Find(&regs).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	// Build response with activity data
	type RegWithActivity struct {
		models.Registration
		Activity *models.Activity `json:"activity"`
	}

	var result []RegWithActivity
	for _, r := range regs {
		item := RegWithActivity{Registration: r}
		var a models.Activity
		if err := config.DB.First(&a, "id = ?", r.ActivityID).Error; err == nil {
			item.Activity = &a
		}
		result = append(result, item)
	}

	return c.JSON(result)
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
	events.Publish(events.TopicActivityJoined, map[string]interface{}{
		"activity_id": id,
		"student_id":  uid,
	})
	return c.Status(201).JSON(r)
}

func Unregister(c fiber.Ctx) error {
	regID, err := uuid.Parse(c.Params("regId"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	uid, _ := c.Locals("user_id").(string)

	result := config.DB.Where("id = ? AND student_id = ?", regID, uid).Delete(&models.Registration{})
	if result.Error != nil {
		return c.Status(500).JSON(fiber.Map{"error": result.Error.Error()})
	}
	if result.RowsAffected == 0 {
		return c.Status(404).JSON(fiber.Map{"error": "registration not found"})
	}
	return c.JSON(fiber.Map{"ok": true})
}

// MyActivitySubmissions — ดึง submissions ทั้งหมดของกิจกรรมที่ครูสร้าง
func MyActivitySubmissions(c fiber.Ctx) error {
	uid, _ := c.Locals("user_id").(string)
	log.Printf("[MyActivitySubmissions] teacher_id=%q", uid)

	// หากิจกรรมที่ครูสร้าง
	var activities []models.Activity
	if err := config.DB.Where("teacher_id = ?", uid).Order("start_at desc").Find(&activities).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	type SubWithReg struct {
		models.Submission
		StudentID  string `json:"student_id"`
		ActivityID string `json:"activity_id"`
	}

	type ActivityWithSubs struct {
		models.Activity
		Submissions []SubWithReg `json:"submissions"`
	}

	var result []ActivityWithSubs
	for _, a := range activities {
		item := ActivityWithSubs{Activity: a}

		// หา registrations + submissions ของกิจกรรมนี้
		var regs []models.Registration
		config.DB.Where("activity_id = ?", a.ID).Find(&regs)

		for _, r := range regs {
			var subs []models.Submission
			config.DB.Where("registration_id = ?", r.ID).Order("created_at desc").Find(&subs)
			for _, s := range subs {
				item.Submissions = append(item.Submissions, SubWithReg{
					Submission: s,
					StudentID:  r.StudentID,
					ActivityID: a.ID.String(),
				})
			}
		}
		result = append(result, item)
	}

	return c.JSON(result)
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
	events.Publish(events.TopicSubmissionReviewed, map[string]interface{}{
		"submission_id": subID,
		"status":        body.Status,
		"score":         body.Score,
		"reviewed_by":   uid,
	})
	return c.JSON(fiber.Map{"ok": true})
}
