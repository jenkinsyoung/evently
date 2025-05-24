package service

import (
	"context"
	"errors"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
	"github.com/jenkinsyoung/evently/internal/utils"
)

type AuthService struct {
	repo         repository.User
	tokenManager TokenManager
}

func NewAuthService(repo repository.User, tokenManager *TokenManagerService) *AuthService {
	return &AuthService{repo: repo, tokenManager: tokenManager}
}

func (s *AuthService) Register(ctx context.Context, user *models.User) (string, string, error) {
	_, err := s.repo.GetUserByEmail(ctx, user.Email)
	if err != nil {
		return "", "", errors.New("user already exists")
	}

	user.UserID = uuid.New()
	user.Password = utils.GeneratePasswordHash(user.Password)

	err = s.repo.CreateUser(ctx, user)
	if err != nil {
		return "", "", err
	}

	payload := Payload{
		UserID: user.UserID,
		Role:   user.Role,
	}

	accessToken, err := s.tokenManager.GenerateToken(payload, TokenTypeAccess)
	if err != nil {
		return "", "", err
	}

	refreshToken, err := s.tokenManager.GenerateToken(payload, TokenTypeRefresh)
	if err != nil {
		return "", "", err
	}
	return accessToken, refreshToken, nil
}

func (s *AuthService) Login(ctx context.Context, user *models.User) (string, string, error) {
	userInfo, err := s.repo.GetUserByEmail(ctx, user.Email)
	if err != nil {
		return "", "", err
	}

	if !utils.CheckPassword(user.Password, userInfo.Password) {
		return "", "", errors.New("wrong password")
	}

	payload := Payload{
		UserID: userInfo.UserID,
		Role:   userInfo.Role,
	}

	accessToken, err := s.tokenManager.GenerateToken(payload, TokenTypeAccess)
	if err != nil {
		return "", "", err
	}

	refreshToken, err := s.tokenManager.GenerateToken(payload, TokenTypeRefresh)
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

func (s *AuthService) RefreshTokens(ctx context.Context, refreshToken string) (string, string, error) {
	refreshPayload, err := s.tokenManager.ParseToken(refreshToken, TokenTypeRefresh)
	if err != nil {
		return "", "", err
	}

	payload := Payload{
		UserID: refreshPayload.UserID,
		Role:   refreshPayload.Role,
	}

	newAccessToken, err := s.tokenManager.GenerateToken(payload, TokenTypeAccess)
	if err != nil {
		return "", "", err
	}

	newRefreshToken, err := s.tokenManager.GenerateToken(payload, TokenTypeRefresh)
	if err != nil {
		return "", "", err
	}

	return newAccessToken, newRefreshToken, nil
}
