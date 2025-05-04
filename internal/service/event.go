package service

import (
	"context"
	"errors"
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

func (s *EventService) CreateEvent(ctx context.Context, event *models.Event) error {
	creator, err := s.userRepo.GetUserByID(ctx, event.Creator.UserID)
	if err != nil {
		return err
	}
	if creator == nil {
		return errors.New("creator does not exist")
	}

	category, err := s.catRepo.GetCategoryByID(ctx, event.Category.CategoryID)
	if err != nil {
		return err
	}
	if category == nil {
		return errors.New("category does not exist")
	}

	event.EventID = uuid.New()

	return s.repo.CreateEvent(ctx, event)
}

func (s *EventService) GetEventById(ctx context.Context, eventId uuid.UUID) (*models.Event, error) {
	event, err := s.repo.GetEventById(ctx, eventId)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, errors.New("event not found")
	}
	return event, nil
}

func (s *EventService) GetEventParticipants(ctx context.Context, eventId uuid.UUID) ([]models.User, error) {
	event, err := s.repo.GetEventById(ctx, eventId)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, errors.New("event not found")
	}

	participants, err := s.repo.GetEventParticipants(ctx, eventId)
	if err != nil {
		return nil, err
	}
	return participants, nil
}

func (s *EventService) DeleteEventById(ctx context.Context, eventId uuid.UUID) error {
	event, err := s.repo.GetEventById(ctx, eventId)
	if err != nil {
		return err
	}
	if event == nil {
		return errors.New("event not found")
	}

	return s.repo.DeleteEventById(ctx, eventId)
}

func (s *EventService) UpdateEvent(ctx context.Context, event *models.Event) error {
	return s.repo.UpdateEvent(ctx, event)
}

func (s *EventService) GetAllEvents(ctx context.Context, page, pageSize int) ([]models.Event, error) {
	return s.repo.GetAllEvents(ctx, page, pageSize)
}
