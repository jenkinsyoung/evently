package service

import (
	"context"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type CategoryService struct {
	repo repository.Category
}

func NewCategoryService(repo repository.Category) *CategoryService {
	return &CategoryService{repo: repo}
}

func (s *CategoryService) GetCategories(ctx context.Context) ([]models.Category, error) {
	return s.repo.GetCategories(ctx)
}

func (s *CategoryService) GetCategoryByID(ctx context.Context, categoryID uuid.UUID) (*models.Category, error) {
	return s.repo.GetCategoryByID(ctx, categoryID)
}

func (s *CategoryService) CreateCategory(ctx context.Context, category *models.Category) (*models.Category, error) {
	return s.repo.CreateCategory(ctx, category)
}

func (s *CategoryService) UpdateCategory(ctx context.Context, category *models.Category) (*models.Category, error) {
	return s.repo.UpdateCategory(ctx, category)
}

func (s *CategoryService) DeleteCategory(ctx context.Context, categoryID uuid.UUID) error {
	return s.repo.DeleteCategory(ctx, categoryID)
}
