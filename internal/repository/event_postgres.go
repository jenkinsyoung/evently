package repository

import (
	"context"
	"fmt"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
	specifications "github.com/jenkinsyoung/evently/internal/specification/event"
	"strings"
)

type EventPostgres struct {
	db *pgxpool.Pool
}

func NewEventPostgres(db *pgxpool.Pool) *EventPostgres {
	return &EventPostgres{db: db}
}

func (r *EventPostgres) CreateEvent(ctx context.Context, event *models.Event) (uuid.UUID, error) {
	var eventID uuid.UUID

	row := r.db.QueryRow(
		ctx,
		`INSERT INTO events (
			title, description, start_date, end_date, 
			creator_id, location, category_id, participant_count, image_urls, status
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
		event.EventTitle, event.Description, event.StartDate, event.EndDate,
		event.Creator.UserID, event.Location, event.Category.CategoryID, event.Participants,
		event.ImageURLs, models.EVENT_STATUS_PENDING,
	)

	err := row.Scan(&eventID)

	return eventID, err
}

func (r *EventPostgres) GetEventByID(ctx context.Context, eventID uuid.UUID) (*models.Event, error) {
	var event models.Event
	err := r.db.QueryRow(
		ctx,
		`SELECT e.id, 
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
				c.name,
				u.email, 
				u.nickname, 
				u.phone, 
				u.profile_pic_url
		 FROM events e
		 JOIN categories c on e.category_id = c.id
		 JOIN users u on u.id = e.creator_id
		 WHERE e.id = $1`,
		eventID,
	).Scan(
		&event.EventID, &event.EventTitle, &event.Description, &event.StartDate, &event.EndDate,
		&event.Creator.UserID, &event.Location, &event.Category.CategoryID, &event.Participants,
		&event.ImageURLs, &event.CreatedAt, &event.Status, &event.Category.CategoryName,
		&event.Creator.Email, &event.Creator.Nickname, &event.Creator.Phone, &event.Creator.ProfilePicture,
	)
	if err != nil {
		return nil, err
	}
	return &event, nil
}

func (r *EventPostgres) GetEventParticipants(ctx context.Context, eventID uuid.UUID) ([]models.User, error) {
	var participants []models.User
	rows, err := r.db.Query(
		ctx,
		`SELECT u.id, u.email, u.nickname, u.phone
		 FROM approved_participants ap
		 JOIN users u ON ap.user_id = u.id
		 WHERE ap.event_id = $1`,
		eventID,
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

func (r *EventPostgres) GetEventCreator(ctx context.Context, eventID uuid.UUID) (uuid.UUID, error) {
	var creatorID uuid.UUID

	err := r.db.QueryRow(
		ctx,
		`SELECT creator_id FROM events
			WHERE id=$1
			`, eventID).Scan(&creatorID)

	return creatorID, err
}

func (r *EventPostgres) DeleteEventByID(ctx context.Context, eventID uuid.UUID) error {
	_, err := r.db.Exec(
		ctx,
		`DELETE FROM events
		 WHERE id = $1`,
		eventID,
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

	args = append(args, event.EventID)

	_, err := r.db.Exec(ctx, query, args...)
	if err != nil {
		return err
	}

	return nil
}

func (r *EventPostgres) GetAllEvents(ctx context.Context, paging *specifications.Paging, isModerator bool) ([]models.EventListing, error) {
	var events []models.EventListing

	query := `
			SELECT 
				e.id, 
				e.title, 
				e.start_date, 	
				e.end_date, 
				e.creator_id, 
				e.location, 
				e.category_id, 
				(e.image_urls[1]) AS cover_image, 
				e.status		
			FROM events e
			WHERE 
            -- модератор видит всё, обычный юзер только «Одобренные»
            ($1 = TRUE OR e.status = 'Одобрено')
			`
	if paging != nil {
		query += fmt.Sprintf(" LIMIT %d OFFSET %d", paging.GetLimit(), paging.GetOffset())
	}

	args := []interface{}{isModerator}

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var ev models.EventListing

		if err = rows.Scan(
			&ev.EventID,
			&ev.EventTitle,
			&ev.StartDate,
			&ev.EndDate,
			&ev.Creator.UserID,
			&ev.Location,
			&ev.Category.CategoryID,
			&ev.CoverImage,
			&ev.Status,
		); err != nil {
			return nil, err
		}
		events = append(events, ev)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return events, nil
}

func (r *EventPostgres) AttendToEvent(ctx context.Context, eventID, userID uuid.UUID) error {
	_, err := r.db.Exec(
		ctx,
		`INSERT INTO approved_participants (event_id, user_id) 
				VALUES ($1, $2)`,
		eventID, userID,
	)

	return err
}

func (r *EventPostgres) CancelAttendance(ctx context.Context, eventID, userID uuid.UUID) error {
	_, err := r.db.Exec(
		ctx,
		`DELETE FROM approved_participants WHERE event_id=$1 AND user_id=$2`,
		eventID, userID,
	)

	return err
}

func (r *EventPostgres) CheckEvent(ctx context.Context, eventID uuid.UUID, status string) error {
	_, err := r.db.Exec(
		ctx,
		`UPDATE events SET status=$1 WHERE id=$2`,
		status, eventID,
	)
	return err
}
