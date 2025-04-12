package repository

import (
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
)

type Repository struct {
	Reviews
	Event
	User
}

type Reviews interface {
	CreateReviewForEvent(ctx context.Context, review *models.Review) error
	GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.Review, error)
}

type Event interface {
	CreateEvent(event *models.Event) error

	GetEventByID(eventID uuid.UUID) (*models.Event, error)
	GetEventParticipants(eventID uuid.UUID) ([]models.User, error)

	DeleteEventByID(eventID uuid.UUID) error

	UpdateEvent(event *models.Event) error
}

type User interface {
	GetEventsForUser(ctx context.Context, userID uuid.UUID, isCreator bool) ([]models.Event, error)
	GetUserByID(ctx context.Context, userID uuid.UUID) (*models.User, error)

	CreateUser(ctx context.Context, user *models.User) error

	UpdateUser(ctx context.Context, user *models.User) error

	DeleteUser(ctx context.Context, userID uuid.UUID) error
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{
		Reviews: NewReviewsPostgres(db),
		Event:   NewEventPostgres(db),
		User:    NewUserPostgres(db),
	}
}
