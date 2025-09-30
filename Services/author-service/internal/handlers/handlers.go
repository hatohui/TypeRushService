package handlers

import (
	"gin/internal/services"
)

// Handlers holds all handler instances
type Handlers struct {
	Role       *RoleHandler
	Permission *PermissionHandler
	UserBan    *UserBanHandler
}

// NewHandlers creates and returns all handler instances
func NewHandlers(services *services.Services) *Handlers {
	return &Handlers{
		Role:       NewRoleHandler(services.Role),
		Permission: NewPermissionHandler(services.Permission),
		UserBan:    NewUserBanHandler(services.UserBan),
	}
}