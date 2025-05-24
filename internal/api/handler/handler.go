package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/jenkinsyoung/evently/internal/logger"
	"github.com/jenkinsyoung/evently/internal/service"
)

const (
	AdminRole = "ADMIN"
	UserRole  = "USER"
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

	auth := router.Group("/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
		auth.POST("/refresh", h.RefreshTokens)

	}

	api := router.Group("/api")
	{
		// ВСЕ /api/** требуют наличия валидного access-токена
		api.Use(h.Authentication())

		// ---------- EVENTS ----------
		event := api.Group("/events")
		{
			event.POST("", h.CreateEvent)
			event.PUT("/:eventID", h.UpdateEvent)
			event.DELETE("/:eventID", h.DeleteEventByID)

			event.GET("/:eventID", h.GetEventByID)
			event.GET("/:eventID/participants", h.GetEventParticipants)
			event.GET("", h.GetAllEvents)

			// участие в мероприятии
			attendance := event.Group("/:eventID/attendance")
			{
				attendance.POST("", h.AttendToEvent)
				attendance.DELETE("", h.CancelAttendance)
			}

			// ---------- REVIEWS ----------
			reviews := event.Group("/:eventID/reviews")
			{
				reviews.GET("", h.GetReviewsForEvent)
				reviews.POST("", h.CreateReviewForEvent)
			}
		}

		// ---------- USERS ----------
		user := api.Group("/users")
		{
			// профиль и события своего пользователя

			user.GET("/me/created-events", h.GetCreatedEventsForUser)
			user.GET("/me/attended-events", h.GetAttendedEventsForUser)
			user.GET("/me", h.GetUserByID)
			user.PUT("/me", h.UpdateUser)
			user.DELETE("/me", h.DeleteUser)

		}

		// ---------- CATEGORIES (доступно всем авторизованным) ----------
		category := api.Group("/categories")
		{
			category.GET("", h.GetCategories)
			category.GET("/:categoryID", h.GetCategoryByID)
		}

		// ---------- MODERATION (только для админов) ----------
		moderation := api.Group("/moderation")
		{
			moderation.Use(h.Authorization(AdminRole))

			// модерация объявлений
			moderation.PATCH("/events/:eventID", h.CheckEvent)

			// управление пользователями
			userModeration := moderation.Group("/users")
			{
				userModeration.POST("", h.ModerationCreateUser)
				userModeration.PUT("/:userID", h.ModerationUpdateUser)
				userModeration.GET("/:userID", h.ModerationGetUserByID)
				userModeration.DELETE("/:userID", h.ModerationDeleteUser)
			}

			// управление категориями
			categoryModeration := moderation.Group("/categories")
			{
				categoryModeration.POST("", h.CreateCategory)
				categoryModeration.PUT("/:categoryID", h.UpdateCategory)
				categoryModeration.DELETE("/:categoryID", h.DeleteCategory)
			}
		}
	}

	return router
}
