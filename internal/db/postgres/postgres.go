package postgres

import (
	"context"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/url"
	"os"
	"strings"
)

type DBConfig struct {
	UserName string `env:"POSTGRES_USER" env-default:"postgres"`
	Password string `env:"POSTGRES_PASSWORD" env-default:"postgres"`
	Host     string `env:"POSTGRES_HOST" env-default:"localhost"`
	Port     string `env:"POSTGRES_PORT" env-default:"5432"`
	DbName   string `env:"POSTGRES_DB" env-default:"evently"`
}

type DB struct {
	Db *pgxpool.Pool
}

func NewPostgresDB(cfg DBConfig, migrationFile string) (*DB, error) {
	escapedPassword := url.QueryEscape(cfg.Password)

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?pool_max_conns=20",
		cfg.UserName, escapedPassword, cfg.Host, cfg.Port, cfg.DbName)

	dbPool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		if strings.Contains(err.Error(), "does not exist") {
			return createDatabaseAndMigrate(cfg, migrationFile)
		}
		return nil, fmt.Errorf("%v Unable to create connection pool: %v\n", os.Stderr, err)
	}

	err = dbPool.Ping(context.Background())
	if err != nil {
		return nil, fmt.Errorf("%v Unable to ping database: %v\n", os.Stderr, err)
	}

	return &DB{Db: dbPool}, nil
}

func createDatabaseAndMigrate(cfg DBConfig, migrationFile string) (*DB, error) {
	escapedPassword := url.QueryEscape(cfg.Password)

	adminDSN := fmt.Sprintf("postgres://%s:%s@%s:%s/postgres?pool_max_conns=20",
		cfg.UserName, escapedPassword, cfg.Host, cfg.Port)

	adminPool, err := pgxpool.New(context.Background(), adminDSN)
	if err != nil {
		return nil, fmt.Errorf("%v Unable to create admin connection pool: %v\n", os.Stderr, err)
	}
	defer adminPool.Close()

	_, err = adminPool.Exec(context.Background(), fmt.Sprintf("CREATE DATABASE %s", cfg.DbName))
	if err != nil {
		return nil, fmt.Errorf("%v Unable to create database: %v\n", os.Stderr, err)
	}

	// Now connect to the new database
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?pool_max_conns=20",
		cfg.UserName, escapedPassword, cfg.Host, cfg.Port, cfg.DbName)

	dbPool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		return nil, fmt.Errorf("%v Unable to create connection pool after database creation: %v\n", os.Stderr, err)
	}

	// Run migration if migration file is provided
	if migrationFile != "" {
		err = runMigration(dbPool, migrationFile)
		if err != nil {
			return nil, fmt.Errorf("%v Migration failed: %v\n", os.Stderr, err)
		}
	}

	// Verify connection
	err = dbPool.Ping(context.Background())
	if err != nil {
		return nil, fmt.Errorf("%v Unable to ping database after migration: %v\n", os.Stderr, err)
	}

	return &DB{Db: dbPool}, nil
}

func runMigration(pool *pgxpool.Pool, migrationFile string) error {
	// Read migration file
	migrationSQL, err := os.ReadFile(migrationFile)
	if err != nil {
		return fmt.Errorf("failed to read migration file: %v", err)
	}

	// Begin transaction
	tx, err := pool.Begin(context.Background())
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %v", err)
	}
	defer tx.Rollback(context.Background())

	// Execute migration
	_, err = tx.Exec(context.Background(), string(migrationSQL))
	if err != nil {
		return fmt.Errorf("failed to execute migration: %v", err)
	}

	// Commit transaction
	err = tx.Commit(context.Background())
	if err != nil {
		return fmt.Errorf("failed to commit migration transaction: %v", err)
	}

	return nil
}
