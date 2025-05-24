package service

import (
	"context"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type Service struct {
	Authorization
	TokenManager

	Reviews
	Event
	User
	Category
	Moderation
}

type Authorization interface {
	Register(ctx context.Context, user *models.User) (string, string, error)
	Login(ctx context.Context, user *models.User) (string, string, error)

	RefreshTokens(ctx context.Context, refreshToken string) (string, string, error)
}

type TokenManager interface {
	GenerateToken(payload Payload, tokenType string) (string, error)
	ParseToken(tokenStr string, tokenType string) (*Payload, error)
}

type Reviews interface {
	CreateReviewForEvent(ctx context.Context, review *models.Review) (*models.Review, error)

	GetReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.Review, error)
}

type Event interface {
	AuthorizeUser(creatorID, userID uuid.UUID, isModerator bool) error

	CreateEvent(ctx context.Context, event *models.Event) (*models.Event, error)

	GetEventByID(ctx context.Context, eventId uuid.UUID) (*models.Event, error)
	GetEventParticipants(ctx context.Context, eventID uuid.UUID) ([]models.User, error)

	DeleteEventByID(ctx context.Context, eventId uuid.UUID, userID uuid.UUID, isModerator bool) error

	UpdateEvent(ctx context.Context, event *models.Event, userID uuid.UUID, isModerator bool) (*models.Event, error)

	GetAllEvents(ctx context.Context, page, pageSize int, isModerator bool) ([]models.Event, error)

	AttendToEvent(ctx context.Context, eventID, userID uuid.UUID) error
	CancelAttendance(ctx context.Context, eventID, userID uuid.UUID) error
}

type User interface {
	GetCreatedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error)
	GetAttendedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error)
	GetUserByID(ctx context.Context, userID uuid.UUID) (*models.User, error)

	CreateUser(ctx context.Context, user *models.User) (*models.User, error)

	UpdateUser(ctx context.Context, user *models.User) (*models.User, error)

	DeleteUser(ctx context.Context, userID uuid.UUID) error
}

type Category interface {
	GetCategories(ctx context.Context) ([]models.Category, error)
	GetCategoryByID(ctx context.Context, categoryID uuid.UUID) (*models.Category, error)

	CreateCategory(ctx context.Context, category *models.Category) (*models.Category, error)

	UpdateCategory(ctx context.Context, category *models.Category) (*models.Category, error)

	DeleteCategory(ctx context.Context, categoryID uuid.UUID) error
}

type Moderation interface {
	CheckEvent(ctx context.Context, eventID uuid.UUID, status string) (*models.Event, error)
}

func NewService(repos *repository.Repository) *Service {
	return &Service{
		Authorization: NewAuthService(repos.User, NewTokenManagerService()),
		TokenManager:  NewTokenManagerService(),

		Reviews:    NewReviewsService(repos.Reviews),
		Event:      NewEventService(repos.Event, repos.User, repos.Category),
		Category:   NewCategoryService(repos.Category),
		User:       NewUserService(repos.User),
		Moderation: NewModerationService(repos.Event, repos.User, repos.Category),
	}
}
