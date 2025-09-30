package models

import "time"


type UserBan struct {
	ID 			    uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID      string `gorm:"primaryKey" json:"user_id"`
	PermID      int    `gorm:"primaryKey" json:"perm_id"`
	Reason      string `json:"reason"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	Permission   Permission `gorm:"foreignKey:PermID;references:PermID"`
}