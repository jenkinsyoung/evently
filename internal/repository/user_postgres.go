package repository

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
)

type UserPostgres struct {
	db *pgxpool.Pool
}

func NewUserPostgres(db *pgxpool.Pool) *UserPostgres {
	return &UserPostgres{db: db}
}

func (r *UserPostgres) GetEventsForUser(userId uuid.UUID, isCreator bool) ([]models.Event, error) {
	return nil, nil
}

func (r *UserPostgres) GetUserById(userId uuid.UUID) (*models.User, error) {
	return nil, nil
}

func (r *UserPostgres) UpdateUser(user *models.User) error {
	return nil
}
