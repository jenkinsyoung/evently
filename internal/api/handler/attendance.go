package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"net/http"
)

func (h *Handler) AttendToEvent(ctx *gin.Context) {
	eventIDParam := ctx.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	rawUserID, exists := ctx.Get("userID")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	userID, ok := rawUserID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "invalid userID type"})
		return
	}

	if err = h.services.Event.AttendToEvent(ctx, userID, eventID); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusOK)
}

func (h *Handler) CancelAttendance(ctx *gin.Context) {
	eventIDParam := ctx.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	rawUserID, exists := ctx.Get("userID")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	userID, ok := rawUserID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "invalid userID type"})
		return
	}

	if err = h.services.Event.CancelAttendance(ctx, userID, eventID); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusOK)
}
