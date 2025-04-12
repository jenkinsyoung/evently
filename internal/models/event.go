package models

import (
	"github.com/google/uuid"
	"time"
)

type Event struct {
	EventId      uuid.UUID `json:"event_id" db:"id"`
	EventName    string    `json:"event_name" db:"name"`
	Description  string    `json:"description" db:"description"`
	StartDate    time.Time `json:"start_date" db:"start_date"`
	EndDate      time.Time `json:"end_date,omitempty" db:"end_date"`
	Creator      User      `json:"creator"`
	Location     string    `json:"locations" db:"location"`
	Category     Category  `json:"category"`
	Participants int       `json:"participants" db:"participants"`
}
