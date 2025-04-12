package models

import "github.com/google/uuid"

type Review struct {
	ReviewID uuid.UUID `json:"review_id" db:"id"`
	User     User      `json:"user"`
	EventID  uuid.UUID `json:"event_id" db:"event_id"`
	Text     string    `json:"text" db:"text"`
	Score    float32   `json:"score" db:"score"`
}
