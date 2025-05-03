package handler

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"strings"
)

func (h *Handler) Authentication() gin.HandlerFunc {
	return func(c *gin.Context) {
		parts := c.Request.Header["Authorization"]
		if len(parts) == 0 {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is missing"})
			return
		}
		headerParts := strings.Split(parts[0], " ")
		if len(headerParts) != 2 || headerParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		if len(headerParts[1]) == 0 {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		payload, err := h.services.TokenManager.ParseJWTToken(headerParts[1])
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}
		c.Set("userId", payload.UserId)
		c.Set("userRole", payload.Role)

		c.Next()
	}
}
