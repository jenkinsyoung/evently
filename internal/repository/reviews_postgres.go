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
			INSERT INTO reviews (id, user_id, event_id, description, score)
			VALUES ($1, $2, $3, $4, $5)
		`
	_, err := r.db.Exec(
		ctx,
		query,
		review.ReviewID,
		review.User.UserID,
		review.Event.EventID,
		review.Description,
		review.Score,
	)

	return err
}

func (r *ReviewsPostgres) GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*models.Review, error) {
	var review models.Review

	err := r.db.QueryRow(
		ctx,
		`SELECT r.id AS review_id,
					r.description,
					r.score,
					r.event_id,
					r.created_at,
					u.id AS user_id,
					u.email,
					u.nickname,
					u.profile_pic_url 
				FROM reviews r 
         		JOIN users u ON u.id = r.user_id
				WHERE r.id = $1`,
		reviewID,
	).Scan(
		&review.ReviewID,
		&review.Description,
		&review.Score,
		&review.Event.EventID,
		&review.CreatedAt,
		&review.User.UserID,
		&review.User.Email,
		&review.User.Nickname,
		&review.User.ProfilePicture,
	)

	return &review, err
}

func (r *ReviewsPostgres) GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.Review, error) {
	var reviews []models.Review

	query := `SELECT r.id AS review_id,
					r.description,
					r.score,
					r.event_id,
					r.created_at,
					u.id AS user_id,
					u.email,
					u.nickname,
					u.profile_pic_url 
				FROM reviews r 
         		JOIN users u ON u.id = r.user_id
				WHERE event_id = $1`

	rows, err := r.db.Query(ctx, query, eventID)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	for rows.Next() {
		var review models.Review

		err = rows.Scan(
			&review.ReviewID,
			&review.Description,
			&review.Score,
			&review.Event.EventID,
			&review.CreatedAt,
			&review.User.UserID,
			&review.User.Email,
			&review.User.Nickname,
			&review.User.ProfilePicture,
		)

		if err != nil {
			return nil, err
		}

		reviews = append(reviews, review)
	}

	return reviews, nil
}
