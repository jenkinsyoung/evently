package service

import (
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type EventService struct {
	repo repository.Event
}

func NewEventService(repo repository.Event) *EventService {
	return &EventService{repo: repo}
}

func (s *EventService) CreateEvent(event *models.Event) error {
	return s.repo.CreateEvent(event)
}

func (s *EventService) GetEventByID(eventID uuid.UUID) (*models.Event, error) {
	return s.repo.GetEventByID(eventID)
}

func (s *EventService) GetEventParticipants(eventID uuid.UUID) ([]models.User, error) {
	return s.repo.GetEventParticipants(eventID)
}

func (s *EventService) DeleteEventByID(eventID uuid.UUID) error {
	return s.repo.DeleteEventByID(eventID)
}

func (s *EventService) UpdateEvent(event *models.Event) error {
	return s.repo.UpdateEvent(event)
}
