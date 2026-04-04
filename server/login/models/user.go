package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Username  string         `gorm:"uniqueIndex;size:100" json:"username"`
	Email     string         `gorm:"uniqueIndex;size:255" json:"email"`
	Password  string         `gorm:"size:255" json:"-"`
	Role      string         `gorm:"size:50;default:นักเรียน" json:"role"`
	Provider  string         `gorm:"size:20;default:local" json:"provider"` // local | google
	GoogleID  string         `gorm:"size:255" json:"-"`
	AvatarURL string         `gorm:"size:500" json:"avatar_url"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

func MigrateDB(db *gorm.DB) error {
	return db.AutoMigrate(&User{})
}
