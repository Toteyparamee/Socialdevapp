package models

import (
	"time"

	"github.com/google/uuid"
)

// Room — ห้องแชท 1:1 ระหว่าง 2 user (เช่น นักเรียน ↔ ครู)
type Room struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	UserA     string    `gorm:"index;not null" json:"user_a"` // เก็บแบบเรียง user_a < user_b เพื่อ unique 1:1
	UserB     string    `gorm:"index;not null" json:"user_b"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Message struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	RoomID    uuid.UUID `gorm:"type:uuid;index;not null" json:"room_id"`
	SenderID  string    `gorm:"index;not null" json:"sender_id"`
	Content   string    `json:"content"`
	ImageID   string    `json:"image_id"`
	ReadAt    *time.Time `json:"read_at"`
	CreatedAt time.Time `json:"created_at"`
}
