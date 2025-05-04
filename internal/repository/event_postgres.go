package repository

import (
	"context"
	"errors"
	"fmt"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
	"strings"
)

type EventPostgres struct {
	db *pgxpool.Pool
}

func NewEventPostgres(db *pgxpool.Pool) *EventPostgres {
	return &EventPostgres{db: db}
}

func (r *EventPostgres) CreateEvent(ctx context.Context, event *models.Event) error {
	_, err := r.db.Exec(
		ctx,
		`INSERT INTO events (
			id, title, description, start_date, end_date, 
			creator_id, location, category_id, participant_count, image_urls
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		event.EventID, event.EventTitle, event.Description, event.StartDate, event.EndDate,
		event.Creator.UserID, event.Location, event.Category.CategoryID, event.Participants,
		event.ImageURLs,
	)
	if err != nil {
		return err
	}
	return nil
}

func (r *EventPostgres) GetEventById(ctx context.Context, eventId uuid.UUID) (*models.Event, error) {
	var event models.Event
	err := r.db.QueryRow(
		ctx,
		`SELECT id, title, description, start_date, end_date, 
				creator_id, location, category_id, participant_count,
				image_urls, created_at
		 FROM events
		 WHERE id = $1`,
		eventId,
	).Scan(
		&event.EventID, &event.EventTitle, &event.Description, &event.StartDate, &event.EndDate,
		&event.Creator.UserID, &event.Location, &event.Category.CategoryID, &event.Participants,
		&event.ImageURLs, &event.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, pgx.ErrNoRows
		}
		return nil, err
	}
	return &event, nil
}

func (r *EventPostgres) GetEventParticipants(ctx context.Context, eventId uuid.UUID) ([]models.User, error) {
	var participants []models.User
	rows, err := r.db.Query(
		ctx,
		`SELECT u.id, u.email, u.nickname, u.phone
		 FROM approved_participants ap
		 JOIN users u ON ap.user_id = u.id
		 WHERE ap.event_id = $1`,
		eventId,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var user models.User
		if err = rows.Scan(&user.UserID, &user.Email, &user.Nickname, &user.Phone); err != nil {
			return nil, err
		}
		participants = append(participants, user)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return participants, nil
}

func (r *EventPostgres) DeleteEventById(ctx context.Context, eventId uuid.UUID) error {
	_, err := r.db.Exec(
		ctx,
		`DELETE FROM events
		 WHERE id = $1`,
		eventId,
	)
	if err != nil {
		return err
	}
	return nil
}

func (r *EventPostgres) UpdateEvent(ctx context.Context, event *models.Event) error {
	var setClauses []string
	var args []interface{}
	argIndex := 1

	if event.EventTitle != "" {
		setClauses = append(setClauses, fmt.Sprintf("title = $%d", argIndex))
		args = append(args, event.EventTitle)
		argIndex++
	}

	if event.Description != "" {
		setClauses = append(setClauses, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, event.Description)
		argIndex++
	}

	if !event.StartDate.IsZero() {
		setClauses = append(setClauses, fmt.Sprintf("start_date = $%d", argIndex))
		args = append(args, event.StartDate)
		argIndex++
	}

	if !event.EndDate.IsZero() {
		setClauses = append(setClauses, fmt.Sprintf("end_date = $%d", argIndex))
		args = append(args, event.EndDate)
		argIndex++
	}

	if event.Creator.UserID != uuid.Nil {
		setClauses = append(setClauses, fmt.Sprintf("creator_id = $%d", argIndex))
		args = append(args, event.Creator.UserID)
		argIndex++
	}

	if event.Location != "" {
		setClauses = append(setClauses, fmt.Sprintf("location = $%d", argIndex))
		args = append(args, event.Location)
		argIndex++
	}

	if event.Category.CategoryID != uuid.Nil {
		setClauses = append(setClauses, fmt.Sprintf("category_id = $%d", argIndex))
		args = append(args, event.Category.CategoryID)
		argIndex++
	}

	if event.Participants != 0 {
		setClauses = append(setClauses, fmt.Sprintf("participant_count = $%d", argIndex))
		args = append(args, event.Participants)
		argIndex++
	}

	if event.ImageURLs != nil {
		setClauses = append(setClauses, fmt.Sprintf("image_urls = $%d", argIndex))
		args = append(args, event.ImageURLs)
		argIndex++
	}

	if len(setClauses) == 0 {
		return nil
	}

	query := "UPDATE events SET " + strings.Join(setClauses, ", ") + fmt.Sprintf(" WHERE id = $%d", argIndex)

	//query := fmt.Sprintf(
	//	`UPDATE events SET %s WHERE id = $%d`,
	//	strings.Join(setClauses, ", "),
	//	argIndex,
	//)

	args = append(args, event.EventID)

	_, err := r.db.Exec(ctx, query, args...)
	if err != nil {
		return err
	}

	return nil
}

func (r *EventPostgres) GetAllEvents(ctx context.Context, page, pageSize int) ([]models.Event, error) {
	var events []models.Event
	rows, err := r.db.Query(
		ctx,
		`SELECT id, title, description, start_date, end_date, creator_id, location, category_id, participant_count, image_urls, created_at
		 FROM events
		 ORDER BY id
		 LIMIT $1
		 OFFSET $2`,
		pageSize,
		(page-1)*pageSize,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var event models.Event
		if err = rows.Scan(
			&event.EventID, &event.EventTitle, &event.Description, &event.StartDate, &event.EndDate,
			&event.Creator.UserID, &event.Location, &event.Category.CategoryID, &event.Participants, &event.ImageURLs, &event.CreatedAt,
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
