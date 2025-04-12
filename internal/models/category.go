package models

import "github.com/google/uuid"

type Category struct {
	CategoryID   uuid.UUID `json:"category_id" db:"id"`
	CategoryName string    `json:"category_name" db:"name"`
}
