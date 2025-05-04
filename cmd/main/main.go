package main

import (
	"context"
	"errors"
	"github.com/jenkinsyoung/evently/internal/api/handler"
	"github.com/jenkinsyoung/evently/internal/config"
	db "github.com/jenkinsyoung/evently/internal/db/postgres"
	"github.com/jenkinsyoung/evently/internal/logger"
	"github.com/jenkinsyoung/evently/internal/repository"
	"github.com/jenkinsyoung/evently/internal/service"
	"go.uber.org/zap"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	cfg, err := config.LoadConfig()
	if err != nil {
		panic("failed to load config: " + err.Error())
	}

	log, err := logger.NewZapLogger(cfg.Environment)
	if err != nil {
		panic("failed to create logger: " + err.Error())
	}

	database, err := db.NewPostgresDB(cfg.DBConfig)
	if err != nil {
		panic("failed to create database connection: " + err.Error())
	}

	repos := repository.NewRepository(database.Db)
	services := service.NewService(repos)
	handlers := handler.NewHandler(services, &log)

	srv := &http.Server{
		Addr:    ":" + cfg.RestServerPort,
		Handler: handlers.InitRoutes(),
	}

	graceCh := make(chan os.Signal, 1)
	signal.Notify(graceCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Info("starting the server", zap.String("port", cfg.RestServerPort))
		if err = srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			defer database.Db.Close()
			log.Error("shutting down the server", zap.Error(err))
			syscall.Exit(1)
		}
	}()

	<-graceCh

	// Graceful shutdown сервера
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err = srv.Shutdown(ctx); err != nil {
		log.Error("server forced to shutdown", zap.Error(err))
	}

	log.Info("server exiting")
}
