package repository

import (
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
)

type UserPostgres struct {
	db *pgxpool.Pool
}

func NewUserPostgres(db *pgxpool.Pool) *UserPostgres {
	return &UserPostgres{db: db}
}

func (r *UserPostgres) GetEventsForUser(ctx context.Context, userID uuid.UUID, isCreator bool) ([]models.Event, error) {
	var events []models.Event
	var query string

	if isCreator {
		query = `SELECT 
				e.id, e.name, e.description, e.start_date, e.end_date, e.location, e.participant_count,
				c.id, c.name
				FROM events e 
				JOIN categories c ON e.category_id = c.id
				WHERE creator_id = $1`
	} else {
		query = `SELECT 
				e.id, e.name, e.description, e.start_date, e.end_date, e.location, e.participant_count,
				c.id, c.name
				FROM events e 
    			JOIN approved_participants ap ON ap.event_id = e.id
				JOIN categories c ON e.category_id = c.id
				WHERE ap.user_id = $1`
	}

	rows, err := r.db.Query(ctx, query, userID)

	defer rows.Close()
	for rows.Next() {
		var ev models.Event
		var cat models.Category

		err = rows.Scan(
			&ev.EventID,
			&ev.EventTitle,
			&ev.Description,
			&ev.StartDate,
			&ev.EndDate,
			&ev.Location,
			&ev.Participants,
			&cat.CategoryID,
			&cat.CategoryName,
		)
		if err != nil {
			return nil, err
		}

		ev.Category = cat
		events = append(events, ev)
	}

	return nil, nil
}

func (r *UserPostgres) GetUserByID(ctx context.Context, userID uuid.UUID) (*models.User, error) {
	var user models.User

	row := r.db.QueryRow(ctx, "SELECT * FROM users WHERE id = $1", userID)
	err := row.Scan(&user.UserID, &user.Email, &user.Password, &user.Nickname, user.Phone)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserPostgres) CreateUser(ctx context.Context, user *models.User) error {
	query := `
			INSERT INTO users (id, email, password, nickname, phone) 
			VALUES ($1, $2, $3, $4, $5)
		`

	_, err := r.db.Exec(ctx, query, user.UserID, user.Email, user.Password, user.Nickname, user.Phone)

	return err
}

func (r *UserPostgres) UpdateUser(ctx context.Context, user *models.User) error {
	_, err := r.db.Exec(ctx,
		`UPDATE users
			SET email=$1, nickname=$2, phone=$3
			WHERE id=$4`,
		user.Email,
		user.Nickname,
		user.Phone,
		user.UserID)

	return err
}

func (r *UserPostgres) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	query := `
			DELETE FROM users WHERE id=$1
		`

	_, err := r.db.Exec(ctx, query, userID)

	return err
}
