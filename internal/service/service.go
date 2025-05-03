package service

import (
	"context"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
	"time"
)

type Service struct {
	Reviews
	Event
	User
	TokenManager
}

type TokenManager interface {
	GenerateJWTToken(payload Payload) (string, error)
	ParseJWTToken(accessToken string) (*Payload, error)
}

type Reviews interface {
	CreateReviewForEvent(ctx context.Context, review *models.Review) error

	GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.Review, error)
}

type Event interface {
	CreateEvent(ctx context.Context, event *models.Event) error

	GetEventById(ctx context.Context, eventId uuid.UUID) (*models.Event, error)
	GetEventParticipants(ctx context.Context, eventId uuid.UUID) ([]models.User, error)

	DeleteEventById(ctx context.Context, eventId uuid.UUID) error

	UpdateEvent(ctx context.Context, event *models.Event) error

	GetAllEvents(ctx context.Context, page, pageSize int) ([]models.Event, error)
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
		TokenManager: NewTokenManagerService(time.Minute * 300),
		Reviews:      NewReviewsService(repos),
		Event:        NewEventService(repos),
		User:         NewUserService(repos),
	}
}
