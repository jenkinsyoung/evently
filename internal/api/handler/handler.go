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

	event := router.Group("/event")
	{
		event.POST("/", h.CreateEventHandler)
		event.GET("/:id", h.GetEventById)
		event.GET("/:id/participants", h.GetEventParticipants)
		event.DELETE("/:id", h.DeleteEventById)
		event.PUT("/:id", h.UpdateEvent)
		event.GET("/all", h.GetAllEvents)
	}

	user := router.Group("/user")
	{
		user.GET("/:id/events", h.GetEventsForUser)
		user.GET("/:id", h.GetUserByID)

		user.POST("", h.CreateUser)

		user.PUT("/:id", h.UpdateUser)

		user.DELETE("/:id", h.DeleteUser)
	}

	return router
}
