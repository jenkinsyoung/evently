package service

import (
	"context"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type ModerationService struct {
	eventRepo repository.Event
	userRepo  repository.User
	catRepo   repository.Category
}

func NewModerationService(eventRepo repository.Event, userRepo repository.User, catRepo repository.Category) *ModerationService {
	return &ModerationService{eventRepo: eventRepo, userRepo: userRepo, catRepo: catRepo}
}

func (s *ModerationService) CheckEvent(ctx context.Context, eventID uuid.UUID, status string) (*models.Event, error) {
	err := s.eventRepo.CheckEvent(ctx, eventID, status)
	if err != nil {
		return nil, err
	}

	return s.eventRepo.GetEventByID(ctx, eventID)
}
