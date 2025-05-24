package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/jenkinsyoung/evently/internal/service"
	"net/http"
	"strings"
)

func (h *Handler) Authentication() gin.HandlerFunc {
	return func(c *gin.Context) {
		parts := c.Request.Header["Authorization"]
		if len(parts) == 0 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is missing"})
			return
		}
		headerParts := strings.Split(parts[0], " ")
		if len(headerParts) != 2 || headerParts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		if len(headerParts[1]) == 0 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		payload, err := h.services.TokenManager.ParseToken(headerParts[1], service.TokenTypeAccess)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err})
			return
		}
		c.Set("userID", payload.UserID)
		c.Set("userRole", payload.Role)

		c.Next()
	}
}

func (h *Handler) Authorization(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exist := c.Get("userRole")
		if !exist {
			c.AbortWithStatus(http.StatusForbidden)
			return
		}

		for _, allowed := range allowedRoles {
			if role == allowed {
				c.Next()
				return
			}
		}
		c.AbortWithStatus(http.StatusForbidden)
		return
	}
}
