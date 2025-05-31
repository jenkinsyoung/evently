package service

import (
	"context"
	"errors"
	"github.com/jenkinsyoung/evently/internal/models"
	"github.com/jenkinsyoung/evently/internal/repository"
	"github.com/jenkinsyoung/evently/internal/utils"
	"time"
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
	if err == nil {
		return "", "", errors.New("user already exists")
	}

	user.Password = utils.GeneratePasswordHash(user.Password)

	userID, err := s.repo.CreateUser(ctx, user)
	if err != nil {
		return "", "", err
	}

	payload := Payload{
		UserID: userID,
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
	refreshClaims, err := s.tokenManager.ParseToken(refreshToken, TokenTypeRefresh)
	if err != nil {
		return "", "", err
	}

	payload := Payload{
		UserID: refreshClaims.UserID,
		Role:   refreshClaims.Role,
	}

	newAccessToken, err := s.tokenManager.GenerateToken(payload, TokenTypeAccess)
	if err != nil {
		return "", "", err
	}

	const refreshThreshold = 24 * time.Hour
	if refreshClaims.ExpiresAt != nil {
		timeLeft := time.Until(refreshClaims.ExpiresAt.Time)
		if timeLeft > refreshThreshold {
			return newAccessToken, refreshToken, nil
		}
	}

	newRefreshToken, err := s.tokenManager.GenerateToken(payload, TokenTypeRefresh)
	if err != nil {
		return "", "", err
	}

	return newAccessToken, newRefreshToken, nil
}
