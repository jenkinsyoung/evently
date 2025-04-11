package repository

import (
	"github.com/jenkinsyoung/evently/internal/db/postgres"
)

type Repository struct {
}

func NewRepository(db *postgres.DB) *Repository {
	return &Repository{}
}
