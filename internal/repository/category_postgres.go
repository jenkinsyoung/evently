package repository

import (
	"context"
	"errors"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jenkinsyoung/evently/internal/models"
)

type CategoryPostgres struct {
	db *pgxpool.Pool
}

func NewCategoryPostgres(db *pgxpool.Pool) *CategoryPostgres {
	return &CategoryPostgres{db: db}
}

func (r *CategoryPostgres) GetCategories(ctx context.Context) ([]models.Category, error) {
	var categories []models.Category
	rows, err := r.db.Query(
		ctx,
		`SELECT id, name 
			FROM categories`,
	)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var category models.Category
		if err = rows.Scan(&category.CategoryID, &category.CategoryName); err != nil {
			return nil, err
		}

		categories = append(categories, category)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return categories, nil
}

func (r *CategoryPostgres) GetCategoryByID(ctx context.Context, categoryID uuid.UUID) (*models.Category, error) {
	var category models.Category

	err := r.db.QueryRow(
		ctx,
		`SELECT id, name
			FROM categories
			WHERE id = $1`,
		categoryID,
	).Scan(&category.CategoryID, &category.CategoryName)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, pgx.ErrNoRows
		}
		return nil, err
	}
	return &category, nil
}

func (r *CategoryPostgres) CreateCategory(ctx context.Context, category *models.Category) error {
	_, err := r.db.Exec(
		ctx,
		`INSERT INTO categories (id, name) VALUES ($1, $2)`,
		category.CategoryID, category.CategoryName,
	)

	return err
}

func (r *CategoryPostgres) UpdateCategory(ctx context.Context, category *models.Category) error {
	_, err := r.db.Exec(
		ctx,
		`UPDATE categories SET name=$1 WHERE id=$2`,
		category.CategoryName, category.CategoryID,
	)

	return err
}

func (r *CategoryPostgres) DeleteCategory(ctx context.Context, categoryID uuid.UUID) error {
	_, err := r.db.Exec(
		ctx,
		`DELETE FROM categories WHERE id=$1`,
		categoryID,
	)

	return err
}
