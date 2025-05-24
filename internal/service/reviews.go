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

func (s *ReviewsService) CreateReviewForEvent(ctx context.Context, review *models.Review) (*models.ReviewResponse, error) {
	review.ReviewID = uuid.New()

	err := s.repo.CreateReviewForEvent(ctx, review)
	if err != nil {
		return nil, err
	}
	return s.repo.GetReviewByID(ctx, review.ReviewID)
}

func (s *ReviewsService) GetReviewsForEvent(ctx context.Context, eventID uuid.UUID) ([]models.ReviewResponse, error) {
	return s.repo.GetAllReviewsForEvent(ctx, eventID)
}
