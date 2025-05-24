package service

import (
	"context"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
	"github.com/jenkinsyoung/evently/internal/utils"
)

type UserService struct {
	repo repository.User
}

func NewUserService(repo repository.User) *UserService {
	return &UserService{repo: repo}
}

func (s *UserService) GetCreatedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error) {
	return s.repo.GetCreatedEventsForUser(ctx, userID)
}

func (s *UserService) GetAttendedEventsForUser(ctx context.Context, userID uuid.UUID) ([]models.Event, error) {
	return s.repo.GetAttendedEventsForUser(ctx, userID)
}

func (s *UserService) GetUserByID(ctx context.Context, userID uuid.UUID) (*models.User, error) {
	return s.repo.GetUserByID(ctx, userID)
}

func (s *UserService) CreateUser(ctx context.Context, user *models.User) (*models.User, error) {
	user.UserID = uuid.New()
	user.Password = utils.GeneratePasswordHash(user.Password)

	err := s.repo.CreateUser(ctx, user)
	if err != nil {
		return nil, err
	}

	return s.repo.GetUserByID(ctx, user.UserID)
}

func (s *UserService) UpdateUser(ctx context.Context, user *models.User) (*models.User, error) {
	err := s.repo.UpdateUser(ctx, user)
	if err != nil {
		return nil, err
	}

	return s.repo.GetUserByID(ctx, user.UserID)
}

func (s *UserService) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	return s.repo.DeleteUser(ctx, userID)
}
