package models

import "github.com/google/uuid"

type User struct {
	UserID   uuid.UUID `json:"user_id" db:"id"`
	Email    string    `json:"email" db:"email"`
	Password string    `json:"password" db:"password"`
	Nickname string    `json:"nickname,omitempty" db:"nickname"`
	Phone    string    `json:"phone,omitempty" db:"phone"`
}
