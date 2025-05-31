package service

import (
	"context"
	"errors"
	"fmt"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type EventService struct {
	repo     repository.Event
	userRepo repository.User
	catRepo  repository.Category
}

func NewEventService(repo repository.Event, userRepo repository.User, catRepo repository.Category) *EventService {
	return &EventService{repo: repo, userRepo: userRepo, catRepo: catRepo}
}

func (s *EventService) AuthorizeUser(creatorID, userID uuid.UUID, isModerator bool) error {
	if isModerator {
		return nil
	}

	if creatorID != userID {
		return fmt.Errorf("user %s is not allowed to update event", userID)
	}

	return nil
}

func (s *EventService) CreateEvent(ctx context.Context, event *models.Event) (*models.Event, error) {
	//if event.StartDate == nil {
	//	return nil, errors.New("start date is required")
	//}

	if event.EndDate != nil && event.EndDate.Before(event.StartDate) {
		return nil, errors.New("end date must be after start date")
	}

	creator, err := s.userRepo.GetUserByID(ctx, event.Creator.UserID)
	if err != nil {
		return nil, err
	}
	if creator == nil {
		return nil, errors.New("creator does not exist")
	}

	category, err := s.catRepo.GetCategoryByID(ctx, event.Category.CategoryID)
	if err != nil {
		return nil, err
	}
	if category == nil {
		return nil, errors.New("category does not exist")
	}

	event.EventID = uuid.New()

	err = s.repo.CreateEvent(ctx, event)
	if err != nil {
		return nil, err
	}

	return s.repo.GetEventByID(ctx, event.EventID)
}

func (s *EventService) GetEventByID(ctx context.Context, eventID uuid.UUID) (*models.Event, error) {
	event, err := s.repo.GetEventByID(ctx, eventID)
	if err != nil {
		return nil, err
	}
	return event, nil
}

func (s *EventService) GetEventParticipants(ctx context.Context, eventID uuid.UUID) ([]models.User, error) {
	participants, err := s.repo.GetEventParticipants(ctx, eventID)
	if err != nil {
		return nil, err
	}
	return participants, nil
}

func (s *EventService) DeleteEventByID(ctx context.Context, eventID uuid.UUID, userID uuid.UUID, isModerator bool) error {
	creatorID, err := s.repo.GetEventCreator(ctx, eventID)
	if err != nil {
		return err
	}

	err = s.AuthorizeUser(creatorID, userID, isModerator)
	if err != nil {
		return err
	}

	return s.repo.DeleteEventByID(ctx, eventID)
}

func (s *EventService) UpdateEvent(ctx context.Context, event *models.Event, userID uuid.UUID, isModerator bool) (*models.Event, error) {
	creatorID, err := s.repo.GetEventCreator(ctx, event.EventID)
	if err != nil {
		return nil, err
	}

	err = s.AuthorizeUser(creatorID, userID, isModerator)
	if err != nil {
		return nil, err
	}

	err = s.repo.UpdateEvent(ctx, event)
	if err != nil {
		return nil, err
	}

	updatedEvent, err := s.repo.GetEventByID(ctx, event.EventID)
	if err != nil {
		return nil, err
	}
	return updatedEvent, nil
}

func (s *EventService) GetAllEvents(ctx context.Context, cursor *models.Cursor, pageSize int, isModerator bool) ([]models.Event, *models.Cursor, error) {
	return s.repo.GetAllEvents(ctx, cursor, pageSize, isModerator)
}

func (s *EventService) AttendToEvent(ctx context.Context, eventID, userID uuid.UUID) error {
	return s.repo.AttendToEvent(ctx, eventID, userID)
}

func (s *EventService) CancelAttendance(ctx context.Context, eventID, userID uuid.UUID) error {
	return s.repo.CancelAttendance(ctx, eventID, userID)
}
