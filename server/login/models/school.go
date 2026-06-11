package models

import (
	"time"

	"gorm.io/gorm"
)

type School struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Name      string         `gorm:"uniqueIndex;size:255;not null" json:"name"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

func MigrateSchoolDB(db *gorm.DB) error {
	return db.AutoMigrate(&School{})
}
