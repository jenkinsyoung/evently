package service

import (
	"context"
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

func (s *ReviewsService) CreateReviewForEvent(ctx context.Context, review *models.Review) error {
	return s.repo.CreateReviewForEvent(ctx, review)
}

func (s *ReviewsService) GetAllReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.Review, error) {
	return s.repo.GetAllReviewsForEvent(ctx, eventID)
}
