package models

import (
	"github.com/google/uuid"
	"time"
)

type Review struct {
	ReviewID    uuid.UUID `json:"review_id" db:"id"`
	User        User      `json:"user"`
	Event       Event     `json:"event"`
	Description string    `json:"description" db:"description"`
	Score       float32   `json:"score" db:"score"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}
