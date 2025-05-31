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

func (r *CategoryPostgres) CreateCategory(ctx context.Context, category *models.Category) (*models.Category, error) {
	query := `INSERT INTO categories (name)
			  VALUES ($1)
			  RETURNING id, name`

	row := r.db.QueryRow(ctx, query, category.CategoryName)

	var created models.Category
	if err := row.Scan(&created.CategoryID, &created.CategoryName); err != nil {
		return nil, err
	}

	return &created, nil
}

func (r *CategoryPostgres) UpdateCategory(ctx context.Context, category *models.Category) (*models.Category, error) {
	query := `UPDATE categories
			  SET name = $1
			  WHERE id = $2
			  RETURNING id, name`

	row := r.db.QueryRow(ctx, query, category.CategoryName, category.CategoryID)

	var updated models.Category
	if err := row.Scan(&updated.CategoryID, &updated.CategoryName); err != nil {
		return nil, err
	}

	return &updated, nil
}

func (r *CategoryPostgres) DeleteCategory(ctx context.Context, categoryID uuid.UUID) error {
	_, err := r.db.Exec(
		ctx,
		`DELETE FROM categories WHERE id=$1`,
		categoryID,
	)

	return err
}
