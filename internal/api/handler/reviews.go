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
	var reviewReq models.ReviewRequest

	eventIDParam := c.Param("eventID")

	eventID, err := uuid.Parse(eventIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid UUID format for event ID"})
		return
	}

	if err = c.BindJSON(&reviewReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	}

	userID, code, msg := GetUserIDFromContext(c)
	if code != http.StatusOK {
		c.JSON(code, gin.H{"error": msg})
		return
	}

	createdReview, err := h.services.Reviews.CreateReviewForEvent(c, &models.Review{
		Event: models.Event{
			EventID: eventID,
		},
		User: models.User{
			UserID: userID,
		},
		Description: reviewReq.Description,
		Score:       reviewReq.Score,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	}

	c.JSON(http.StatusCreated, createdReview)
}
