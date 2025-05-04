package config

import (
	"fmt"
	"github.com/ilyakaznacheev/cleanenv"
	"github.com/jenkinsyoung/evently/internal/db/postgres"
)

type Config struct {
	postgres.DBConfig

	RestServerPort string `env:"REST_SERVER_PORT" envDefault:"8080"`
	Environment    string `env:"ENVIRONMENT"`
}

func LoadConfig() (*Config, error) {
	cfg := &Config{}
	err := cleanenv.ReadConfig("./configs/local.env", cfg)
	fmt.Println(err)
	if err != nil {
		return nil, fmt.Errorf("failed to load config: %w", err)
	}

	return cfg, nil
}
