package service

import (
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type ReviewsService struct {
	repo repository.Reviews
}

func NewReviewsService(repo repository.Reviews) *ReviewsService {
	return &ReviewsService{repo: repo}
}

func (s *ReviewsService) CreateReviewForEvent(eventId uuid.UUID, review *models.Review) error {
	return s.repo.CreateReviewForEvent(eventId, review)
}

func (s *ReviewsService) GetAllReviewsForEvent(eventId uuid.UUID) ([]models.Review, error) {
	return s.repo.GetAllReviewsForEvent(eventId)
}
