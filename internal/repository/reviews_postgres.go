package repository

import (
	"context"
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

func (r *ReviewsPostgres) CreateReviewForEvent(ctx context.Context, review *models.Review) error {
	query := `
			INSERT INTO reviews (id, user_id, event_id, text, score)
			VALUES ($1, $2, $3, $4, $5)
		`
	_, err := r.db.Exec(
		ctx,
		query,
		review.ReviewID,
		review.User.UserID,
		review.EventID,
		review.Text,
		review.Score,
	)

	return err
}

func (r *ReviewsPostgres) GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.Review, error) {
	var reviews []models.Review

	query := `SELECT r.id AS review_id,
					r.text,
					r.score,
					r.event_id,
					u.id AS user_id,
					u.email,
					u.nickname,
					u.phone 
				FROM review r 
         		JOIN users u ON u.user_id = r.user_id
				WHERE event_id = $1`

	rows, err := r.db.Query(ctx, query, eventID)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	for rows.Next() {
		var review models.Review
		var user models.User

		err = rows.Scan(
			&review.ReviewID,
			&review.Text,
			&review.Score,
			&review.EventID,
			&user.UserID,
			&user.Email,
			&user.Nickname,
			&user.Phone,
		)

		if err != nil {
			return nil, err
		}
	}

	return reviews, nil
}
