package models

import "time"

type Image struct {
	ID        string    `gorm:"primaryKey;type:uuid" json:"id"`
	OwnerID   string    `gorm:"index;not null" json:"owner_id"`
	Key       string    `gorm:"uniqueIndex;not null" json:"key"`
	URL       string    `gorm:"not null" json:"url"`
	Folder    string    `json:"folder"`
	Mime      string    `json:"mime"`
	Size      int64     `json:"size"`
	CreatedAt time.Time `json:"created_at"`
}
