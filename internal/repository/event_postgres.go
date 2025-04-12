package repository

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
)

type EventPostgres struct {
	db *pgxpool.Pool
}

func NewEventPostgres(db *pgxpool.Pool) *EventPostgres {
	return &EventPostgres{db: db}
}

func (r *EventPostgres) CreateEvent(event *models.Event) error {
	return nil
}

func (r *EventPostgres) GetEventByID(eventID uuid.UUID) (*models.Event, error) {
	return nil, nil
}

func (r *EventPostgres) GetEventParticipants(eventID uuid.UUID) ([]models.User, error) {
	return nil, nil
}

func (r *EventPostgres) DeleteEventByID(eventID uuid.UUID) error {
	return nil
}

func (r *EventPostgres) UpdateEvent(event *models.Event) error {
	return nil
}
