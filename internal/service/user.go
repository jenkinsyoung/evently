package service

import (
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
)

type UserService struct {
	repo repository.User
}

func NewUserService(repo repository.User) *UserService {
	return &UserService{repo: repo}
}

func (s *UserService) GetEventsForUser(userId uuid.UUID, isCreator bool) ([]models.Event, error) {
	return s.repo.GetEventsForUser(userId, isCreator)
}

func (s *UserService) GetUserById(userId uuid.UUID) (*models.User, error) {
	return s.repo.GetUserById(userId)
}

func (s *UserService) UpdateUser(user *models.User) error {
	return s.repo.UpdateUser(user)
}
