package repository

import (
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
	specifications "github.com/jenkinsyoung/evently/internal/specification/event"
)

type Repository struct {
	Reviews
	Event
	User
	Category
}

type Reviews interface {
	CreateReviewForEvent(ctx context.Context, review *models.Review) (uuid.UUID, error)

	GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*models.ReviewResponse, error)

	GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.ReviewResponse, error)
}

type Event interface {
	CreateEvent(ctx context.Context, event *models.Event) (uuid.UUID, error)

	GetEventByID(ctx context.Context, eventID uuid.UUID) (*models.Event, error)
	GetEventParticipants(ctx context.Context, eventID uuid.UUID) ([]models.User, error)
	GetEventCreator(ctx context.Context, eventID uuid.UUID) (uuid.UUID, error)

	DeleteEventByID(ctx context.Context, eventID uuid.UUID) error

	UpdateEvent(ctx context.Context, event *models.Event) error
	GetAllEvents(ctx context.Context, pg *specifications.Paging, isModerator bool) ([]models.Event, error)

	AttendToEvent(ctx context.Context, eventID, userID uuid.UUID) error
	CancelAttendance(ctx context.Context, eventID, userID uuid.UUID) error

	CheckEvent(ctx context.Context, eventID uuid.UUID, status string) error
}

type User interface {
	GetCreatedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error)
	GetAttendedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error)

	GetUserByID(ctx context.Context, userID uuid.UUID) (*models.User, error)
	GetUserByEmail(ctx context.Context, email string) (*models.User, error)

	CreateUser(ctx context.Context, user *models.User) (uuid.UUID, error)

	UpdateUser(ctx context.Context, user *models.User) error

	DeleteUser(ctx context.Context, userID uuid.UUID) error
}

type Category interface {
	GetCategories(ctx context.Context) ([]models.Category, error)
	GetCategoryByID(ctx context.Context, categoryID uuid.UUID) (*models.Category, error)

	CreateCategory(ctx context.Context, category *models.Category) (*models.Category, error)

	UpdateCategory(ctx context.Context, category *models.Category) (*models.Category, error)

	DeleteCategory(ctx context.Context, categoryID uuid.UUID) error
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{
		Reviews:  NewReviewsPostgres(db),
		Event:    NewEventPostgres(db),
		User:     NewUserPostgres(db),
		Category: NewCategoryPostgres(db),
	}
}
