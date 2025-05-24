package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"net/http"
	"strconv"
)

func (h *Handler) CreateEvent(c *gin.Context) {
	var event models.Event
	if err := c.ShouldBindJSON(&event); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	createdEvent, err := h.services.Event.CreateEvent(c, &event)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, createdEvent)
}

func (h *Handler) GetEventByID(c *gin.Context) {
	eventID, err := uuid.Parse(c.Param("eventID"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	event, err := h.services.Event.GetEventByID(c, eventID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, event)
}

func (h *Handler) GetEventParticipants(c *gin.Context) {
	eventID, err := uuid.Parse(c.Param("eventID"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	participants, err := h.services.Event.GetEventParticipants(c, eventID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, participants)
}

func (h *Handler) DeleteEventByID(c *gin.Context) {
	eventID, err := uuid.Parse(c.Param("eventID"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	role, exists := c.Get("userRole")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	if err := h.services.Event.DeleteEventByID(c, eventID, userID, role == AdminRole); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *Handler) UpdateEvent(c *gin.Context) {
	var event models.Event

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

	role, exists := c.Get("userRole")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	if err := c.ShouldBindJSON(&event); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	event.EventID = eventID
	updatedEvent, err := h.services.Event.UpdateEvent(c, &event, userID, role == AdminRole)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedEvent)
}

func (h *Handler) GetAllEvents(c *gin.Context) {
	page := c.DefaultQuery("page", "1")
	pageSize := c.DefaultQuery("pageSize", "10")

	pageInt, err := strconv.Atoi(page)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid page parameter"})
		return
	}

	pageSizeInt, err := strconv.Atoi(pageSize)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pageSize parameter"})
		return
	}

	role, exists := c.Get("userRole")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	events, err := h.services.Event.GetAllEvents(c, pageInt, pageSizeInt, role == AdminRole)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, events)
}
