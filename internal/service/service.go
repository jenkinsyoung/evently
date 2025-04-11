package service

import (
	"github.com/jenkinsyoung/evently/internal/repository"
)

type Service struct {
}

func NewService(repos *repository.Repository) *Service {
	return &Service{}
}
