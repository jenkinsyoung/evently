package service

import (
	"errors"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"os"
	"time"
)

const (
	TokenTypeAccess  = "access"
	TokenTypeRefresh = "refresh"

	accessTTL  = 30 * time.Minute
	refreshTTL = 30 * 24 * time.Hour
)

type TokenManagerService struct {
	accessTokenTTL  time.Duration
	refreshTokenTTL time.Duration
}

type Payload struct {
	UserID uuid.UUID `json:"user_id"`
	Role   string    `json:"role"`
}

type Claims struct {
	jwt.RegisteredClaims
	Payload
}

var AccessSigningKey = os.Getenv("SECRET_KEY_ACCESS")
var RefreshSigningKey = os.Getenv("SECRET_KEY_REFRESH")

func NewTokenManagerService() *TokenManagerService {
	return &TokenManagerService{accessTokenTTL: accessTTL, refreshTokenTTL: refreshTTL}
}

func (s *TokenManagerService) CheckTokenType(tokenType string) (time.Duration, string, error) {
	switch tokenType {
	case TokenTypeAccess:
		return accessTTL, AccessSigningKey, nil
	case TokenTypeRefresh:
		return refreshTTL, RefreshSigningKey, nil
	default:
		return 0, "", errors.New("invalid token type")
	}
}

func (s *TokenManagerService) GenerateToken(payload Payload, tokenType string) (string, error) {
	ttl, signingKey, err := s.CheckTokenType(tokenType)
	if err != nil {
		return "", err
	}

	claims := &Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(ttl)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
		Payload: payload,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	signedToken, err := token.SignedString([]byte(signingKey))
	if err != nil {
		return "", err
	}
	return signedToken, nil
}

func (s *TokenManagerService) ParseToken(tokenStr string, tokenType string) (*Claims, error) {
	_, signingKey, err := s.CheckTokenType(tokenType)
	if err != nil {
		return nil, err
	}

	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}

		return []byte(signingKey), nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("token is not valid")
	}

	claims, ok := token.Claims.(*Claims)
	if !ok {
		return claims, errors.New("error in token claims")
	}
	return claims, nil
}
