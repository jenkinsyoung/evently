package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jenkinsyoung/evently/internal/models"
	"net/http"
)

func (h *Handler) GetReviewsForEvent(c *gin.Context) {
	eventIDParam := c.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	reviews, err := h.services.Reviews.GetReviewsForEvent(c, eventID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, reviews)
}

func (h *Handler) CreateReviewForEvent(c *gin.Context) {
	var review models.Review

	eventIDParam := c.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	if err = c.BindJSON(&review); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	}

	review.Event.EventID = eventID
	review.ReviewID = uuid.New()

	createdReview, err := h.services.Reviews.CreateReviewForEvent(c, &review)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	}

	c.JSON(http.StatusCreated, createdReview)
}
