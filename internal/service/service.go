package service

import (
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
	CreateReviewForEvent(eventId uuid.UUID, review *models.Review) error

	GetAllReviewsForEvent(eventId uuid.UUID) ([]models.Review, error)
}

type Event interface {
	CreateEvent(event *models.Event) error

	GetEventById(eventId uuid.UUID) (*models.Event, error)
	GetEventParticipants(eventId uuid.UUID) ([]models.User, error)

	DeleteEventById(eventId uuid.UUID) error

	UpdateEvent(event *models.Event) error
}

type User interface {
	GetEventsForUser(userId uuid.UUID, isCreator bool) ([]models.Event, error)
	GetUserById(userId uuid.UUID) (*models.User, error)

	UpdateUser(user *models.User) error
}

func NewService(repos *repository.Repository) *Service {
	return &Service{
		Reviews: NewReviewsService(repos),
		Event:   NewEventService(repos),
		User:    NewUserService(repos),
	}
}
