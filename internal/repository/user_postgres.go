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
				e.id, e.title, e.description, e.start_date, e.end_date, e.location, e.image_urls, e.participant_count, e.created_at,
				c.id, c.name
				FROM events e 
				JOIN categories c ON e.category_id = c.id
				WHERE creator_id = $1`
	} else {
		query = `SELECT 
				e.id, e.title, e.description, e.start_date, e.end_date, e.location, e.image_urls, e.participant_count, e.created_at,
				c.id, c.name, u.nickname, u.email, u.phone, u.profile_pic_url
				FROM events e 
    			JOIN approved_participants ap ON ap.event_id = e.id
				JOIN categories c ON e.category_id = c.id
				JOIN users u on u.id = e.creator_id
				WHERE ap.user_id = $1`
	}

	rows, err := r.db.Query(ctx, query, userID)

	defer rows.Close()
	for rows.Next() {
		var ev models.Event
		var cat models.Category
		var user models.User

		if isCreator {
			err = rows.Scan(
				&ev.EventID,
				&ev.EventTitle,
				&ev.Description,
				&ev.StartDate,
				&ev.EndDate,
				&ev.Location,
				&ev.ImageURLs,
				&ev.Participants,
				&ev.CreatedAt,
				&cat.CategoryID,
				&cat.CategoryName,
			)
		} else {
			err = rows.Scan(
				&ev.EventID,
				&ev.EventTitle,
				&ev.Description,
				&ev.StartDate,
				&ev.EndDate,
				&ev.Location,
				&ev.ImageURLs,
				&ev.Participants,
				&ev.CreatedAt,
				&cat.CategoryID,
				&cat.CategoryName,
				&user.Nickname,
				&user.Email,
				&user.Phone,
				&user.ProfilePicture,
			)
		}

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

	row := r.db.QueryRow(ctx, "SELECT id, email, nickname, phone, profile_pic_url, role FROM users WHERE id = $1", userID)
	err := row.Scan(&user.UserID, &user.Email, &user.Nickname, &user.Phone, &user.ProfilePicture, &user.Role)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserPostgres) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User

	row := r.db.QueryRow(ctx, "SELECT * FROM users WHERE email = $1", email)
	err := row.Scan(&user.UserID, &user.Email, &user.Password, &user.Nickname, &user.Phone, &user.ProfilePicture, &user.Role)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserPostgres) CreateUser(ctx context.Context, user *models.User) error {
	query := `
			INSERT INTO users (id, email, password, nickname, phone, profile_pic_url, role) 
			VALUES ($1, $2, $3, $4, $5, $6, $7)
		`

	_, err := r.db.Exec(ctx, query, user.UserID, user.Email, user.Password, user.Nickname, user.Phone, user.Role)

	return err
}

func (r *UserPostgres) UpdateUser(ctx context.Context, user *models.User) error {
	_, err := r.db.Exec(ctx,
		`UPDATE users
			SET email=$1, nickname=$2, phone=$3, profile_pic_url=$4
			WHERE id=$5`,
		user.Email,
		user.Nickname,
		user.Phone,
		user.ProfilePicture,
		user.UserID,
	)

	return err
}

func (r *UserPostgres) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	query := `
			DELETE FROM users WHERE id=$1
		`

	_, err := r.db.Exec(ctx, query, userID)

	return err
}

func (r *UserPostgres) GetCreatedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error) {
	var events []models.Event

	rows, err := r.db.Query(
		ctx,
		`SELECT 
			  e.id,
			  e.title,
			  e.description,
			  e.start_date,
			  e.end_date,
			  e.creator_id,
			  e.location,
			  e.category_id,
			  e.participant_count,
			  e.image_urls,
			  e.created_at,
			  e.status,
			  c.name AS category_name
			FROM events e
			JOIN categories c ON e.category_id = c.id
			WHERE e.creator_id = $1`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var (
			event models.Event
		)

		if err = rows.Scan(
			&event.EventID, &event.EventTitle, &event.Description, &event.StartDate, &event.EndDate,
			&event.Creator.UserID, &event.Location, &event.Category.CategoryID, &event.Participants,
			&event.ImageURLs, &event.CreatedAt, &event.Status, &event.Category.CategoryName,
		); err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return events, nil
}

func (r *UserPostgres) GetAttendedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error) {
	var events []models.Event

	rows, err := r.db.Query(
		ctx,
		`SELECT 
			  e.id,
			  e.title,
			  e.description,
			  e.start_date,
			  e.end_date,
			  e.creator_id,
			  e.location,
			  e.category_id,
			  e.participant_count,
			  e.image_urls,
			  e.created_at,
			  e.status,
			  c.name AS category_name,
			  u.email,
			  u.nickname,
			  u.phone,
			  u.profile_pic_url
			FROM approved_participants ap
			JOIN events e ON e.id = ap.event_id
			JOIN users u ON u.id = ap.user_id
			JOIN categories c ON e.category_id = c.id
			WHERE ap.user_id = $1`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var (
			event models.Event
		)

		if err = rows.Scan(
			&event.EventID, &event.EventTitle, &event.Description, &event.StartDate, &event.EndDate,
			&event.Creator.UserID, &event.Location, &event.Category.CategoryID, &event.Participants,
			&event.ImageURLs, &event.CreatedAt, &event.Status, &event.Category.CategoryName,
			&event.Creator.Email, &event.Creator.Nickname, &event.Creator.Phone, &event.Creator.ProfilePicture,
		); err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return events, nil
}
