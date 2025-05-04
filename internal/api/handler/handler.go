package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/jenkinsyoung/evently/internal/logger"
	"github.com/jenkinsyoung/evently/internal/service"
)

type Handler struct {
	services *service.Service
	log      *logger.Logger
}

func NewHandler(services *service.Service, log *logger.Logger) *Handler {
	return &Handler{services: services, log: log}
}

func (h *Handler) InitRoutes() *gin.Engine {
	router := gin.New()

	router.Use(gin.Logger())

	reviews := router.Group("/reviews")
	{
		reviews.GET("/:id", h.GetReviewsForEvent)
		reviews.POST("/:id", h.CreateReviewForEvent)
	}

	event := router.Group("/events")
	{
		event.POST("", h.CreateEventHandler)
		event.GET("/:id", h.GetEventById)
		event.GET("/:id/participants", h.GetEventParticipants)
		event.DELETE("/:id", h.DeleteEventById)
		event.PUT("/:id", h.UpdateEvent)
		event.GET("", h.GetAllEvents)
	}

	user := router.Group("/users")
	{
		user.GET("/:id/events", h.GetEventsForUser)
		user.GET("/:id", h.GetUserByID)

		user.POST("", h.CreateUser)

		user.PUT("/:id", h.UpdateUser)

		user.DELETE("/:id", h.DeleteUser)
	}

	category := router.Group("/categories")
	{
		category.GET("", h.GetCategories)
		category.GET("/:id", h.GetCategoryByID)

		category.POST("", h.CreateCategory)

		category.PUT("/:id", h.UpdateCategory)

		category.DELETE("/:id", h.DeleteCategory)
	}

	return router
}
