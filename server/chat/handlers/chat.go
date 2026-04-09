package handlers

import (
	"chat-service/config"
	"chat-service/models"

	"socialdev/shared/events"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

// orderPair คืน (a,b) โดย a < b เพื่อให้ห้อง 1:1 unique
func orderPair(x, y string) (string, string) {
	if x < y {
		return x, y
	}
	return y, x
}

// findOrCreateRoom: ใช้สำหรับ "นักเรียนทักครู" — auto-create
func findOrCreateRoom(userA, userB string) (*models.Room, error) {
	a, b := orderPair(userA, userB)
	var room models.Room
	err := config.DB.Where("user_a = ? AND user_b = ?", a, b).First(&room).Error
	if err == nil {
		return &room, nil
	}
	room = models.Room{UserA: a, UserB: b}
	if err := config.DB.Create(&room).Error; err != nil {
		return nil, err
	}
	events.Publish(events.TopicChatRoomCreated, map[string]interface{}{
		"room_id": room.ID,
		"user_a":  room.UserA,
		"user_b":  room.UserB,
	})
	return &room, nil
}

// ListMyRooms — list ห้องทั้งหมดของ user ปัจจุบัน
func ListMyRooms(c fiber.Ctx) error {
	uid, _ := c.Locals("user_id").(string)
	var rooms []models.Room
	if err := config.DB.Where("user_a = ? OR user_b = ?", uid, uid).
		Order("updated_at desc").Find(&rooms).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(rooms)
}

// SendMessage — ถ้ายังไม่มีห้องระหว่างคู่นี้ จะ auto-create แล้วค่อยส่ง
func SendMessage(c fiber.Ctx) error {
	var body struct {
		ToUserID string `json:"to_user_id"`
		Content  string `json:"content"`
		ImageID  string `json:"image_id"`
	}
	if err := c.Bind().JSON(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	uid, _ := c.Locals("user_id").(string)

	room, err := findOrCreateRoom(uid, body.ToUserID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	msg := models.Message{
		RoomID:   room.ID,
		SenderID: uid,
		Content:  body.Content,
		ImageID:  body.ImageID,
	}
	if err := config.DB.Create(&msg).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	config.DB.Model(room).Update("updated_at", msg.CreatedAt)
	events.Publish(events.TopicChatMessageSent, map[string]interface{}{
		"room_id":   room.ID,
		"sender_id": uid,
		"to_user":   body.ToUserID,
		"content":   body.Content,
	})

	// Broadcast via WebSocket to both users in the room
	out := WsOutgoingMessage{
		Type:    "new_message",
		Message: msg,
		RoomID:  room.ID.String(),
	}
	WsHub.SendToUser(room.UserA, out)
	WsHub.SendToUser(room.UserB, out)

	return c.Status(201).JSON(fiber.Map{"room": room, "message": msg})
}

func ListMessages(c fiber.Ctx) error {
	roomID, err := uuid.Parse(c.Params("roomId"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid id"})
	}
	var msgs []models.Message
	if err := config.DB.Where("room_id = ?", roomID).
		Order("created_at asc").Find(&msgs).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(msgs)
}
