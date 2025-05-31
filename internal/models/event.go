package models

import (
	"github.com/google/uuid"
	"time"
)

type Cursor struct {
	LastStartDate time.Time
	LastID        uuid.UUID
}

type Event struct {
	EventID      uuid.UUID  `json:"event_id" db:"id" binding:"uuid"`
	EventTitle   string     `json:"event_title,omitempty" db:"title" binding:"max=255"`
	Description  string     `json:"description,omitempty" db:"description" binding:""`
	StartDate    time.Time  `json:"start_date" db:"start_date" binding:""`
	EndDate      *time.Time `json:"end_date,omitempty" db:"end_date"`
	Creator      User       `json:"creator,omitempty"`
	Location     string     `json:"location,omitempty" db:"location"`
	Category     Category   `json:"category,omitempty"`
	Participants int        `json:"participant_count" db:"participant_count" binding:""`
	ImageURLs    []string   `json:"image_urls" db:"image_urls"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	Status       string     `json:"event_status" db:"status"`
}
