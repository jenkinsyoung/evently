package service

import (
	"context"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type Service struct {
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

func NewService(repos *repository.Repository) *Service {
	return &Service{
		Reviews: NewReviewsService(repos),
		Event:   NewEventService(repos),
		User:    NewUserService(repos),
	}
}
