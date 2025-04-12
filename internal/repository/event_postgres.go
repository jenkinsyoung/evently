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
		`INSERT INTO event (
			id, name, description, start_date, end_date, 
			creator_id, location, category_id, participants
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		event.EventID, event.EventName, event.Description, event.StartDate, event.EndDate,
		event.Creator.UserID, event.Location, event.Category, event.Participants,
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
		`SELECT id, name, description, start_date, end_date, 
				creator_id, location, category_id, participants
		 FROM event
		 WHERE id = $1`,
		eventId,
	).Scan(
		&event.EventID, &event.EventName, &event.Description, &event.StartDate, &event.EndDate,
		&event.Creator.UserID, &event.Location, &event.Category, &event.Participants,
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
		 FROM approved_participant ap
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
		`DELETE FROM event
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

	if event.EventName != "" {
		setClauses = append(setClauses, fmt.Sprintf("name = $%d", argIndex))
		args = append(args, event.EventName)
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
		setClauses = append(setClauses, fmt.Sprintf("participants = $%d", argIndex))
		args = append(args, event.Participants)
		argIndex++
	}

	if len(setClauses) == 0 {
		return nil
	}

	query := fmt.Sprintf(
		`UPDATE event
		 SET %s
		 WHERE id = $%d`,
		strings.Join(setClauses, ", "),
		argIndex,
	)

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
		`SELECT id, name, description, start_date, end_date, creator_id, location, category_id, participants
		 FROM event
		 ORDER BY id
		 LIMIT $1
		 OFFSET $2`,
		pageSize,
		page*pageSize,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var event models.Event
		if err = rows.Scan(
			&event.EventID, &event.EventName, &event.Description, &event.StartDate, &event.EndDate,
			&event.Creator.UserID, &event.Location, &event.Category.CategoryID, &event.Participants,
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
