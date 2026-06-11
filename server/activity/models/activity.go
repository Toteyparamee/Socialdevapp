package models

import (
	"database/sql/driver"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// StringArray handles PostgreSQL text[] serialization correctly with GORM
type StringArray []string

func (s StringArray) Value() (driver.Value, error) {
	if len(s) == 0 {
		return "{}", nil
	}
	quoted := make([]string, len(s))
	for i, v := range s {
		quoted[i] = `"` + strings.ReplaceAll(v, `"`, `\"`) + `"`
	}
	return "{" + strings.Join(quoted, ",") + "}", nil
}

func (s *StringArray) Scan(src interface{}) error {
	if src == nil {
		*s = []string{}
		return nil
	}
	var str string
	switch v := src.(type) {
	case string:
		str = v
	case []byte:
		str = string(v)
	default:
		return fmt.Errorf("unsupported type: %T", src)
	}
	str = strings.TrimPrefix(str, "{")
	str = strings.TrimSuffix(str, "}")
	if str == "" {
		*s = []string{}
		return nil
	}
	// parse quoted or unquoted elements
	var result []string
	for _, elem := range strings.Split(str, ",") {
		elem = strings.TrimSpace(elem)
		elem = strings.Trim(elem, `"`)
		result = append(result, elem)
	}
	*s = result
	return nil
}

type Activity struct {
	ID              uuid.UUID   `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	TeacherID       string      `gorm:"index;not null" json:"teacher_id"`
	SchoolID        uint        `gorm:"index;not null;default:0" json:"school_id"`
	Title           string      `gorm:"not null" json:"title"`
	Description     string      `json:"description"`
	Location        string      `json:"location"`
	Latitude        *float64    `json:"latitude"`
	Longitude       *float64    `json:"longitude"`
	StartAt         time.Time   `json:"start_at"`
	EndAt           time.Time   `json:"end_at"`
	Supervisor      string      `json:"supervisor"`
	SupervisorPhone string      `json:"supervisor_phone"`
	MaxSlots        int         `json:"max_slots"`
	ImageIDs        StringArray `gorm:"type:text[]" json:"image_ids"`
	CreatedAt       time.Time   `json:"created_at"`
	UpdatedAt       time.Time   `json:"updated_at"`
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
	ImageIDs       StringArray `gorm:"type:text[]" json:"image_ids"`
	Score          *int        `json:"score"`
	Feedback       string    `json:"feedback"`
	Status         string    `gorm:"default:'pending'" json:"status"` // pending/passed/failed
	ReviewedBy     string    `json:"reviewed_by"`
	CreatedAt      time.Time `json:"created_at"`
	ReviewedAt     *time.Time `json:"reviewed_at"`
}
