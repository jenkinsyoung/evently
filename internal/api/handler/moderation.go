package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"net/http"
)

type CheckEventRequest struct {
	Status string `json:"status"`
}

func (h *Handler) CheckEvent(c *gin.Context) {
	eventIDParam := c.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	var request CheckEventRequest

	if err = c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	event, err := h.services.Moderation.CheckEvent(c, eventID, request.Status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err})
		return
	}

	c.JSON(http.StatusOK, event)
}

func (h *Handler) ModerationGetUserByID(c *gin.Context) {
	userIDParam := c.Param("userID")

	userID, err := uuid.Parse(userIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for user ID"})
		return
	}

	user, err := h.services.User.GetUserByID(c, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, user)
}

func (h *Handler) ModerationCreateUser(c *gin.Context) {
	var user models.User

	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	}

	createdUser, err := h.services.User.CreateUser(c, &user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, createdUser)
}

func (h *Handler) ModerationUpdateUser(c *gin.Context) {
	var user models.User

	userIDParam := c.Param("userID")

	userID, err := uuid.Parse(userIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for user ID"})
		return
	}

	if err = c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	}

	user.UserID = userID

	updatedUser, err := h.services.User.UpdateUser(c, &user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedUser)
}

func (h *Handler) ModerationDeleteUser(c *gin.Context) {
	userIDParam := c.Param("userID")

	userID, err := uuid.Parse(userIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for user ID"})
		return
	}

	err = h.services.User.DeleteUser(c, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
