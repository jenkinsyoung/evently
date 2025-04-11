package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/jenkinsyoung/evently/internal/service"
)

type Handler struct {
	services *service.Service
}

func NewHandler(services *service.Service) *Handler {
	return &Handler{services: services}
}

func (h *Handler) InitRoutes() *gin.Engine {
	router := gin.New()

	router.Use(gin.Logger())

	return router
}
