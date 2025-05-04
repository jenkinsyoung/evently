package models

import (
	"github.com/google/uuid"
	"time"
)

type Event struct {
	EventID      uuid.UUID `json:"event_id" db:"id" binding:"uuid"`
	EventTitle   string    `json:"event_title" db:"title" binding:"min=3,max=255"`
	Description  string    `json:"description" db:"description" binding:""`
	StartDate    time.Time `json:"start_date" db:"start_date" binding:""`
	EndDate      time.Time `json:"end_date,omitempty" db:"end_date" binding:"gtfield=StartDate"`
	Creator      User      `json:"creator"`
	Location     string    `json:"location" db:"location"`
	Category     Category  `json:"category"`
	Participants int       `json:"participant_count" db:"participant_count" binding:"omitempty,min=0"`
	ImageURLs    []string  `json:"image_urls" db:"image_urls"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}
