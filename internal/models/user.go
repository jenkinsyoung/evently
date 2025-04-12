package models

import "github.com/google/uuid"

type User struct {
	UserId   uuid.UUID `json:"user_id" db:"id"`
	Email    string    `json:"email" db:"email"`
	Password string    `json:"password" db:"password"`
	Nickname string    `json:"nickname" db:"nickname"`
	Phone    string    `json:"phone" db:"phone"`
}
