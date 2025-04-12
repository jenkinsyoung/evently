package repository

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
)

type ReviewsPostgres struct {
	db *pgxpool.Pool
}

func NewReviewsPostgres(db *pgxpool.Pool) *ReviewsPostgres {
	return &ReviewsPostgres{db: db}
}

func (r *ReviewsPostgres) CreateReviewForEvent(eventId uuid.UUID, review *models.Review) error {
	return nil
}

func (r *ReviewsPostgres) GetAllReviewsForEvent(eventId uuid.UUID) ([]models.Review, error) {
	return nil, nil
}
