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

func (r *ReviewsPostgres) CreateReviewForEvent(ctx context.Context, review *models.Review) (uuid.UUID, error) {
	var reviewID uuid.UUID

	query := `
			INSERT INTO reviews (user_id, event_id, description, score)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`
	row := r.db.QueryRow(
		ctx,
		query,
		review.User.UserID,
		review.Event.EventID,
		review.Description,
		review.Score,
	)

	err := row.Scan(&reviewID)

	return reviewID, err
}

func (r *ReviewsPostgres) GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*models.ReviewResponse, error) {
	var review models.ReviewResponse

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
		&review.CreatedAt,
		&review.User.UserID,
		&review.User.Email,
		&review.User.Nickname,
		&review.User.ProfilePicture,
	)

	return &review, err
}

func (r *ReviewsPostgres) GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.ReviewResponse, error) {
	var reviews []models.ReviewResponse

	query := `SELECT r.id AS review_id,
					r.description,
					r.score,
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
		var review models.ReviewResponse

		err = rows.Scan(
			&review.ReviewID,
			&review.Description,
			&review.Score,
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
