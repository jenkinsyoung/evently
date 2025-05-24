package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/jenkinsyoung/evently/internal/models"
	"net/http"
)

type Tokens struct {
	AccessToken  string `json:"access_token,omitempty"`
	RefreshToken string `json:"refresh_token,omitempty"`
}

func (h *Handler) Register(c *gin.Context) {
	var user models.User
	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	accessToken, refreshToken, err := h.services.Authorization.Register(c, &user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, Tokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

func (h *Handler) Login(c *gin.Context) {
	var user models.User
	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	accessToken, refreshToken, err := h.services.Authorization.Login(c, &user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, Tokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

func (h *Handler) RefreshTokens(c *gin.Context) {
	var oldToken Tokens

	if err := c.BindJSON(&oldToken); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	accessToken, refreshToken, err := h.services.Authorization.RefreshTokens(c, oldToken.RefreshToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, Tokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}
