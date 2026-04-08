package models

import (
	"time"

	"github.com/google/uuid"
)

type Problem struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	OwnerID     string    `gorm:"index;not null" json:"owner_id"`
	Title       string    `gorm:"not null" json:"title"`
	Description string    `json:"description"`
	Category    string    `gorm:"not null" json:"category"` // flood/trash/traffic/infrastructure/other
	Status      string    `gorm:"default:'pending'" json:"status"` // pending/in_progress/resolved
	Source      string    `gorm:"default:'user'" json:"source"`
	Lat         float64   `json:"lat"`
	Lng         float64   `json:"lng"`
	Address     string    `json:"address"`
	ImageIDs    []string  `gorm:"type:text[]" json:"image_ids"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
