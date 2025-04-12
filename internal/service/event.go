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

func (s *EventService) GetEventById(eventId uuid.UUID) (*models.Event, error) {
	return s.repo.GetEventById(eventId)
}

func (s *EventService) GetEventParticipants(eventId uuid.UUID) ([]models.User, error) {
	return s.repo.GetEventParticipants(eventId)
}

func (s *EventService) DeleteEventById(eventId uuid.UUID) error {
	return s.repo.DeleteEventById(eventId)
}

func (s *EventService) UpdateEvent(event *models.Event) error {
	return s.repo.UpdateEvent(event)
}
