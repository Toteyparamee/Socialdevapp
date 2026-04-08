package models

import (
	"time"

	"github.com/google/uuid"
)

type Activity struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	TeacherID   string    `gorm:"index;not null" json:"teacher_id"`
	Title       string    `gorm:"not null" json:"title"`
	Description string    `json:"description"`
	Location    string    `json:"location"`
	StartAt     time.Time `json:"start_at"`
	EndAt       time.Time `json:"end_at"`
	MaxSlots    int       `json:"max_slots"`
	ImageIDs    []string  `gorm:"type:text[]" json:"image_ids"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Registration struct {
	ID         uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	ActivityID uuid.UUID `gorm:"type:uuid;index;not null" json:"activity_id"`
	StudentID  string    `gorm:"index;not null" json:"student_id"`
	Status     string    `gorm:"default:'registered'" json:"status"` // registered/submitted/passed/failed
	CreatedAt  time.Time `json:"created_at"`
}

type Submission struct {
	ID             uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	RegistrationID uuid.UUID `gorm:"type:uuid;index;not null" json:"registration_id"`
	Content        string    `json:"content"`
	ImageIDs       []string  `gorm:"type:text[]" json:"image_ids"`
	Score          *int      `json:"score"`
	Feedback       string    `json:"feedback"`
	Status         string    `gorm:"default:'pending'" json:"status"` // pending/passed/failed
	ReviewedBy     string    `json:"reviewed_by"`
	CreatedAt      time.Time `json:"created_at"`
	ReviewedAt     *time.Time `json:"reviewed_at"`
}
