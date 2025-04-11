package postgres

import (
	"context"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
)

type DBConfig struct {
	UserName string `env:"POSTGRES_USER" env-default:"postgres"`
	Password string `env:"POSTGRES_PASSWORD" env-default:"123"`
	Host     string `env:"POSTGRES_HOST" env-default:"localhost"`
	Port     string `env:"POSTGRES_PORT" env-default:"5432"`
	DbName   string `env:"POSTGRES_DB" env-default:"evently"`
}

type DB struct {
	Db *pgxpool.Pool
}

func NewPostgresDB(cfg DBConfig) (*DB, error) {

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?pool_max_conns=20",
		cfg.UserName, cfg.Password, cfg.Host, cfg.Port, cfg.DbName)

	dbpPool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		return nil, fmt.Errorf("%v Unable to create connection pool: %v\n", os.Stderr, err)
	}

	err = dbpPool.Ping(context.Background())
	if err != nil {
		return nil, fmt.Errorf("%v Unable to ping database: %v\n", os.Stderr, err)
	}

	return &DB{Db: dbpPool}, nil
}
