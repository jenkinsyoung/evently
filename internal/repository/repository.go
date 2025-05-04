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
	Category
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

type Category interface {
	GetCategories(ctx context.Context) ([]models.Category, error)
	GetCategoryByID(ctx context.Context, categoryID uuid.UUID) (*models.Category, error)

	CreateCategory(ctx context.Context, category *models.Category) error

	UpdateCategory(ctx context.Context, category *models.Category) error

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
