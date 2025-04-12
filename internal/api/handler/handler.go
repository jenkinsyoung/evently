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

	reviews := router.Group("/reviews")
	{
		reviews.GET("/:id", h.GetReviewsForEvent)
		reviews.POST("/:id", h.CreateReviewForEvent)
	}

	//event := router.Group("/event")
	//{
	//
	//}

	user := router.Group("/user")
	{
		user.GET("/:id/events", h.GetEventsForUser)
		user.GET("/:id", h.GetUserById)

		user.PUT("/:id", h.UpdateUser)
	}

	return router
}
