package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"net/http"
)

func (h *Handler) AttendToEvent(c *gin.Context) {
	eventIDParam := c.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	if err = h.services.Event.AttendToEvent(c, eventID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (h *Handler) CancelAttendance(c *gin.Context) {
	eventIDParam := c.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	if err = h.services.Event.CancelAttendance(c, eventID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}
