package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"net/http"
)

func GetUserIDFromContext(c *gin.Context) (uuid.UUID, int, string) {
	raw, exists := c.Get("userID")
	if !exists {
		return uuid.Nil, http.StatusUnauthorized, "unauthorized"
	}

	userID, ok := raw.(uuid.UUID)
	if !ok {
		return uuid.Nil, http.StatusInternalServerError, "invalid userID type"
	}

	return userID, http.StatusOK, ""
}

func (h *Handler) GetUserByID(c *gin.Context) {
	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	user, err := h.services.User.GetUserByID(c, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, user)
}

func (h *Handler) UpdateUser(c *gin.Context) {
	var user models.User

	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	if err := c.BindJSON(&user); err != nil {
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

func (h *Handler) DeleteUser(c *gin.Context) {
	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	err := h.services.User.DeleteUser(c, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *Handler) GetCreatedEventsForUser(c *gin.Context) {
	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	events, err := h.services.User.GetCreatedEventsForUser(c, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, events)
}

func (h *Handler) GetAttendedEventsForUser(c *gin.Context) {
	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	events, err := h.services.User.GetAttendedEventsForUser(c, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, events)
}
